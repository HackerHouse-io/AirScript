import Foundation
import SwiftData

@Model
final class Transcript {
    @Attribute(.unique) var id: UUID
    var text: String
    var rawText: String
    var createdAt: Date
    var duration: TimeInterval
    var wordCount: Int
    var wordsPerMinute: Double
    var model: String
    var llmModel: String?
    var appBundleID: String?
    var appName: String?
    var audioFileURL: URL?
    var wasCommand: Bool
    var commandAction: String?
    var isArchived: Bool
    var archivedAt: Date?
    @Relationship(inverse: \TranscriptTag.transcripts) var tags: [TranscriptTag]

    init(
        text: String,
        rawText: String,
        duration: TimeInterval,
        model: String,
        llmModel: String? = nil,
        appBundleID: String? = nil,
        appName: String? = nil,
        audioFileURL: URL? = nil,
        wasCommand: Bool = false,
        commandAction: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.rawText = rawText
        self.createdAt = Date()
        self.duration = duration
        let wc = text.split(separator: " ").count
        self.wordCount = wc
        self.wordsPerMinute = duration > 0 ? Double(wc) / (duration / 60.0) : 0
        self.model = model
        self.llmModel = llmModel
        self.appBundleID = appBundleID
        self.appName = appName
        self.audioFileURL = audioFileURL
        self.wasCommand = wasCommand
        self.commandAction = commandAction
        self.isArchived = false
        self.archivedAt = nil
        self.tags = []
    }
}
