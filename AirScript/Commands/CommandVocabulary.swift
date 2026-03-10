import Foundation

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
    // MARK: - Shared Filler Lists (single source of truth)

    static let fillerPrefixes = [
        "please", "can you", "could you", "hey", "okay", "ok",
        "so", "well", "actually", "just", "i need to",
        "i want to", "i'd like to", "go ahead and"
    ]

    static let fillerSuffixes = [
        "please", "thanks", "thank you", "now",
        "for me", "right now"
    ]

    static func matchCustom(_ text: String, customCommands: [CustomVoiceCommand]) -> CustomCommandMatch? {
        let normalized = normalize(text)

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

    static func normalize(_ text: String) -> String {
        var result = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        // Strip filler prefixes iteratively
        var didStrip = true
        while didStrip {
            didStrip = false
            for prefix in fillerPrefixes {
                let check = prefix + " "
                if result.hasPrefix(check) {
                    result = String(result.dropFirst(check.count))
                    didStrip = true
                    break
                }
            }
        }

        // Strip filler suffixes iteratively
        didStrip = true
        while didStrip {
            didStrip = false
            for suffix in fillerSuffixes {
                let check = " " + suffix
                if result.hasSuffix(check) {
                    result = String(result.dropLast(check.count))
                    didStrip = true
                    break
                }
            }
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}
