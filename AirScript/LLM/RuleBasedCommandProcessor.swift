import Foundation

enum CommandType {
    case makeConcise
    case fixGrammar
    case bulletPoints
    case makeProfessional
    case makeCasual
    case uppercase
    case lowercase
    case titleCase
    case boldTitle
    case rewriteAsEmail
    case expandText
    case summarize
    case translateTo
    case unknown
}

enum RuleBasedCommandProcessor {

    // MARK: - Classification

    static func classify(_ command: String) -> CommandType {
        let lower = command.lowercased()

        if lower.contains("concise") || lower.contains("shorter") || lower.contains("shorten") || lower.contains("brief") {
            return .makeConcise
        }
        if lower.contains("grammar") || lower.contains("fix spelling") {
            return .fixGrammar
        }
        if lower.contains("bullet") || lower.contains("list") {
            return .bulletPoints
        }
        if lower.contains("professional") || lower.contains("formal") {
            return .makeProfessional
        }
        if lower.contains("casual") || lower.contains("informal") {
            return .makeCasual
        }
        if lower.contains("uppercase") || lower.contains("all caps") {
            return .uppercase
        }
        if lower.contains("lowercase") {
            return .lowercase
        }
        if lower.contains("title case") {
            return .titleCase
        }
        if lower.contains("bold title") {
            return .boldTitle
        }
        if lower.contains("email") || lower.contains("as an email") {
            return .rewriteAsEmail
        }
        if lower.contains("expand") || lower.contains("elaborate") {
            return .expandText
        }
        if lower.contains("summarize") || lower.contains("summary") {
            return .summarize
        }
        if lower.contains("translate") {
            return .translateTo
        }

        return .unknown
    }

    // MARK: - Rule-Based Transforms

    static func apply(_ type: CommandType, to text: String) -> String? {
        switch type {
        case .makeConcise:
            return makeConcise(text)
        case .fixGrammar:
            return fixGrammar(text)
        case .bulletPoints:
            return bulletPoints(text)
        case .makeProfessional:
            return makeProfessional(text)
        case .makeCasual:
            return makeCasual(text)
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .titleCase:
            return titleCase(text)
        case .boldTitle:
            return boldTitle(text)
        case .rewriteAsEmail:
            return rewriteAsEmail(text)
        case .expandText, .summarize, .translateTo:
            return nil // Requires LLM
        case .unknown:
            return nil
        }
    }

    // MARK: - Transform Implementations

    private static func makeConcise(_ text: String) -> String {
        var result = text
        let wordyPhrases: [(String, String)] = [
            ("in order to", "to"),
            ("due to the fact that", "because"),
            ("in the event that", "if"),
            ("at this point in time", "now"),
            ("for the purpose of", "to"),
            ("in spite of the fact that", "although"),
            ("on the other hand", "however"),
            ("in the near future", "soon"),
            ("a large number of", "many"),
            ("the majority of", "most"),
            ("in addition to", "besides"),
            ("at the present time", "currently"),
            ("it is important to note that", "notably"),
            ("as a matter of fact", "in fact"),
            ("in light of the fact that", "since"),
            ("with regard to", "about"),
            ("in reference to", "about"),
            ("each and every", "every"),
            ("first and foremost", "first"),
            ("basic and fundamental", "basic"),
        ]

        for (wordy, concise) in wordyPhrases {
            result = result.replacingOccurrences(
                of: wordy, with: concise,
                options: .caseInsensitive
            )
        }

        // Remove filler adverbs (word-boundary anchored on both sides to avoid partial matches)
        let fillers = ["very", "really", "actually", "basically", "quite", "rather"]
        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: "\\b\(filler)\\b\\s*", options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Clean up double spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func fixGrammar(_ text: String) -> String {
        var result = text

        // Remove speech fillers (word-boundary anchored to prevent false matches)
        let fillers = ["\\bum\\b", "\\buh\\b", "\\byou know\\b", "\\bI mean\\b"]
        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: filler, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Fix spacing
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize first letter
        if let first = result.first, first.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }

        // Ensure terminal punctuation
        if !result.isEmpty && !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }

