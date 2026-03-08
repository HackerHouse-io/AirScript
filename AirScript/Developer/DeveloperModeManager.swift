import Foundation
import os

final class DeveloperModeManager {
    private let logger = Logger.general

    func recognizeVariables(in text: String, visibleCode: String) -> String {
        let identifiers = IdentifierExtractor.extract(from: visibleCode)
        guard !identifiers.isEmpty else { return text }

        var result = text
        let words = text.components(separatedBy: " ")

        for word in words {
            let cleaned = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            // Find best matching identifier
            for identifier in identifiers {
                if cleaned.fuzzyMatches(identifier.lowercased(), maxDistance: 2) &&
                   cleaned.count >= 3 {
                    // Replace with backtick-wrapped identifier
                    result = result.replacingOccurrences(of: word, with: "`\(identifier)`")
                    break
                }
            }
        }

        // Handle "@filename" pattern
        result = handleFileTagging(result, in: visibleCode)

        return result
    }

    private func handleFileTagging(_ text: String, in code: String) -> String {
        // Detect "at filename" pattern and convert to @filename
        var result = text
        let atPattern = "\\bat\\s+([a-zA-Z][a-zA-Z0-9._-]+\\.[a-zA-Z]+)"
        if let regex = try? NSRegularExpression(pattern: atPattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "@$1"
            )
        }
        return result
    }
}
