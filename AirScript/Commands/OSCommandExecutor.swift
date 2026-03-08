import AppKit
import os

final class OSCommandExecutor {
    private let logger = Logger.commands

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
            sendKeystroke(keyCode: 0x03, flags: [.maskCommand, .maskShift]) // ⌘⇧3 -- actually keycode for '3' is 0x14
            sendKeystroke(keyCode: 0x14, flags: [.maskCommand, .maskShift])
        case .search(let query):
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                NSWorkspace.shared.open(url)
            }
        case .undo:
            sendKeystroke(keyCode: 0x06, flags: .maskCommand) // ⌘Z
        case .redo:
            sendKeystroke(keyCode: 0x06, flags: [.maskCommand, .maskShift]) // ⌘⇧Z
        }
    }

    private func activateApp(named name: String) {
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: {
            $0.localizedName?.localizedCaseInsensitiveContains(name) == true
        }) {
            app.activate()
            logger.info("Activated: \(app.localizedName ?? name)")
        } else {
            launchApp(named: name)
        }
    }

    private func launchApp(named name: String) {
        let config = NSWorkspace.OpenConfiguration()
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name) {
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        } else {
            // Try by name
            let appURL = URL(fileURLWithPath: "/Applications/\(name).app")
            if FileManager.default.fileExists(atPath: appURL.path) {
                NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            } else {
                logger.warning("App not found: \(name)")
            }
        }
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
