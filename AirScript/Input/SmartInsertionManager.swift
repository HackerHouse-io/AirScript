import AppKit
import os

enum CursorContext {
    case startOfField
    case startOfLine
    case midSentence
    case midSentenceAfterSpace
    case unknown
}

struct SmartInsertionManager {
    private let logger = Logger.injection

    func getCursorContext() -> CursorContext {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return .unknown
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        // Get focused UI element
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success else {
            return .unknown
        }
        let element = focusedRef as! AXUIElement

        // Get text value
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
              let text = valueRef as? String else {
            return .unknown
        }

        // Empty field
        if text.isEmpty {
            return .startOfField
        }

        // Get cursor position from selected text range
        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success else {
            return .unknown
        }

        var range = CFRange()
        guard AXValueGetValue(rangeRef as! AXValue, .cfRange, &range) else {
            return .unknown
        }

        let cursorPos = range.location

        // Cursor at very start
        if cursorPos == 0 {
            return .startOfField
        }

        // Analyze character before cursor
        let index = text.index(text.startIndex, offsetBy: Swift.min(cursorPos, text.count))
        let charBefore = text[text.index(before: index)]

        if charBefore == "\n" || charBefore == "\r" {
            return .startOfLine
        }

        if charBefore == " " || charBefore == "\t" {
            return .midSentenceAfterSpace
        }

        return .midSentence
    }

    func adjustText(_ text: String, for context: CursorContext) -> String {
        guard !text.isEmpty else { return text }

        switch context {
        case .startOfField, .startOfLine, .unknown:
            return text

        case .midSentence:
            var adjusted = " " + lowercaseFirst(text)
            adjusted = removeTrailingSinglePeriod(adjusted)
            return adjusted

        case .midSentenceAfterSpace:
            var adjusted = lowercaseFirst(text)
            adjusted = removeTrailingSinglePeriod(adjusted)
            return adjusted
        }
    }

    // MARK: - Private

    private func lowercaseFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        // Don't lowercase acronyms or all-caps words (e.g. "NASA", "API")
        if text.count >= 2 {
            let secondIndex = text.index(after: text.startIndex)
            if text[secondIndex].isUppercase {
                return text
            }
        }
        return first.lowercased() + text.dropFirst()
    }

    private func removeTrailingSinglePeriod(_ text: String) -> String {
        // Only remove a single trailing period, not ellipsis (..) or more
        if text.hasSuffix(".") && !text.hasSuffix("..") {
            return String(text.dropLast())
        }
        return text
    }
}
