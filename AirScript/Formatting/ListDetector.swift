import Foundation

enum ListDetector {
    static func detect(in text: String) -> String {
        var result = text

        // Detect numbered patterns: "one X two Y three Z" or "first X second Y third Z"
        let numberPatterns: [(pattern: String, prefix: String)] = [
            ("\\bone\\b", "1. "), ("\\btwo\\b", "2. "), ("\\bthree\\b", "3. "),
            ("\\bfour\\b", "4. "), ("\\bfive\\b", "5. "), ("\\bsix\\b", "6. "),
            ("\\bseven\\b", "7. "), ("\\beight\\b", "8. "), ("\\bnine\\b", "9. "),
            ("\\bten\\b", "10. "),
        ]

        let ordinalPatterns: [(pattern: String, prefix: String)] = [
            ("\\bfirst\\b", "1. "), ("\\bsecond\\b", "2. "), ("\\bthird\\b", "3. "),
            ("\\bfourth\\b", "4. "), ("\\bfifth\\b", "5. "),
        ]

        // Check if text has list-like pattern (at least 2 sequential numbers/ordinals at sentence boundaries)
        if hasListPattern(text, patterns: numberPatterns) {
            result = formatAsList(text, patterns: numberPatterns)
        } else if hasListPattern(text, patterns: ordinalPatterns) {
            result = formatAsList(text, patterns: ordinalPatterns)
        }

        return result
    }

    private static func hasListPattern(_ text: String, patterns: [(pattern: String, prefix: String)]) -> Bool {
        var matchCount = 0
        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                matchCount += 1
            }
            if matchCount >= 2 { return true }
        }
        return false
    }

    private static func formatAsList(_ text: String, patterns: [(pattern: String, prefix: String)]) -> String {
        var result = text
        for (pattern, prefix) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: "\n\(prefix)"
                )
            }
        }
        // Trim leading newline
        result = result.trimmingCharacters(in: .newlines)
        return result
    }
}
