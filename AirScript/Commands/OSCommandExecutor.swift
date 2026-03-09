import AppKit
import os

final class OSCommandExecutor {
    private let logger = Logger.commands
    private var customAliases: [String: String] = [:]

    func registerCustomAliases(_ aliases: [String: String]) {
        customAliases = aliases
    }

    private static let appAliases: [String: String] = [
        "terminal": "Terminal",
        "chrome": "Google Chrome",
        "firefox": "Firefox",
        "code": "Visual Studio Code",
        "vscode": "Visual Studio Code",
        "finder": "Finder",
        "messages": "Messages",
        "mail": "Mail",
        "music": "Music",
        "slack": "Slack",
        "discord": "Discord",
        "safari": "Safari",
        "notes": "Notes",
        "cursor": "Cursor",
        "xcode": "Xcode",
        "iterm": "iTerm2",
        "warp": "Warp",
    ]

    func execute(_ action: CommandAction) async {
        switch action {
        case .switchToApp(let name):
            activateApp(named: name)
        case .openApp(let name):
            launchApp(named: name)
        case .nextDesktop:
            sendKeystroke(keyCode: 0x7C, flags: .maskControl) // Ctrl+Right
        case .previousDesktop:
            sendKeystroke(keyCode: 0x7B, flags: .maskControl) // Ctrl+Left
        case .volumeUp:
            sendMediaKey(NX_KEYTYPE_SOUND_UP)
        case .volumeDown:
            sendMediaKey(NX_KEYTYPE_SOUND_DOWN)
        case .mute:
            sendMediaKey(NX_KEYTYPE_MUTE)
        case .playPause:
            sendMediaKey(NX_KEYTYPE_PLAY)
        case .nextTrack:
            sendMediaKey(NX_KEYTYPE_NEXT)
        case .previousTrack:
            sendMediaKey(NX_KEYTYPE_PREVIOUS)
        case .closeWindow:
            sendKeystroke(keyCode: 0x0D, flags: .maskCommand) // ⌘W
        case .minimizeWindow:
            sendKeystroke(keyCode: 0x2F, flags: .maskCommand) // ⌘M
        case .fullScreen:
            sendKeystroke(keyCode: 0x03, flags: [.maskCommand, .maskControl]) // ⌘⌃F
        case .screenshot:
            sendKeystroke(keyCode: 0x14, flags: [.maskCommand, .maskShift]) // ⌘⇧3
        case .search(let query):
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                NSWorkspace.shared.open(url)
            }
        case .undo:
            sendKeystroke(keyCode: 0x06, flags: .maskCommand) // ⌘Z
        case .redo:
            sendKeystroke(keyCode: 0x06, flags: [.maskCommand, .maskShift]) // ⌘⇧Z
        case .copy:
            sendKeystroke(keyCode: 0x08, flags: .maskCommand) // ⌘C
        case .paste:
            sendKeystroke(keyCode: 0x09, flags: .maskCommand) // ⌘V
        case .cut:
            sendKeystroke(keyCode: 0x07, flags: .maskCommand) // ⌘X
        case .selectAll:
            sendKeystroke(keyCode: 0x00, flags: .maskCommand) // ⌘A
        case .newTab:
            sendKeystroke(keyCode: 0x11, flags: .maskCommand) // ⌘T
        case .newWindow:
            sendKeystroke(keyCode: 0x2D, flags: .maskCommand) // ⌘N
        case .closeTab:
            sendKeystroke(keyCode: 0x0D, flags: .maskCommand) // ⌘W
        case .lockScreen:
            sendKeystroke(keyCode: 0x0C, flags: [.maskCommand, .maskControl]) // ⌘⌃Q
        }
    }

    private func activateApp(named name: String) {
        let apps = NSWorkspace.shared.runningApplications

        // Try exact substring match on running apps
        if let app = apps.first(where: {
            $0.localizedName?.localizedCaseInsensitiveContains(name) == true
        }) {
            app.activate()
            logger.info("Activated: \(app.localizedName ?? name)")
            return
        }

        // Try alias lookup (custom aliases override built-in)
        let mergedAliases = Self.appAliases.merging(customAliases) { _, custom in custom }
        if let resolved = mergedAliases[name.lowercased()] {
            if let app = apps.first(where: {
                $0.localizedName?.localizedCaseInsensitiveContains(resolved) == true
            }) {
                app.activate()
                logger.info("Activated via alias: \(app.localizedName ?? resolved)")
                return
            }
            // Not running — try launching the resolved name
            launchApp(named: resolved)
            return
        }

        // Fallback — try launching with title-cased name
        let titleCased = name.prefix(1).uppercased() + name.dropFirst()
        launchApp(named: titleCased)
    }

    private func launchApp(named name: String) {
        let config = NSWorkspace.OpenConfiguration()

        // Try bundle identifier
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name) {
            NSWorkspace.shared.openApplication(at: url, configuration: config)
            return
        }

        // Try /Applications
        let appURL = URL(fileURLWithPath: "/Applications/\(name).app")
        if FileManager.default.fileExists(atPath: appURL.path) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            return
        }

        // Try /System/Applications (Notes, etc.)
        let systemURL = URL(fileURLWithPath: "/System/Applications/\(name).app")
        if FileManager.default.fileExists(atPath: systemURL.path) {
            NSWorkspace.shared.openApplication(at: systemURL, configuration: config)
            return
        }

        // Try /System/Applications/Utilities (Terminal, etc.)
        let utilitiesURL = URL(fileURLWithPath: "/System/Applications/Utilities/\(name).app")
        if FileManager.default.fileExists(atPath: utilitiesURL.path) {
            NSWorkspace.shared.openApplication(at: utilitiesURL, configuration: config)
            return
        }

        // Try common Apple bundle ID pattern
        let appleBundleID = "com.apple.\(name)"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appleBundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: config)
            return
        }

        logger.warning("App not found: \(name)")
        NSSound.beep()
    }

    private func sendKeystroke(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        TextInjector.sendKeystroke(keyCode: keyCode, flags: flags)
    }

    private func sendMediaKey(_ key: Int32) {
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((key << 16) | (0xA << 8)),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cgSessionEventTap)

        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((key << 16) | (0xB << 8)),
            data2: -1
        )
        keyUp?.cgEvent?.post(tap: .cgSessionEventTap)
    }
}
