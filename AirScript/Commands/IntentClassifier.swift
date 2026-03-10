import Foundation
import AppKit
import os

enum Intent {
    case command(CommandAction)
    case dictation
}

@MainActor
final class IntentClassifier {
    private let logger = Logger.commands
    private var customAliases: [String: String] = [:]
    private var installedApps: Set<String> = []
    private var lastAppScanDate: Date?
    private var cachedRunningAppNames: [String] = []
    private var lastRunningAppScanDate: Date?

    // MARK: - Command Verb Groups

    private static let appSwitchVerbs: Set<String> = [
        "switch", "go", "open", "launch", "start", "activate", "show"
    ]

    private static let systemVerbs: Set<String> = [
        "close", "minimize", "maximize", "fullscreen", "lock", "screenshot"
    ]

    private static let mediaVerbs: Set<String> = [
        "play", "pause", "skip", "stop", "mute", "unmute"
    ]

    private static let clipboardVerbs: Set<String> = [
        "copy", "paste", "cut", "undo", "redo"
    ]

    private static let allCommandVerbs: Set<String> = appSwitchVerbs
        .union(systemVerbs)
        .union(mediaVerbs)
        .union(clipboardVerbs)

    // MARK: - Known System Targets

    private static let systemTargets: Set<String> = [
        "desktop", "space", "screen", "tab", "window"
    ]

    // MARK: - Prepositions to strip between verb and target

    private static let prepositions: Set<String> = [
        "to", "up", "the", "a", "an", "my", "this"
    ]

    // MARK: - Exact-match Commands (no target needed)

    private static let exactCommands: [String: CommandAction] = [
        "volume up": .volumeUp,
        "louder": .volumeUp,
        "volume down": .volumeDown,
        "quieter": .volumeDown,
        "softer": .volumeDown,
        "mute": .mute,
        "unmute": .mute,
        "play": .playPause,
        "pause": .playPause,
        "play pause": .playPause,
        "next track": .nextTrack,
        "next song": .nextTrack,
        "skip": .nextTrack,
        "previous track": .previousTrack,
        "previous song": .previousTrack,
        "close window": .closeWindow,
        "close this": .closeWindow,
        "minimize": .minimizeWindow,
        "minimize window": .minimizeWindow,
        "full screen": .fullScreen,
        "fullscreen": .fullScreen,
        "enter full screen": .fullScreen,
        "take screenshot": .screenshot,
        "screenshot": .screenshot,
        "undo": .undo,
        "redo": .redo,
        "copy": .copy,
        "copy that": .copy,
        "paste": .paste,
        "cut": .cut,
        "select all": .selectAll,
        "new tab": .newTab,
        "new window": .newWindow,
        "close tab": .closeTab,
        "lock screen": .lockScreen,
        "next desktop": .nextDesktop,
        "next space": .nextDesktop,
        "right desktop": .nextDesktop,
        "previous desktop": .previousDesktop,
        "previous space": .previousDesktop,
        "left desktop": .previousDesktop,
    ]

    // MARK: - Public API

    func registerCustomAliases(_ aliases: [String: String]) {
        customAliases = aliases
    }

    func classify(_ text: String, isCommandMode: Bool = false) -> (intent: Intent, confidence: Double) {
        let normalized = normalize(text)

        guard !normalized.isEmpty else {
            return (.dictation, 1.0)
        }

        // In command mode, be more aggressive about matching
        let confidenceThreshold: Double = isCommandMode ? 0.4 : 0.6

        // Signal 1: Exact command match (highest confidence)
        if let action = Self.exactCommands[normalized] {
            logger.debug("Exact command match: \(normalized)")
            return (.command(action), 1.0)
        }

        // Also try fuzzy match against exact commands
        for (pattern, action) in Self.exactCommands {
            if normalized.fuzzyMatches(pattern, maxDistance: 1) {
                logger.debug("Fuzzy exact match: \(normalized) ≈ \(pattern)")
                return (.command(action), 0.85)
            }
        }

        // Signal 2: Search pattern ("search for X", "google X", "look up X")
        if let searchAction = matchSearchPattern(normalized) {
            return (.command(searchAction), 0.95)
        }

        // Signal 3: Verb + target analysis for app switching
        if let result = classifyVerbTarget(normalized, confidenceThreshold: confidenceThreshold) {
            return result
        }

        // In command mode, lower the bar
        if isCommandMode {
            // Try to interpret as app switch even without strong verb match
            if let appAction = tryAppNameOnly(normalized) {
                return (.command(appAction), 0.5)
            }
        }

        return (.dictation, 1.0 - (isCommandMode ? 0.3 : 0.0))
    }

    // MARK: - Signal: Search Patterns

