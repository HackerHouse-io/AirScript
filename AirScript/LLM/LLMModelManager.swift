import Foundation
import os

@Observable
final class LLMModelManager {
    var availableModels: [ModelInfo] = []
    var isLoading = false

    private let logger = Logger.models

    static func recommendedLLMModelStatic() -> String {
        let ramGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        if ramGB >= 16 {
            return "mlx-community/Qwen3.5-4B-MLX-4bit"
        } else {
            return "mlx-community/gemma-3-1b-it-qat-4bit"
        }
    }

    func recommendedLLMModel() -> String {
        Self.recommendedLLMModelStatic()
    }

    func fetchAvailableModels() async {
        isLoading = true
        defer { isLoading = false }

        let recommended = recommendedLLMModel()
        let downloadedModels = getDownloadedModels()

        let models = [
            // Ultra-light
            ("mlx-community/gemma-3-1b-it-qat-4bit", "Gemma 3 1B (QAT)", "~733 MB", "1B"),
            // Light
            ("mlx-community/Llama-3.2-3B-Instruct-4bit", "Llama 3.2 3B", "~1.8 GB", "3B"),
            // Best quality
            ("mlx-community/Qwen3.5-4B-MLX-4bit", "Qwen 3.5 4B", "~3.0 GB", "4B"),
        ]

        availableModels = models.map { (id, display, size, params) in
            ModelInfo(
                id: id,
                name: id,
                displayName: display,
                sizeDescription: size,
                parameterCount: params,
                isRecommended: id == recommended,
                isDownloaded: downloadedModels.contains(id),
                isDownloading: false,
                downloadProgress: 0,
                isDownloadable: false
            )
        }
    }

    // LLM model download is not yet implemented.
    // Models must be downloaded externally for now.

    func deleteModel(named modelName: String) throws {
        let safeName = Self.filesystemName(for: modelName)
        let modelDir = URL.llmModels.appendingPathComponent(safeName)
        if FileManager.default.fileExists(atPath: modelDir.path) {
            try FileManager.default.removeItem(at: modelDir)
            logger.info("Deleted LLM model: \(modelName)")
        }

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = false
            availableModels[index].downloadProgress = 0
        }
    }

    // MARK: - Filesystem Encoding

    /// Characters safe for directory names (preserves readability while encoding `/`).
    private static let filenameSafeCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._")
        return set
    }()

    /// Percent-encodes a model ID for use as a directory name.
    static func filesystemName(for modelID: String) -> String {
        modelID.addingPercentEncoding(withAllowedCharacters: filenameSafeCharacters) ?? modelID
    }

    /// Recovers the original model ID from a percent-encoded directory name.
    static func modelID(fromFilesystemName name: String) -> String {
        name.removingPercentEncoding ?? name
    }

    private func getDownloadedModels() -> Set<String> {
        let modelsDir = URL.llmModels
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: modelsDir,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return Set(contents.map { Self.modelID(fromFilesystemName: $0.lastPathComponent) })
    }
}
