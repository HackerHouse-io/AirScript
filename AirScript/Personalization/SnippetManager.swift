import AppKit
import CoreGraphics
import os

final class SnippetManager {
    private let logger = Logger.general

    func findMatch(for text: String, in snippets: [Snippet]) -> Snippet? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Exact match first
        if let exact = snippets.first(where: { $0.trigger.lowercased() == trimmed }) {
            return exact
        }

        // Fuzzy match (Levenshtein ≤ 2)
        return snippets.first { snippet in
            trimmed.fuzzyMatches(snippet.trigger, maxDistance: 2)
        }
    }

    func execute(snippet: Snippet) async {
        snippet.usageCount += 1
        snippet.lastUsed = Date()

        switch snippet.actionType {
        case .text:
            await TextInjector.inject(text: snippet.value)
        case .shell:
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", snippet.value]
            try? process.run()
        case .keystroke:
            // Parse "keyCode:flags" format
            let parts = snippet.value.split(separator: ":")
            if let keyCode = parts.first.flatMap({ UInt16($0) }) {
                let flags: CGEventFlags = parts.count > 1 ? parseFlags(String(parts[1])) : []
                TextInjector.sendKeystroke(keyCode: keyCode, flags: flags)
            }
        }
    }

    private func parseFlags(_ flagStr: String) -> CGEventFlags {
        var flags: CGEventFlags = []
        if flagStr.contains("cmd") { flags.insert(.maskCommand) }
        if flagStr.contains("shift") { flags.insert(.maskShift) }
        if flagStr.contains("opt") { flags.insert(.maskAlternate) }
        if flagStr.contains("ctrl") { flags.insert(.maskControl) }
        return flags
    }
}