    private func matchSearchPattern(_ text: String) -> CommandAction? {
        let searchPrefixes = ["search for ", "google ", "look up "]
        for prefix in searchPrefixes {
            if text.hasPrefix(prefix) {
                let query = String(text.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
                if !query.isEmpty {
                    return .search(query: query)
                }
            }
        }
        return nil
    }

    // MARK: - Signal: Verb + Target Classification

    private func classifyVerbTarget(_ text: String, confidenceThreshold: Double) -> (Intent, Double)? {
        let words = text.components(separatedBy: " ")
        guard !words.isEmpty else { return nil }

        // Find the command verb — may not be the first word due to filler
        var verbIndex: Int?
        var verb: String?

        for (i, word) in words.enumerated() {
            if Self.allCommandVerbs.contains(word) {
                verbIndex = i
                verb = word
                break
            }
        }

        guard let verb, let verbIdx = verbIndex else { return nil }

        // Extract target: everything after verb, skipping prepositions
        var targetWords: [String] = []
        var i = verbIdx + 1
        // Skip prepositions immediately after verb
        while i < words.count && Self.prepositions.contains(words[i]) {
            i += 1
        }
        while i < words.count {
            // Stop if remaining words form a trailing filler phrase
            let remaining = words[i...].joined(separator: " ")
            if CommandVocabulary.fillerSuffixes.contains(remaining) { break }
            targetWords.append(words[i])
            i += 1
        }

        let rawTarget = targetWords.joined(separator: " ")
        let target = cleanAppName(rawTarget)

        // App switch verbs need a valid target
        if Self.appSwitchVerbs.contains(verb) {
            guard !target.isEmpty else { return nil }

            if isKnownTarget(target) {
                var confidence = 0.9
                // Boost if verb is first meaningful word
                if verbIdx == 0 { confidence += 0.05 }
                // Penalty for long sentences (likely dictation)
                if words.count > 7 { confidence -= 0.3 }

                let action: CommandAction = (verb == "launch" || verb == "start")
                    ? .openApp(name: target)
                    : .switchToApp(name: target)

                if confidence >= confidenceThreshold {
                    logger.debug("Verb+target match: \(verb) → \(target) (conf: \(confidence))")
                    return (.command(action), confidence)
                }
            }
            // Target not known → this is dictation ("open the door")
            return nil
        }

        // System/media/clipboard verbs without targets are handled by exactCommands above
        // But some system verbs take targets: "close window", "close tab"
        if Self.systemVerbs.contains(verb) && !target.isEmpty {
            if Self.systemTargets.contains(target) {
                let compound = "\(verb) \(target)"
                if let action = Self.exactCommands[compound] {
                    return (.command(action), 0.9)
                }
            }
        }

        return nil
    }

    // MARK: - Target Validation

    private func isKnownTarget(_ target: String) -> Bool {
        let lower = target.lowercased()

        // 1. Built-in app aliases
        if OSCommandExecutor.appAliases[lower] != nil { return true }

        // 2. Custom aliases
        if customAliases[lower] != nil { return true }

        // 3. Running applications (cached, refreshed every 10 seconds)
        // Use contains matching to handle partial transcriptions ("note" → "Notes")
        refreshRunningAppsIfNeeded()
        for name in cachedRunningAppNames {
            if name.localizedCaseInsensitiveContains(target) { return true }
        }

        // 4. System targets
        if Self.systemTargets.contains(lower) { return true }

        // 5. Installed apps in /Applications
        if isInstalledApp(lower) { return true }

        return false
    }

    private func refreshRunningAppsIfNeeded() {
        let now = Date()
        guard let lastScan = lastRunningAppScanDate else {
            cachedRunningAppNames = NSWorkspace.shared.runningApplications
                .compactMap { $0.localizedName }
            lastRunningAppScanDate = now
            return
        }
        if now.timeIntervalSince(lastScan) > 10 {
            cachedRunningAppNames = NSWorkspace.shared.runningApplications
                .compactMap { $0.localizedName }
            lastRunningAppScanDate = now
        }
    }

    private func isInstalledApp(_ name: String) -> Bool {
        // Cache installed apps, refresh every 5 minutes
        let now = Date()
        let needsRefresh: Bool
        if installedApps.isEmpty {
            needsRefresh = true
        } else if let lastScan = lastAppScanDate {
            needsRefresh = now.timeIntervalSince(lastScan) > 300
        } else {
            needsRefresh = true
        }
        if needsRefresh {
            scanInstalledApps()
            lastAppScanDate = now
        }
        // Prefix match: "note" matches "notes", "term" matches "terminal"
        return installedApps.contains { $0.hasPrefix(name) || name.hasPrefix($0) }
    }

    private func scanInstalledApps() {
        installedApps.removeAll()
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ]
        let fm = FileManager.default
        for path in searchPaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let appName = String(item.dropLast(4)).lowercased()
                installedApps.insert(appName)
            }
        }
    }

    // MARK: - Fallback: bare app name in command mode

    private func tryAppNameOnly(_ text: String) -> CommandAction? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        if isKnownTarget(cleaned) {
            return .switchToApp(name: cleanAppName(cleaned))
        }
        return nil
    }

    // MARK: - Text Normalization

    private func normalize(_ text: String) -> String {
        CommandVocabulary.normalize(text)
    }

    private func cleanAppName(_ name: String) -> String {
        var result = name.trimmingCharacters(in: .whitespaces)
        // Strip trailing "app"
        if result.lowercased().hasSuffix(" app") {
            result = String(result.dropLast(4)).trimmingCharacters(in: .whitespaces)
        }
        // Strip articles
        for article in ["the ", "a ", "an "] {
            if result.lowercased().hasPrefix(article) {
                result = String(result.dropFirst(article.count))
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}
