import AppKit
import SwiftData
import os

final class CommandRouter {
    private let executor = OSCommandExecutor()
    private let logger = Logger.commands

    func route(text: String, isCommandMode: Bool, customCommands: [CustomVoiceCommand] = [], customAliases: [CustomAppAlias] = []) async -> Bool {
        // Register custom aliases with executor
        if !customAliases.isEmpty {
            var aliasMap: [String: String] = [:]
            for alias in customAliases {
                aliasMap[alias.spokenName.lowercased()] = alias.appName
            }
            executor.registerCustomAliases(aliasMap)
        }

        // In command mode: everything is a command
        // In dictation mode: only exact matches
        let match = CommandVocabulary.match(text)

        if let match {
            if isCommandMode || match.confidence >= 0.9 {
                logger.info("Executing command: \(match.command)")
                await executor.execute(match.action)
                return true
            }
        }

        // Check custom commands (after built-in)
        if let customMatch = CommandVocabulary.matchCustom(text, customCommands: customCommands) {
            if isCommandMode || customMatch.confidence >= 0.9 {
                logger.info("Executing custom command: \(customMatch.command)")
                await executeCustomCommand(customMatch.customCommand)
                return true
            }
        }

        if isCommandMode && match == nil {
            NSSound.beep()
            logger.info("No command matched: \(text)")
        }

        return false
    }

    private func executeCustomCommand(_ command: CustomVoiceCommand) async {
        switch command.actionType {
        case .keystroke:
            // Parse "keyCode:flags" format
            let parts = command.actionValue.components(separatedBy: ":")
            if let keyCode = UInt16(parts[0].trimmingCharacters(in: .whitespaces)) {
                var flags: CGEventFlags = []
                if parts.count > 1 {
                    let flagStr = parts[1].lowercased()
                    if flagStr.contains("cmd") { flags.insert(.maskCommand) }
                    if flagStr.contains("shift") { flags.insert(.maskShift) }
                    if flagStr.contains("opt") || flagStr.contains("alt") { flags.insert(.maskAlternate) }
                    if flagStr.contains("ctrl") { flags.insert(.maskControl) }
                }
                TextInjector.sendKeystroke(keyCode: keyCode, flags: flags)
            }
        case .openApp:
            await executor.execute(.openApp(name: command.actionValue))
        case .openURL:
            if let url = URL(string: command.actionValue) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
