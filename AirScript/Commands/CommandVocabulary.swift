import Foundation

struct CommandMatch {
    let command: String
    let action: CommandAction
    let confidence: Double
}

struct CustomCommandMatch {
    let command: String
    let customCommand: CustomVoiceCommand
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
    case copy, paste, cut, selectAll
    case newTab, newWindow, closeTab
    case lockScreen
}

enum CommandVocabulary {
    static let commands: [(patterns: [String], action: (String) -> CommandAction)] = [
        // App switching
        (["switch to *", "go to *", "open up *", "open *"], { name in .switchToApp(name: name) }),
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

        // Clipboard
        (["copy", "copy that"], { _ in .copy }),
        (["paste"], { _ in .paste }),
        (["cut"], { _ in .cut }),
        (["select all"], { _ in .selectAll }),

        // Tabs/Windows
        (["new tab"], { _ in .newTab }),
        (["new window"], { _ in .newWindow }),
        (["close tab"], { _ in .closeTab }),

        // System extras
        (["lock screen"], { _ in .lockScreen }),
    ]

    static func match(_ text: String) -> CommandMatch? {
        let normalized = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        for (patterns, actionBuilder) in commands {
            for pattern in patterns {
                if pattern.hasSuffix("*") {
                    let prefix = String(pattern.dropLast()).trimmingCharacters(in: .whitespaces)
                    if normalized.hasPrefix(prefix) {
                        let argument = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                        let cleaned = stripArticles(argument)
                        return CommandMatch(
                            command: normalized,
                            action: actionBuilder(cleaned),
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
                            let cleaned = stripArticles(argument)
                            return CommandMatch(
                                command: normalized,
                                action: actionBuilder(cleaned),
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

    static func matchCustom(_ text: String, customCommands: [CustomVoiceCommand]) -> CustomCommandMatch? {
        let normalized = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        for command in customCommands {
            let trigger = command.trigger.lowercased()
            if normalized == trigger || normalized.fuzzyMatches(trigger, maxDistance: 2) {
                return CustomCommandMatch(
                    command: normalized,
                    customCommand: command,
                    confidence: normalized == trigger ? 1.0 : 0.7
                )
            }
        }
        return nil
    }

    private static func stripArticles(_ text: String) -> String {
        let articles = ["the ", "a ", "an "]
        var result = text
        for article in articles {
            if result.lowercased().hasPrefix(article) {
                result = String(result.dropFirst(article.count))
            }
        }
        if result.lowercased().hasSuffix(" app") {
            result = String(result.dropLast(4)).trimmingCharacters(in: .whitespaces)
        }
        return result
    }
}
