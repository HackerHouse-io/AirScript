import Foundation
import SwiftData

enum ModelStatus: String, Codable {
    case available
    case downloading
    case downloaded
    case failed
}

@Model
final class WhisperModelRecord {
    @Attribute(.unique) var modelName: String
    var status: ModelStatus
    var sizeBytes: Int64
    var downloadedAt: Date?
    var lastUsed: Date?
    var checksumSHA256: String?

    init(
        modelName: String,
        status: ModelStatus = .available,
        sizeBytes: Int64 = 0
    ) {
        self.modelName = modelName
        self.status = status
        self.sizeBytes = sizeBytes
        self.downloadedAt = nil
        self.lastUsed = nil
        self.checksumSHA256 = nil
    }
}
