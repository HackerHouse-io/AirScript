import Foundation
import SwiftData
import os

final class TranscriptStore {
    private let logger = Logger.general

    func save(
        text: String,
        rawText: String,
        duration: TimeInterval,
        model: String,
        llmModel: String?,
        appBundleID: String?,
        appName: String?,
        wasCommand: Bool,
        commandAction: String?,
        in context: ModelContext
    ) {
        let transcript = Transcript(
            text: text,
            rawText: rawText,
            duration: duration,
            model: model,
            llmModel: llmModel,
            appBundleID: appBundleID,
            appName: appName,
            wasCommand: wasCommand,
            commandAction: commandAction
        )
        context.insert(transcript)
        logger.info("Transcript saved: \(text.prefix(50))")
    }

    func search(query: String, in context: ModelContext) -> [Transcript] {
        let descriptor = FetchDescriptor<Transcript>(
            predicate: #Predicate<Transcript> { $0.text.localizedStandardContains(query) },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func recent(limit: Int = 50, in context: ModelContext) -> [Transcript] {
        var descriptor = FetchDescriptor<Transcript>(
            predicate: #Predicate<Transcript> { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func archive(_ transcript: Transcript) {
        transcript.isArchived = true
        transcript.archivedAt = Date()
    }

    func unarchive(_ transcript: Transcript) {
        transcript.isArchived = false
        transcript.archivedAt = nil
    }
}
