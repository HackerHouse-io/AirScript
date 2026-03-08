import Foundation
import SwiftData

@Model
final class CorrectionLog {
    @Attribute(.unique) var id: UUID
    var originalText: String
    var correctedText: String
    var appBundleID: String?
    var occurredAt: Date
    var count: Int
    var addedToDictionary: Bool

    init(
        originalText: String,
        correctedText: String,
        appBundleID: String? = nil
    ) {
        self.id = UUID()
        self.originalText = originalText
        self.correctedText = correctedText
        self.appBundleID = appBundleID
        self.occurredAt = Date()
        self.count = 1
        self.addedToDictionary = false
    }
}
