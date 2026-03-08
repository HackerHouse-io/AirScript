import Foundation
import SwiftData

enum SnippetActionType: String, Codable {
    case text
    case shell
    case keystroke
}

@Model
final class Snippet {
    @Attribute(.unique) var id: UUID
    var trigger: String
    var actionType: SnippetActionType
    var value: String
    var usageCount: Int
    var lastUsed: Date?
    var createdAt: Date

    init(
        trigger: String,
        actionType: SnippetActionType = .text,
        value: String
    ) {
        self.id = UUID()
        self.trigger = trigger
        self.actionType = actionType
        self.value = value
        self.usageCount = 0
        self.lastUsed = nil
        self.createdAt = Date()
    }
}
