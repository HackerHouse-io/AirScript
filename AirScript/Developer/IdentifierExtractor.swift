import Foundation

enum IdentifierExtractor {
    // Common English words to filter out
    private static let commonWords: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her",
        "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its",
        "let", "may", "new", "now", "old", "see", "way", "who", "did", "got", "say",
        "she", "too", "use", "with", "this", "that", "from", "they", "been", "have",
        "many", "some", "them", "than", "each", "make", "like", "long", "look",
        "will", "into", "time", "very", "when", "come", "just", "know", "take",
        "class", "func", "return", "import", "struct", "enum", "case", "break",
        "continue", "while", "true", "false", "null", "void", "public", "private",
    ]

    static func extract(from code: String) -> [String] {
        // Match camelCase, PascalCase, snake_case, SCREAMING_SNAKE
        let patterns = [
            "[a-z][a-zA-Z0-9]*[A-Z][a-zA-Z0-9]*",  // camelCase
            "[A-Z][a-zA-Z0-9]+",                       // PascalCase
            "[a-z]+(?:_[a-z]+)+",                       // snake_case
            "[A-Z]+(?:_[A-Z]+)+",                       // SCREAMING_SNAKE
        ]

        var identifiers: Set<String> = []

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(code.startIndex..., in: code)
                let matches = regex.matches(in: code, range: range)
                for match in matches {
                    if let range = Range(match.range, in: code) {
                        let word = String(code[range])
                        if !commonWords.contains(word.lowercased()) && word.count > 2 {
                            identifiers.insert(word)
                        }
                    }
                }
            }
        }

        return Array(identifiers)
    }
}
