import Foundation
import SwiftData

@Model
final class LLMModelRecord {
    @Attribute(.unique) var modelName: String
    var status: ModelStatus
    var sizeBytes: Int64
    var parameterCount: String?
    var quantization: String?
    var downloadedAt: Date?
    var lastUsed: Date?
    var checksumSHA256: String?

    init(
        modelName: String,
        status: ModelStatus = .available,
        sizeBytes: Int64 = 0,
        parameterCount: String? = nil,
        quantization: String? = nil
    ) {
        self.modelName = modelName
        self.status = status
        self.sizeBytes = sizeBytes
        self.parameterCount = parameterCount
        self.quantization = quantization
        self.downloadedAt = nil
        self.lastUsed = nil
        self.checksumSHA256 = nil
    }
}
