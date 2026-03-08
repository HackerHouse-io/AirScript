import AppKit
import os

final class CommandModeEngine {
    private let llmProcessor: LLMProcessor
    private let logger = Logger.commands

    init(llmProcessor: LLMProcessor) {
        self.llmProcessor = llmProcessor
    }

    func execute(command: String) async throws -> String {
        // Get selected text via ⌘C
        let selectedText = getSelectedText()

        if let selectedText, !selectedText.isEmpty {
            // Transform selected text with LLM
            let result = try await llmProcessor.processCommand(
                selectedText: selectedText,
                command: command
            )
            // Replace via ⌘V
            await TextInjector.inject(text: result)
            return result
        } else {
            // No selection: open browser search
            let query = command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? command
            if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                NSWorkspace.shared.open(url)
            }
            return command
        }
    }

    private func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboardContents(pasteboard)

        // ⌘C to copy selection
        TextInjector.sendKeystroke(keyCode: 0x08, flags: .maskCommand) // 'c'

        // Brief pause for clipboard to update
        Thread.sleep(forTimeInterval: 0.1)

        let selectedText = pasteboard.string(forType: .string)

        // Restore clipboard
        restorePasteboardContents(pasteboard, contents: savedContents)

        return selectedText
    }

    private func savePasteboardContents(_ pasteboard: NSPasteboard) -> [(NSPasteboard.PasteboardType, Data)] {
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

    private func restorePasteboardContents(
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
