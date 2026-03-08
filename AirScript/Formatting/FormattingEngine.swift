import Foundation
import os

final class FormattingEngine {
    private let logger = Logger.formatting

    func format(_ text: String) -> String {
        var result = text

        // 1. Punctuation dictation substitution
        result = PunctuationDictation.apply(to: result)

        // 2. Line/paragraph breaks
        result = applyLineBreaks(result)

        // 3. List detection
        result = ListDetector.detect(in: result)

        // 4. "press enter" detection
        result = handlePressEnter(result)

        return result
    }

    private func applyLineBreaks(_ text: String) -> String {
        var result = text

        let replacements: [(pattern: String, replacement: String)] = [
            ("\\bnew paragraph\\b", "\n\n"),
            ("\\bnew line\\b", "\n"),
            ("\\bline break\\b", "\n"),
            ("\\bnext line\\b", "\n"),
        ]

        for (pattern, replacement) in replacements {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: replacement
                )
            }
        }

        return result
    }

    private func handlePressEnter(_ text: String) -> String {
        // If text ends with "press enter" or "hit enter", strip it and flag for Enter keystroke
        let patterns = ["\\s*press enter\\s*$", "\\s*hit enter\\s*$", "\\s*press return\\s*$"]
        var result = text
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                if regex.firstMatch(in: result, range: range) != nil {
                    result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
                    // The "press enter" will be handled by TextInjector
                    result += "\n" // Append newline to simulate Enter
                }
            }
        }
        return result
    }
}
