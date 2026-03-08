import Foundation
import SwiftData

@Model
final class AirNote {
    @Attribute(.unique) var id: UUID
    var text: String
    var rawText: String
    var createdAt: Date
    var duration: TimeInterval
    var audioFileURL: URL?
    var tags: [String]
    var isPinned: Bool
    var isArchived: Bool

    init(
        text: String,
        rawText: String,
        duration: TimeInterval,
        audioFileURL: URL? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.text = text
        self.rawText = rawText
        self.createdAt = Date()
        self.duration = duration
        self.audioFileURL = audioFileURL
        self.tags = tags
        self.isPinned = false
        self.isArchived = false
    }
}
