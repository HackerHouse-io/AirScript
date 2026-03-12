import Foundation
import os

@MainActor
@Observable
final class LLMModelManager {
    var availableModels: [ModelInfo] = []
    var isLoading = false

    private var downloadTask: Task<Void, any Error>?
    private let logger = Logger.models

    private static let downloadSession: URLSession = {
        URLSession(configuration: .default)
    }()

    private static let modelDefinitions: [(id: String, display: String, size: String, params: String)] = [
        ("mlx-community/gemma-3-1b-it-qat-4bit", "Gemma 3 1B (QAT)", "~733 MB", "1B"),
        ("mlx-community/Llama-3.2-3B-Instruct-4bit", "Llama 3.2 3B", "~1.8 GB", "3B"),
        ("mlx-community/Qwen3.5-4B-MLX-4bit", "Qwen 3.5 4B", "~3.0 GB", "4B"),
    ]

    /// Sentinel written after all files finish; its presence means the download completed.
    private static let completionMarker = ".download_complete"

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

        availableModels = Self.modelDefinitions.map { (id, display, size, params) in
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
                isDownloadable: true
            )
        }
    }

    // MARK: - Download

    /// Starts a download in a tracked task so it can be cancelled via `cancelDownload()`.
    /// Cancels any in-flight download first to avoid cleanup races.
    func startDownload(named modelName: String, onProgress: @escaping @Sendable (Double) -> Void) async throws {
        cancelDownload()
        let task = Task {
            try await self.downloadModel(named: modelName, onProgress: onProgress)
        }
        downloadTask = task
        defer { downloadTask = nil }
        try await task.value
    }

    /// Cancels the in-flight download. The underlying URLSession download task is
    /// cooperatively cancelled via Swift concurrency's task cancellation, so the
    /// network transfer stops promptly (not just between files).
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        for index in availableModels.indices where availableModels[index].isDownloading {
            availableModels[index].isDownloading = false
            availableModels[index].downloadProgress = 0
        }

        logger.info("LLM model download cancelled")
    }

    private func downloadModel(named modelName: String, onProgress: @escaping @Sendable (Double) -> Void) async throws {
        logger.info("Downloading LLM model: \(modelName)")

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloading = true
            availableModels[index].downloadProgress = 0
        }

        var didComplete = false
        defer {
            if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
                availableModels[index].isDownloading = false
            }
            if !didComplete {
                // Clean up partial download so it doesn't appear as "downloaded"
                let modelDir = Self.modelDirectory(for: modelName)
                try? FileManager.default.removeItem(at: modelDir)
            }
        }

        try Task.checkCancellation()
        try URL.ensureDirectoryExists(URL.llmModels)

        let modelDir = Self.modelDirectory(for: modelName)
        try URL.ensureDirectoryExists(modelDir)

        // Fetch file list with sizes from HuggingFace tree API
        let encodedName = modelName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? modelName
        guard let apiURL = URL(string: "https://huggingface.co/api/models/\(encodedName)/tree/main") else {
            throw LLMDownloadError.invalidModelID(modelName)
        }
        let (data, _) = try await Self.downloadSession.data(from: apiURL)
        let treeEntries = try JSONDecoder().decode([HFTreeEntry].self, from: data)

        // Filter to model files, reject path traversal
        let extensions = Set(["safetensors", "json", "txt", "model"])
        let files = treeEntries.filter { entry in
            guard entry.type == "file",
                  !entry.path.contains("..") else { return false }
            let ext = (entry.path as NSString).pathExtension.lowercased()
            return extensions.contains(ext)
        }

        guard !files.isEmpty else {
            throw LLMDownloadError.noFilesFound(modelName)
        }

        // Byte-based progress: use sizes from tree API
        let fileSizes = files.map { max(Int64($0.size), 1) }
        let totalBytes = fileSizes.reduce(0, +)
        var downloadedBytes: Int64 = 0

        for (fileIndex, file) in files.enumerated() {
            try Task.checkCancellation()

            let encodedPath = file.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.path
            guard let fileURL = URL(string: "https://huggingface.co/\(encodedName)/resolve/main/\(encodedPath)?download=true") else {
                throw LLMDownloadError.invalidFileURL(file.path)
            }
            let destPath = modelDir.appendingPathComponent(file.path)

            // Create subdirectories if needed
            let destDir = destPath.deletingLastPathComponent()
            try URL.ensureDirectoryExists(destDir)

            let fileSize = fileSizes[fileIndex]

            // Skip if already downloaded
            if FileManager.default.fileExists(atPath: destPath.path) {
                downloadedBytes += fileSize
                let fraction = Double(downloadedBytes) / Double(totalBytes)
                updateProgress(for: modelName, fraction: fraction, onProgress: onProgress)
                continue
            }

            // Download with byte-accurate per-file progress
            let capturedDownloaded = downloadedBytes
            let delegate = DownloadProgressDelegate { [weak self] fileProgress in
                let currentBytes = capturedDownloaded + Int64(fileProgress * Double(fileSize))
                let fraction = Double(currentBytes) / Double(totalBytes)
                Task { @MainActor [weak self] in
                    self?.updateProgress(for: modelName, fraction: fraction, onProgress: onProgress)
                }
            }

            let (tempURL, _) = try await Self.downloadSession.download(from: fileURL, delegate: delegate)

            try Task.checkCancellation()

            // Move to final location
            if FileManager.default.fileExists(atPath: destPath.path) {
                try FileManager.default.removeItem(at: destPath)
            }
            try FileManager.default.moveItem(at: tempURL, to: destPath)

            downloadedBytes += fileSize
            let fraction = Double(downloadedBytes) / Double(totalBytes)
            updateProgress(for: modelName, fraction: fraction, onProgress: onProgress)
        }

        // Write completion marker so getDownloadedModels can distinguish finished downloads
        let marker = modelDir.appendingPathComponent(Self.completionMarker)
        try Data().write(to: marker)

        didComplete = true

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = true
            availableModels[index].downloadProgress = 1.0
        }
        onProgress(1.0)

        logger.info("LLM model downloaded: \(modelName)")
    }

    private func updateProgress(for modelName: String, fraction: Double, onProgress: @Sendable (Double) -> Void) {
        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].downloadProgress = fraction
        }
        onProgress(fraction)
    }

    // MARK: - Delete

    func deleteModel(named modelName: String) throws {
        let modelDir = Self.modelDirectory(for: modelName)
        if FileManager.default.fileExists(atPath: modelDir.path) {
            try FileManager.default.removeItem(at: modelDir)
            logger.info("Deleted LLM model: \(modelName)")
        }

        if let index = availableModels.firstIndex(where: { $0.id == modelName }) {
            availableModels[index].isDownloaded = false
            availableModels[index].downloadProgress = 0
        }
    }

    // MARK: - Filesystem

    static func modelDirectory(for modelID: String) -> URL {
        let safeName = filesystemName(for: modelID)
        return URL.llmModels.appendingPathComponent(safeName)
    }

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

    /// A model counts as downloaded only if the completion marker is present.
    private func getDownloadedModels() -> Set<String> {
        Set(Self.modelDefinitions.map(\.id).filter { modelID in
            let marker = Self.modelDirectory(for: modelID)
                .appendingPathComponent(Self.completionMarker)
            return FileManager.default.fileExists(atPath: marker.path)
        })
    }
}

// MARK: - HuggingFace API Types

private struct HFTreeEntry: Decodable {
    let type: String
    let path: String
    let size: Int
}

// MARK: - Download Progress Delegate

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    private let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Handled by the caller via the async download API
    }
}

// MARK: - Errors

enum LLMDownloadError: Error, LocalizedError {
    case noFilesFound(String)
    case invalidModelID(String)
    case invalidFileURL(String)

    var errorDescription: String? {
        switch self {
        case .noFilesFound(let model):
            "No downloadable files found for model: \(model)"
        case .invalidModelID(let model):
            "Invalid model identifier: \(model)"
        case .invalidFileURL(let path):
            "Could not construct download URL for file: \(path)"
        }
    }
}
