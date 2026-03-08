import Foundation
import WhisperKit
import os

struct ModelInfo: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let sizeDescription: String
    let isRecommended: Bool
    var isDownloaded: Bool
    var isDownloading: Bool
    var downloadProgress: Double
}

@Observable
final class ModelManager {
    var availableModels: [ModelInfo] = []
    var isLoading = false

    private let logger = Logger.models

    func recommendedWhisperModel() -> String {
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = Double(totalRAM) / (1024 * 1024 * 1024)

        if ramGB >= 32 {
            return "openai_whisper-large-v3-v20240930"
        } else if ramGB >= 16 {
            return "openai_whisper-large-v3-v20240930"
        } else {
            return "openai_whisper-small-v20240930"
        }
    }

    func fetchAvailableModels() async {
        isLoading = true
        defer { isLoading = false }

        let recommended = recommendedWhisperModel()
        let downloadedModels = getDownloadedModels()

        let models = [
            ("openai_whisper-tiny", "Tiny", "~75 MB"),
            ("openai_whisper-base", "Base", "~150 MB"),
            ("openai_whisper-small", "Small", "~500 MB"),
            ("openai_whisper-small.en", "Small (English)", "~500 MB"),
            ("openai_whisper-medium", "Medium", "~1.5 GB"),
            ("openai_whisper-large-v3-v20240930", "Large v3", "~3 GB"),
            ("openai_whisper-large-v3-turbo", "Large v3 Turbo", "~1.6 GB"),
        ]

        availableModels = models.map { (id, display, size) in
            ModelInfo(
                id: id,
                name: id,
                displayName: display,
                sizeDescription: size,
                isRecommended: id == recommended,
                isDownloaded: downloadedModels.contains(id),
                isDownloading: false,
                downloadProgress: 0
            )
        }
    }

    func downloadModel(named modelName: String) async throws {
        logger.info("Downloading model: \(modelName)")

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloading = true
        }

        defer {
            if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
                availableModels[index].isDownloading = false
            }
        }

        // WhisperKit handles model download internally when you init with a model name
        // We pre-download by initializing and then releasing
        let _ = try await WhisperKit(model: modelName, verbose: false, logLevel: .none)

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = true
            availableModels[index].downloadProgress = 1.0
        }

        logger.info("Model downloaded: \(modelName)")
    }

    func deleteModel(named modelName: String) throws {
        let modelDir = URL.whisperModels.appendingPathComponent(modelName)
        if FileManager.default.fileExists(atPath: modelDir.path) {
            try FileManager.default.removeItem(at: modelDir)
            logger.info("Deleted model: \(modelName)")
        }

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = false
            availableModels[index].downloadProgress = 0
        }
    }

    private func getDownloadedModels() -> Set<String> {
        let modelsDir = URL.whisperModels
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: modelsDir,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return Set(contents.map(\.lastPathComponent))
    }
}
