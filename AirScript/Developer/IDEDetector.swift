import AppKit

enum IDEType: String {
    case xcode
    case vscode
    case cursor
    case windsurf
}

enum IDEDetector {
    static func detectIDE() -> IDEType? {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        return detectIDE(bundleID: bundleID)
    }

    static func detectIDE(bundleID: String) -> IDEType? {
        switch bundleID {
        case Constants.BundleIDs.xcode: return .xcode
        case Constants.BundleIDs.vscode: return .vscode
        case Constants.BundleIDs.cursor: return .cursor
        case Constants.BundleIDs.windsurf: return .windsurf
        default: return nil
        }
    }

    static var isInIDE: Bool {
        detectIDE() != nil
    }
}
