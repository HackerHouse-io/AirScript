import Foundation
import SwiftData

enum DictionarySource: String, Codable {
    case manual
    case autoLearned
}

@Model
final class DictionaryEntry {
    @Attribute(.unique) var id: UUID
    var spoken: String
    var written: String
    var caseSensitive: Bool
    var category: String
    var source: DictionarySource
    var createdAt: Date
    var usageCount: Int

    init(
        spoken: String,
        written: String,
        caseSensitive: Bool = false,
        category: String = "",
        source: DictionarySource = .manual
    ) {
        self.id = UUID()
        self.spoken = spoken
        self.written = written
        self.caseSensitive = caseSensitive
        self.category = category
        self.source = source
        self.createdAt = Date()
        self.usageCount = 0
    }
}
