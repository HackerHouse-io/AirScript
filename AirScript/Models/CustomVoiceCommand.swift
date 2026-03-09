import Foundation
import SwiftData

enum CustomCommandActionType: String, Codable, CaseIterable {
    case keystroke
    case openApp
    case openURL
}

@Model
final class CustomVoiceCommand {
    @Attribute(.unique) var id: UUID
    var trigger: String
    var actionType: CustomCommandActionType
    var actionValue: String
    var createdAt: Date

    init(trigger: String, actionType: CustomCommandActionType, actionValue: String) {
        self.id = UUID()
        self.trigger = trigger
        self.actionType = actionType
        self.actionValue = actionValue
        self.createdAt = Date()
    }
}
