import Foundation
import os

final class BacktrackingEngine {
    private var lastInjectedText: String?
    private let logger = Logger.formatting

    func setLastInjected(_ text: String) {
        lastInjectedText = text
    }

    func handleCorrection(newText: String) -> (textToReplace: String?, replacement: String)? {
        // Patterns handled by LLM prompt: "actually X", "scratch that"
        // This handles explicit "correct that" voice command
        guard let lastText = lastInjectedText else { return nil }
        return (textToReplace: lastText, replacement: newText)
    }

    func clear() {
        lastInjectedText = nil
    }
}