        return result
    }

    private static func bulletPoints(_ text: String) -> String {
        // Split on sentence boundaries
        let pattern = "(?<=[.!?])\\s+"
        let sentences: [String]
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            var parts: [String] = []
            var lastEnd = text.startIndex
            regex.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match else { return }
                let matchRange = Range(match.range, in: text)!
                let sentence = String(text[lastEnd..<matchRange.lowerBound])
                if !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                    parts.append(sentence.trimmingCharacters(in: .whitespaces))
                }
                lastEnd = matchRange.upperBound
            }
            let remaining = String(text[lastEnd...])
            if !remaining.trimmingCharacters(in: .whitespaces).isEmpty {
                parts.append(remaining.trimmingCharacters(in: .whitespaces))
            }
            sentences = parts
        } else {
            sentences = [text]
        }

        return sentences.map { "- \($0)" }.joined(separator: "\n")
    }

    private static func makeProfessional(_ text: String) -> String {
        var result = text

        // Expand contractions
        let contractions: [(String, String)] = [
            ("don't", "do not"),
            ("doesn't", "does not"),
            ("didn't", "did not"),
            ("can't", "cannot"),
            ("couldn't", "could not"),
            ("wouldn't", "would not"),
            ("shouldn't", "should not"),
            ("won't", "will not"),
            ("isn't", "is not"),
            ("aren't", "are not"),
            ("wasn't", "was not"),
            ("weren't", "were not"),
            ("hasn't", "has not"),
            ("haven't", "have not"),
            ("hadn't", "had not"),
            ("I'm", "I am"),
            ("I've", "I have"),
            ("I'll", "I will"),
            ("I'd", "I would"),
            ("we're", "we are"),
            ("we've", "we have"),
            ("we'll", "we will"),
            ("they're", "they are"),
            ("they've", "they have"),
            ("they'll", "they will"),
            ("you're", "you are"),
            ("you've", "you have"),
            ("you'll", "you will"),
            ("it's", "it is"),
            ("that's", "that is"),
            ("there's", "there is"),
            ("let's", "let us"),
        ]

        for (contraction, expanded) in contractions {
            result = result.replacingOccurrences(of: contraction, with: expanded, options: .caseInsensitive)
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize first letter
        if let first = result.first, first.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }

        // Ensure terminal punctuation
        if !result.isEmpty && !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }

        return result
    }

    private static func makeCasual(_ text: String) -> String {
        var result = text

        // Contract formal phrases (preserves original casing)
        let formalToCasual: [(String, String)] = [
            ("do not", "don't"),
            ("does not", "doesn't"),
            ("did not", "didn't"),
            ("cannot", "can't"),
            ("could not", "couldn't"),
            ("would not", "wouldn't"),
            ("should not", "shouldn't"),
            ("will not", "won't"),
            ("is not", "isn't"),
            ("are not", "aren't"),
            ("was not", "wasn't"),
            ("were not", "weren't"),
            ("has not", "hasn't"),
            ("have not", "haven't"),
            ("had not", "hadn't"),
            ("I am", "I'm"),
            ("I have", "I've"),
            ("I will", "I'll"),
            ("I would", "I'd"),
            ("we are", "we're"),
            ("they are", "they're"),
            ("you are", "you're"),
            ("it is", "it's"),
            ("that is", "that's"),
            ("there is", "there's"),
            ("let us", "let's"),
        ]

        for (formal, casual) in formalToCasual {
            while let range = result.range(of: formal, options: .caseInsensitive) {
                let matched = String(result[range])
                var replacement = casual
                // Preserve ALL CAPS
                if matched.count > 1 && matched == matched.uppercased() && matched != matched.lowercased() {
                    replacement = casual.uppercased()
                } else if matched.first?.isUppercase == true {
                    replacement = casual.prefix(1).uppercased() + casual.dropFirst()
                }
                result = result.replacingCharacters(in: range, with: replacement)
            }
        }

        return result
    }

    private static func titleCase(_ text: String) -> String {
        let lowercaseWords: Set<String> = ["a", "an", "the", "and", "but", "or", "for", "nor",
                                            "on", "at", "to", "by", "in", "of", "up", "as"]
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        return words.enumerated().map { index, word in
            let lower = word.lowercased()
            if index == 0 || !lowercaseWords.contains(lower) {
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            return lower
        }.joined(separator: " ")
    }

    /// Wraps the first line in Markdown bold syntax (`**...**`).
    /// Note: Only renders correctly in apps that support Markdown. In plain-text
    /// contexts the literal `**` characters will be visible.
    private static func boldTitle(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        guard let firstLine = lines.first else { return text }
        var result = ["**\(firstLine)**"]
        result.append(contentsOf: lines.dropFirst())
        return result.joined(separator: "\n")
    }

    private static func rewriteAsEmail(_ text: String) -> String {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Hi,\n\n\(body)\n\nBest regards"
    }
}
