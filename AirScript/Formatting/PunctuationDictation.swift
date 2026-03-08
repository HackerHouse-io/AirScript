import Foundation

enum PunctuationDictation {
    static let mappings: [(spoken: String, written: String)] = [
        // Basic punctuation
        ("period", "."), ("full stop", "."),
        ("comma", ","),
        ("exclamation point", "!"), ("exclamation mark", "!"),
        ("question mark", "?"),
        ("colon", ":"), ("semicolon", ";"),
        ("dash", " — "), ("hyphen", "-"),
        ("ellipsis", "..."), ("dot dot dot", "..."),

        // Quotes
        ("open quote", "\""), ("close quote", "\""),
        ("open single quote", "'"), ("close single quote", "'"),
        ("quote", "\""), ("end quote", "\""),
        ("single quote", "'"),

        // Brackets
        ("open parenthesis", "("), ("close parenthesis", ")"),
        ("open paren", "("), ("close paren", ")"),
        ("open bracket", "["), ("close bracket", "]"),
        ("open brace", "{"), ("close brace", "}"),

        // Symbols
        ("at sign", "@"), ("at symbol", "@"),
        ("hashtag", "#"), ("hash", "#"), ("pound sign", "#"),
        ("dollar sign", "$"), ("dollar", "$"),
        ("percent", "%"), ("percent sign", "%"),
        ("ampersand", "&"), ("and sign", "&"),
        ("asterisk", "*"), ("star", "*"),
        ("forward slash", "/"), ("slash", "/"),
        ("backslash", "\\"),
        ("pipe", "|"), ("vertical bar", "|"),
        ("tilde", "~"),
        ("underscore", "_"),
        ("plus sign", "+"), ("plus", "+"),
        ("equals sign", "="), ("equals", "="),
        ("greater than", ">"), ("less than", "<"),
        ("caret", "^"),

        // Special
        ("apostrophe", "'"),
        ("copyright", "©"),
        ("trademark", "™"),
        ("degree", "°"),
    ]

    static func apply(to text: String) -> String {
        var result = text
        // Sort by spoken phrase length (longest first) to match multi-word phrases first
        let sorted = mappings.sorted { $0.spoken.count > $1.spoken.count }

        for mapping in sorted {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: mapping.spoken))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: mapping.written
                )
            }
        }

        // Clean up spacing around punctuation
        result = cleanPunctuationSpacing(result)
        return result
    }

    private static func cleanPunctuationSpacing(_ text: String) -> String {
        var result = text
        // Remove space before punctuation marks
        let noSpaceBefore = [".", ",", "!", "?", ":", ";", ")", "]", "}", "'"]
        for mark in noSpaceBefore {
            result = result.replacingOccurrences(of: " \(mark)", with: mark)
        }
        // Remove space after opening brackets
        let noSpaceAfter = ["(", "[", "{"]
        for mark in noSpaceAfter {
            result = result.replacingOccurrences(of: "\(mark) ", with: mark)
        }
        return result
    }
}
