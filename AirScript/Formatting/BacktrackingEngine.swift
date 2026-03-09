import Foundation
import os

final class BacktrackingEngine {
    private(set) var lastInjected: String?
    private let logger = Logger.formatting

    func setLastInjected(_ text: String) {
        lastInjected = text
    }

    func handleCorrection(newText: String) -> (textToReplace: String?, replacement: String)? {
        guard let lastText = lastInjected else { return nil }
        return (textToReplace: lastText, replacement: newText)
    }

    func clear() {
        lastInjected = nil
    }
}
