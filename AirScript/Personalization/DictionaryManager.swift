import Foundation
import SwiftData
import os

final class DictionaryManager {
    private let logger = Logger.general

    func applyReplacements(to text: String, using entries: [DictionaryEntry]) -> String {
        var result = text
        // Sort by spoken length (longest first) to handle multi-word replacements
        let sorted = entries.sorted { $0.spoken.count > $1.spoken.count }

        for entry in sorted {
            let options: NSRegularExpression.Options = entry.caseSensitive ? [] : .caseInsensitive
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: entry.spoken))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: options) {
                let range = NSRange(result.startIndex..., in: result)
                let newResult = regex.stringByReplacingMatches(
                    in: result,
                    range: range,
                    withTemplate: entry.written
                )
                if newResult != result {
                    result = newResult
                    entry.usageCount += 1
                }
            }
        }
        return result
    }

    func exportJSON(entries: [DictionaryEntry]) throws -> Data {
        let exportable = entries.map { entry in
            [
                "spoken": entry.spoken,
                "written": entry.written,
                "caseSensitive": entry.caseSensitive ? "true" : "false",
                "category": entry.category,
            ]
        }
        return try JSONSerialization.data(withJSONObject: exportable, options: .prettyPrinted)
    }

    func importJSON(data: Data) throws -> [(spoken: String, written: String, caseSensitive: Bool, category: String)] {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            throw NSError(domain: "DictionaryManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        return array.compactMap { dict in
            guard let spoken = dict["spoken"], let written = dict["written"] else { return nil }
            return (
                spoken: spoken,
                written: written,
                caseSensitive: dict["caseSensitive"] == "true",
                category: dict["category"] ?? ""
            )
        }
    }
}
