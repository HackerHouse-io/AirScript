import AppKit
import os

actor TextInjector {
    private static let logger = Logger.injection

    static func inject(text: String) async {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        simulatePaste()

        // Restore clipboard after delay
        try? await Task.sleep(for: .milliseconds(500))
        restorePasteboard(pasteboard, contents: savedContents)

        logger.info("Text injected (\(text.count) chars)")
    }

    static func sendKeystroke(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cgSessionEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cgSessionEventTap)
    }

    // MARK: - Private

    private static func simulatePaste() {
        // ⌘V: keyCode 0x09 = 'v'
        sendKeystroke(keyCode: 0x09, flags: .maskCommand)
    }

    private static func savePasteboard(_ pasteboard: NSPasteboard) -> [(NSPasteboard.PasteboardType, Data)] {
        var saved: [(NSPasteboard.PasteboardType, Data)] = []
        for item in pasteboard.pasteboardItems ?? [] {
            for type in item.types {
                if let data = item.data(forType: type) {
                    saved.append((type, data))
                }
            }
        }
        return saved
    }

    private static func restorePasteboard(
        _ pasteboard: NSPasteboard,
        contents: [(NSPasteboard.PasteboardType, Data)]
    ) {
        pasteboard.clearContents()
        guard !contents.isEmpty else { return }

        let item = NSPasteboardItem()
        for (type, data) in contents {
            item.setData(data, forType: type)
        }
        pasteboard.writeObjects([item])
    }
}
