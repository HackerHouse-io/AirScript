import Foundation
import SwiftData
import os

final class AutoLearnManager {
    private let logger = Logger.general

    func logCorrection(
        original: String,
        corrected: String,
        appBundleID: String?,
        in context: ModelContext
    ) {
        // Check if this correction already exists
        let descriptor = FetchDescriptor<CorrectionLog>(
            predicate: #Predicate<CorrectionLog> {
                $0.originalText == original && $0.correctedText == corrected
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.count += 1
            existing.occurredAt = Date()

            if existing.count >= 3 && !existing.addedToDictionary {
                logger.info("Suggesting dictionary entry: \"\(original)\" → \"\(corrected)\" (corrected \(existing.count) times)")
            }
        } else {
            let log = CorrectionLog(
                originalText: original,
                correctedText: corrected,
                appBundleID: appBundleID
            )
            context.insert(log)
        }
    }

    func pendingSuggestions(in context: ModelContext) -> [CorrectionLog] {
        let descriptor = FetchDescriptor<CorrectionLog>(
            predicate: #Predicate<CorrectionLog> {
                $0.count >= 3 && $0.addedToDictionary == false
            },
            sortBy: [SortDescriptor(\.count, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
