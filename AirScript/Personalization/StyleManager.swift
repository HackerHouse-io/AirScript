import Foundation

final class StyleManager {
    func styleInstruction(for bundleID: String?, styles: [AppStyle]) -> String? {
        guard let bundleID else { return nil }
        let category = categorize(bundleID: bundleID)

        guard let appStyle = styles.first(where: { $0.category == category && $0.isEnabled }) else {
            return nil
        }

        return instruction(for: appStyle.style)
    }

    func categorize(bundleID: String) -> StyleCategory {
        switch bundleID {
        case Constants.BundleIDs.messages,
             Constants.BundleIDs.whatsapp,
             Constants.BundleIDs.telegram:
            return .personalMessaging

        case Constants.BundleIDs.slack,
             Constants.BundleIDs.discord:
            return .workMessaging

        case Constants.BundleIDs.mail:
            return .email

        case Constants.BundleIDs.vscode,
             Constants.BundleIDs.cursor,
             Constants.BundleIDs.xcode,
             Constants.BundleIDs.windsurf:
            return .codingChat

        case Constants.BundleIDs.notes:
            return .notes

        default:
            return .other
        }
    }

    func instruction(for preset: StylePreset) -> String {
        switch preset {
        case .veryCasual:
            return "Use very casual style: all lowercase, minimal punctuation, abbreviations OK (u, ur, rn, lol, lmao). Short sentences."
        case .casual:
            return "Use casual style: normal capitalization, light punctuation, conversational tone."
        case .excited:
            return "Use excited style: capitalize key words, use exclamation points, energetic tone!"
        case .formal:
            return "Use formal style: proper grammar, full punctuation, professional tone, complete sentences."
        }
    }
}
