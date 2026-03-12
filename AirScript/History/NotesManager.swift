import Foundation
import SwiftData
import os

final class NotesManager {
    private let logger = Logger.general

    func create(
        text: String,
        rawText: String,
        duration: TimeInterval,
        audioFileURL: URL? = nil,
        in context: ModelContext
    ) -> AirNote {
        let note = AirNote(
            text: text,
            rawText: rawText,
            duration: duration,
            audioFileURL: audioFileURL
        )
        context.insert(note)
        logger.info("Note created: \(String(text.prefix(50)))")
        return note
    }

    func allNotes(in context: ModelContext) -> [AirNote] {
        let descriptor = FetchDescriptor<AirNote>(
            predicate: #Predicate<AirNote> { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func pinnedNotes(in context: ModelContext) -> [AirNote] {
        let descriptor = FetchDescriptor<AirNote>(
            predicate: #Predicate<AirNote> { $0.isPinned && !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
