import Foundation

struct CommandMatch {
    let command: String
    let action: CommandAction
    let confidence: Double
}

enum CommandAction {
    case switchToApp(name: String)
    case openApp(name: String)
    case nextDesktop
    case previousDesktop
    case volumeUp
    case volumeDown
    case mute
    case playPause
    case nextTrack
    case previousTrack
    case closeWindow
    case minimizeWindow
    case fullScreen
    case screenshot
    case search(query: String)
    case undo
    case redo
}

enum CommandVocabulary {
    static let commands: [(patterns: [String], action: (String) -> CommandAction)] = [
        // App switching
        (["switch to *", "go to *", "open *"], { name in .switchToApp(name: name) }),
        (["launch *", "start *"], { name in .openApp(name: name) }),

        // Desktop navigation
        (["next desktop", "next space", "right desktop"], { _ in .nextDesktop }),
        (["previous desktop", "previous space", "left desktop"], { _ in .previousDesktop }),

        // Volume
        (["volume up", "louder"], { _ in .volumeUp }),
        (["volume down", "quieter", "softer"], { _ in .volumeDown }),
        (["mute", "unmute"], { _ in .mute }),

        // Media
        (["play", "pause", "play pause"], { _ in .playPause }),
        (["next track", "next song", "skip"], { _ in .nextTrack }),
        (["previous track", "previous song"], { _ in .previousTrack }),

        // Window
        (["close window", "close this"], { _ in .closeWindow }),
        (["minimize", "minimize window"], { _ in .minimizeWindow }),
        (["full screen", "fullscreen", "enter full screen"], { _ in .fullScreen }),

        // System
        (["take screenshot", "screenshot"], { _ in .screenshot }),
        (["search for *", "google *", "look up *"], { query in .search(query: query) }),
        (["undo"], { _ in .undo }),
        (["redo"], { _ in .redo }),
    ]

    static func match(_ text: String) -> CommandMatch? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        for (patterns, actionBuilder) in commands {
            for pattern in patterns {
                if pattern.hasSuffix("*") {
                    let prefix = String(pattern.dropLast()).trimmingCharacters(in: .whitespaces)
                    if normalized.hasPrefix(prefix) {
                        let argument = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                        return CommandMatch(
                            command: normalized,
                            action: actionBuilder(argument),
                            confidence: 1.0
                        )
                    }
                    // Fuzzy prefix match
                    let words = normalized.components(separatedBy: " ")
                    let prefixWords = prefix.components(separatedBy: " ")
                    if words.count > prefixWords.count {
                        let spokenPrefix = words.prefix(prefixWords.count).joined(separator: " ")
                        if spokenPrefix.fuzzyMatches(prefix, maxDistance: 2) {
                            let argument = words.dropFirst(prefixWords.count).joined(separator: " ")
                            return CommandMatch(
                                command: normalized,
                                action: actionBuilder(argument),
                                confidence: 0.8
                            )
                        }
                    }
                } else {
                    if normalized == pattern {
                        return CommandMatch(
                            command: normalized,
                            action: actionBuilder(""),
                            confidence: 1.0
                        )
                    }
                    if normalized.fuzzyMatches(pattern, maxDistance: 2) {
                        return CommandMatch(
                            command: normalized,
                            action: actionBuilder(""),
                            confidence: 0.7
                        )
                    }
                }
            }
        }
        return nil
    }
}
