import Foundation
import SwiftData
import os

enum DataExporter {
    private static let logger = Logger.general

    // MARK: - Export DTOs

    struct TranscriptExport: Codable {
        let id: UUID
        let text: String
        let rawText: String
        let createdAt: Date
        let duration: TimeInterval
        let wordCount: Int
        let wordsPerMinute: Double
        let model: String
        let llmModel: String?
        let appBundleID: String?
        let appName: String?
        let wasCommand: Bool
        let commandAction: String?
        let isArchived: Bool

        init(from model: Transcript) {
            self.id = model.id
            self.text = model.text
            self.rawText = model.rawText
            self.createdAt = model.createdAt
            self.duration = model.duration
            self.wordCount = model.wordCount
            self.wordsPerMinute = model.wordsPerMinute
            self.model = model.model
            self.llmModel = model.llmModel
            self.appBundleID = model.appBundleID
            self.appName = model.appName
            self.wasCommand = model.wasCommand
            self.commandAction = model.commandAction
            self.isArchived = model.isArchived
        }
    }

    struct DictionaryEntryExport: Codable {
        let id: UUID
        let spoken: String
        let written: String
        let caseSensitive: Bool
        let category: String
        let source: DictionarySource
        let createdAt: Date
        let usageCount: Int

        init(from model: DictionaryEntry) {
            self.id = model.id
            self.spoken = model.spoken
            self.written = model.written
            self.caseSensitive = model.caseSensitive
            self.category = model.category
            self.source = model.source
            self.createdAt = model.createdAt
            self.usageCount = model.usageCount
        }
    }

    struct SnippetExport: Codable {
        let id: UUID
        let trigger: String
        let actionType: SnippetActionType
        let value: String
        let usageCount: Int
        let lastUsed: Date?
        let createdAt: Date

        init(from model: Snippet) {
            self.id = model.id
            self.trigger = model.trigger
            self.actionType = model.actionType
            self.value = model.value
            self.usageCount = model.usageCount
            self.lastUsed = model.lastUsed
            self.createdAt = model.createdAt
        }
    }

    struct AirNoteExport: Codable {
        let id: UUID
        let text: String
        let rawText: String
        let createdAt: Date
        let duration: TimeInterval
        let tags: [String]
        let isPinned: Bool
        let isArchived: Bool

        init(from model: AirNote) {
            self.id = model.id
            self.text = model.text
            self.rawText = model.rawText
            self.createdAt = model.createdAt
            self.duration = model.duration
            self.tags = model.tags
            self.isPinned = model.isPinned
            self.isArchived = model.isArchived
        }
    }

    struct AppStyleExport: Codable {
        let id: UUID
        let category: StyleCategory
        let style: StylePreset
        let isEnabled: Bool

        init(from model: AppStyle) {
            self.id = model.id
            self.category = model.category
            self.style = model.style
            self.isEnabled = model.isEnabled
        }
    }

    struct ProductivityStatExport: Codable {
        let date: Date
        let wordsTranscribed: Int
        let sessionsCount: Int
        let totalDurationSeconds: Double
        let commandsExecuted: Int

        init(from model: ProductivityStat) {
            self.date = model.date
            self.wordsTranscribed = model.wordsTranscribed
            self.sessionsCount = model.sessionsCount
            self.totalDurationSeconds = model.totalDurationSeconds
            self.commandsExecuted = model.commandsExecuted
        }
    }

    struct CorrectionLogExport: Codable {
        let id: UUID
        let originalText: String
        let correctedText: String
        let appBundleID: String?
        let occurredAt: Date
        let count: Int
        let addedToDictionary: Bool

        init(from model: CorrectionLog) {
            self.id = model.id
            self.originalText = model.originalText
            self.correctedText = model.correctedText
            self.appBundleID = model.appBundleID
            self.occurredAt = model.occurredAt
            self.count = model.count
            self.addedToDictionary = model.addedToDictionary
        }
    }

    // MARK: - Export Bundle

    struct ExportBundle: Codable {
        let exportDate: Date
        let appVersion: String
        let transcripts: [TranscriptExport]
        let dictionaryEntries: [DictionaryEntryExport]
        let snippets: [SnippetExport]
        let notes: [AirNoteExport]
        let styles: [AppStyleExport]
        let stats: [ProductivityStatExport]
        let corrections: [CorrectionLogExport]
    }

    // MARK: - Export

    static func exportAll(context: ModelContext) throws -> Data {
        let transcripts = (try? context.fetch(FetchDescriptor<Transcript>())) ?? []
        let entries = (try? context.fetch(FetchDescriptor<DictionaryEntry>())) ?? []
        let snippets = (try? context.fetch(FetchDescriptor<Snippet>())) ?? []
        let notes = (try? context.fetch(FetchDescriptor<AirNote>())) ?? []
        let styles = (try? context.fetch(FetchDescriptor<AppStyle>())) ?? []
        let stats = (try? context.fetch(FetchDescriptor<ProductivityStat>())) ?? []
        let corrections = (try? context.fetch(FetchDescriptor<CorrectionLog>())) ?? []

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        let bundle = ExportBundle(
            exportDate: Date(),
            appVersion: appVersion,
            transcripts: transcripts.map(TranscriptExport.init),
            dictionaryEntries: entries.map(DictionaryEntryExport.init),
            snippets: snippets.map(SnippetExport.init),
            notes: notes.map(AirNoteExport.init),
            styles: styles.map(AppStyleExport.init),
            stats: stats.map(ProductivityStatExport.init),
            corrections: corrections.map(CorrectionLogExport.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        logger.info("Exported \(transcripts.count) transcripts, \(entries.count) dictionary entries, \(snippets.count) snippets, \(notes.count) notes")
        return try encoder.encode(bundle)
    }

    // MARK: - Delete

    static func deleteAll(context: ModelContext) throws {
        try context.delete(model: Transcript.self)
        try context.delete(model: TranscriptTag.self)
        try context.delete(model: DictionaryEntry.self)
        try context.delete(model: Snippet.self)
        try context.delete(model: AirNote.self)
        try context.delete(model: AppStyle.self)
        try context.delete(model: ProductivityStat.self)
        try context.delete(model: CorrectionLog.self)
        try context.save()
        logger.info("All user data deleted from SwiftData")
    }

    static func deleteAudioFiles() {
        let audioDir = URL.audioRecordings
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fm.removeItem(at: file)
        }
        logger.info("Deleted \(files.count) audio files")
    }

    static func clearUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
        logger.info("User defaults cleared")
    }
}
