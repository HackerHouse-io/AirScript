import Foundation
import os

final class CommandRouter {
    private let executor = OSCommandExecutor()
    private let logger = Logger.commands

    func route(text: String, isCommandMode: Bool) async -> Bool {
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

        return false
    }
}
