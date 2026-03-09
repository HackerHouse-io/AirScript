import Foundation
import Carbon.HIToolbox
import os

final class BacktrackingEngine {
    private(set) var lastInjected: String?
    private(set) var lastInjectedLength: Int = 0
    private let logger = Logger.formatting

    private static let correctThatTriggers: Set<String> = [
        "correct that", "fix that", "redo that", "change that"
    ]

    func setLastInjected(_ text: String) {
        lastInjected = text
        lastInjectedLength = text.count
    }

    func isCorrectThatTrigger(_ text: String) -> Bool {
        let normalized = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".!?,"))
        return Self.correctThatTriggers.contains(normalized)
    }

    /// Selects the previously injected text by sending Option+Shift+Left arrow events
    /// word-by-word. This is much faster than character-by-character for longer texts.
    func selectLastInjected() {
        guard let text = lastInjected, lastInjectedLength > 0 else { return }

        let src = CGEventSource(stateID: .combinedSessionState)
        let wordCount = text.split(whereSeparator: { $0.isWhitespace }).count
        // Option+Shift+Left selects one word at a time (handles punctuation attached to words)
        let selectPresses = Swift.max(wordCount, 1)

        for _ in 0..<selectPresses {
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_LeftArrow), keyDown: true)
            keyDown?.flags = [.maskShift, .maskAlternate]
            keyDown?.post(tap: .cgSessionEventTap)

            let keyUp = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_LeftArrow), keyDown: false)
            keyUp?.flags = [.maskShift, .maskAlternate]
            keyUp?.post(tap: .cgSessionEventTap)
        }

        logger.info("Selected last injected text (~\(wordCount) words via Option+Shift+Left)")
    }

    func handleCorrection(newText: String) -> (textToReplace: String?, replacement: String)? {
        guard let lastText = lastInjected else { return nil }
        return (textToReplace: lastText, replacement: newText)
    }

    func clear() {
        lastInjected = nil
        lastInjectedLength = 0
    }
}
