import AppKit
import os

final class ContextReader {
    private let logger = Logger.context

    func readActiveContext() -> AppContext {
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let bundleID = frontmostApp?.bundleIdentifier
        let appName = frontmostApp?.localizedName

        var windowTitle: String?
        var visibleText: String?
        var cursorPosition: Int?

        // Read focused UI element via Accessibility API
        if let app = frontmostApp {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            // Get focused window title
            var titleValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &titleValue) == .success {
                let windowElement = titleValue as! AXUIElement
                var title: CFTypeRef?
                if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title) == .success {
                    windowTitle = title as? String
                }
            }

            // Get focused text element value
            var focusedElement: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success {
                let element = focusedElement as! AXUIElement
                var value: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success {
                    if let text = value as? String {
                        // Limit to 2000 chars
                        visibleText = String(text.prefix(2000))
                    }
                }

                // Get cursor position
                var selectedRange: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRange) == .success {
                    var range = CFRange()
                    if AXValueGetValue(selectedRange as! AXValue, .cfRange, &range) {
                        cursorPosition = range.location
                    }
                }
            }
        }

        return AppContext(
            bundleID: bundleID,
            appName: appName,
            windowTitle: windowTitle,
            visibleText: visibleText,
            cursorPosition: cursorPosition
        )
    }

    func extractRelevantTerms(from context: AppContext) -> [String] {
        guard let text = context.visibleText else { return [] }

        // Extract uncommon words that might be names, technical terms, etc.
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
            .filter { word in
                // Keep words with capital letters (names, proper nouns)
                word.first?.isUppercase == true ||
                // Keep camelCase or snake_case (code identifiers)
                word.contains("_") ||
                (word.rangeOfCharacter(from: .uppercaseLetters) != nil &&
                 word.rangeOfCharacter(from: .lowercaseLetters) != nil)
            }

        return Array(Set(words).prefix(50))
    }
}
