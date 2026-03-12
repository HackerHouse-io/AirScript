import AppKit
import SwiftData
import os

final class CommandRouter {
    private let executor = OSCommandExecutor()
    private let intentClassifier = IntentClassifier()
    private let logger = Logger.commands
    private var lastRegisteredAliases: [String: String] = [:]

    func route(text: String, isCommandMode: Bool, customCommands: [CustomVoiceCommand] = [], customAliases: [CustomAppAlias] = []) async -> Bool {
        // Register custom aliases with both executor and classifier (only if changed)
        if !customAliases.isEmpty {
            var aliasMap: [String: String] = [:]
            for alias in customAliases {
                aliasMap[alias.spokenName.lowercased()] = alias.appName
            }
            if aliasMap != lastRegisteredAliases {
                lastRegisteredAliases = aliasMap
                executor.registerCustomAliases(aliasMap)
                await intentClassifier.registerCustomAliases(aliasMap)
            }
        }

        // Use IntentClassifier for smart matching
        let (intent, confidence) = await intentClassifier.classify(text, isCommandMode: isCommandMode)

        switch intent {
        case .command(let action):
            logger.info("Intent classified as command (conf: \(confidence)): \(String(text.prefix(50)))")
            await executor.execute(action)
            return true
        case .dictation:
            break
        }

        // Check custom commands (these use exact trigger matching)
        if let customMatch = CommandVocabulary.matchCustom(text, customCommands: customCommands) {
            if isCommandMode || customMatch.confidence >= 0.8 {
                logger.info("Executing custom command: \(customMatch.command)")
                await executeCustomCommand(customMatch.customCommand)
                return true
            }
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
