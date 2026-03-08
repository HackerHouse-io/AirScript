import Foundation
import os

struct LLMModelInfo: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let sizeDescription: String
    let parameterCount: String
    let isRecommended: Bool
    var isDownloaded: Bool
    var isDownloading: Bool
    var downloadProgress: Double
}

@Observable
final class LLMModelManager {
    var availableModels: [LLMModelInfo] = []
    var isLoading = false

    private let logger = Logger.models

    func recommendedLLMModel() -> String {
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = Double(totalRAM) / (1024 * 1024 * 1024)

        if ramGB >= 32 {
            return "mlx-community/Llama-3.2-3B-Instruct-4bit"
        } else if ramGB >= 16 {
            return "mlx-community/Llama-3.2-1B-Instruct-4bit"
        } else {
            return "mlx-community/Llama-3.2-1B-Instruct-4bit"
        }
    }

    func fetchAvailableModels() async {
        isLoading = true
        defer { isLoading = false }

        let recommended = recommendedLLMModel()

        let models = [
            ("mlx-community/Llama-3.2-1B-Instruct-4bit", "Llama 3.2 1B (4-bit)", "~700 MB", "1B"),
            ("mlx-community/Llama-3.2-3B-Instruct-4bit", "Llama 3.2 3B (4-bit)", "~1.8 GB", "3B"),
            ("mlx-community/Qwen2.5-1.5B-Instruct-4bit", "Qwen 2.5 1.5B (4-bit)", "~900 MB", "1.5B"),
            ("mlx-community/Qwen2.5-3B-Instruct-4bit", "Qwen 2.5 3B (4-bit)", "~1.9 GB", "3B"),
        ]

        availableModels = models.map { (id, display, size, params) in
            LLMModelInfo(
                id: id,
                name: id,
                displayName: display,
                sizeDescription: size,
                parameterCount: params,
                isRecommended: id == recommended,
                isDownloaded: false,
                isDownloading: false,
                downloadProgress: 0
            )
        }
    }
}
