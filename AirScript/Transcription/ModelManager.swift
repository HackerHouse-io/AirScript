import Foundation
import WhisperKit
import os

struct ModelInfo: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let sizeDescription: String
    let parameterCount: String?
    let isRecommended: Bool
    var isDownloaded: Bool
    var isDownloading: Bool
    var downloadProgress: Double
    var isDownloadable: Bool

    init(id: String, name: String, displayName: String, sizeDescription: String,
         parameterCount: String? = nil, isRecommended: Bool, isDownloaded: Bool,
         isDownloading: Bool, downloadProgress: Double, isDownloadable: Bool = true) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.sizeDescription = sizeDescription
        self.parameterCount = parameterCount
        self.isRecommended = isRecommended
        self.isDownloaded = isDownloaded
        self.isDownloading = isDownloading
        self.downloadProgress = downloadProgress
        self.isDownloadable = isDownloadable
    }

    // MARK: - Display Name Lookups

    private static let whisperDisplayNames: [String: String] = [
        "openai_whisper-small": "Small",
        "openai_whisper-medium": "Medium",
        "openai_whisper-large-v3-v20240930": "Large v3",
        "openai_whisper-large-v3_turbo": "Large v3 Turbo",
    ]

    private static let llmDisplayNames: [String: String] = [
        "mlx-community/gemma-3-1b-it-qat-4bit": "Gemma 3 1B",
        "mlx-community/Llama-3.2-3B-Instruct-4bit": "Llama 3.2 3B",
        "mlx-community/Qwen3.5-4B-MLX-4bit": "Qwen 3.5 4B",
    ]

    static func whisperDisplayName(for id: String) -> String {
        whisperDisplayNames[id] ?? id
    }

    static func llmDisplayName(for id: String) -> String {
        llmDisplayNames[id] ?? id
    }
}

@Observable
final class ModelManager {
    var availableModels: [ModelInfo] = []
    var isLoading = false

    private var downloadTask: Task<Void, any Error>?
    private let logger = Logger.models

    static func recommendedWhisperModelStatic() -> String {
        let ramGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        if ramGB >= 16 {
            return "openai_whisper-large-v3-v20240930"
        } else {
            return "openai_whisper-small"
        }
    }

    func recommendedWhisperModel() -> String {
        Self.recommendedWhisperModelStatic()
    }

    func fetchAvailableModels() async {
        isLoading = true
        defer { isLoading = false }

        let recommended = recommendedWhisperModel()
        let downloadedModels = getDownloadedModels()

        let models = [
            ("openai_whisper-small", "Small", "~500 MB"),
            ("openai_whisper-medium", "Medium", "~1.5 GB"),
            ("openai_whisper-large-v3-v20240930", "Large v3", "~3 GB"),
            ("openai_whisper-large-v3_turbo", "Large v3 Turbo", "~1.6 GB"),
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

    func downloadModel(named modelName: String, onProgress: ((Double) -> Void)? = nil) async throws {
        logger.info("Downloading model: \(modelName)")

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloading = true
            availableModels[index].downloadProgress = 0
        }

        defer {
            if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
                availableModels[index].isDownloading = false
            }
            downloadTask = nil
        }

        try Task.checkCancellation()

        // Ensure the download base directory exists
        try URL.ensureDirectoryExists(URL.whisperModels)

        let _ = try await WhisperKit.download(
            variant: modelName,
            downloadBase: URL.whisperModels.deletingLastPathComponent(),
            progressCallback: { [weak self] progress in
                let fraction = progress.fractionCompleted
                Task { @MainActor [weak self] in
                    guard let self,
                          let index = self.availableModels.firstIndex(where: { $0.id == modelName }) else { return }
                    self.availableModels[index].downloadProgress = fraction
                    onProgress?(fraction)
                }
            }
        )

        try Task.checkCancellation()

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = true
            availableModels[index].downloadProgress = 1.0
        }
        onProgress?(1.0)

        logger.info("Model downloaded: \(modelName)")
    }

    /// Cancels the current download. Best-effort: the UI resets immediately, but the
    /// underlying WhisperKit network request may continue to completion in the background
    /// since WhisperKit's initializer doesn't support cooperative cancellation.
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        for index in availableModels.indices where availableModels[index].isDownloading {
            availableModels[index].isDownloading = false
            availableModels[index].downloadProgress = 0
        }

        logger.info("Model download cancelled")
    }

    /// Starts a download in a tracked task so it can be cancelled.
    /// The optional `onProgress` closure is called on each progress update (0.0–1.0).
    func startDownload(named modelName: String, onProgress: ((Double) -> Void)? = nil) async throws {
        let task = Task {
            try await downloadModel(named: modelName, onProgress: onProgress)
        }
        downloadTask = task
        try await task.value
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
