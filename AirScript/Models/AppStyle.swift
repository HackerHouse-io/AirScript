import Foundation
import SwiftData

enum StyleCategory: String, Codable, CaseIterable {
    case personalMessaging
    case workMessaging
    case email
    case codingChat
    case notes
    case other
}

enum StylePreset: String, Codable, CaseIterable {
    case veryCasual
    case casual
    case excited
    case formal
}

@Model
final class AppStyle {
    @Attribute(.unique) var id: UUID
    var category: StyleCategory
    var style: StylePreset
    var isEnabled: Bool

    init(
        category: StyleCategory,
        style: StylePreset,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.category = category
        self.style = style
        self.isEnabled = isEnabled
    }
}
