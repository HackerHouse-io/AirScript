import Foundation
import WhisperKit
import os

struct TranscriptionResult {
    let text: String
    let segments: [TranscriptionSegment]
    let language: String
    let processingTime: TimeInterval

    struct TranscriptionSegment {
        let text: String
        let start: TimeInterval
        let end: TimeInterval
    }
}

@Observable
final class TranscriptionEngine {
    var isModelLoaded = false
    var currentModelName: String?

    private var whisperKit: WhisperKit?
    private let logger = Logger.transcription

    func loadModel(named modelName: String) async throws {
        logger.info("Loading WhisperKit model: \(modelName)")

        let whisper = try await WhisperKit(
            model: modelName,
            verbose: false,
            logLevel: .none
        )

        self.whisperKit = whisper
        self.currentModelName = modelName
        self.isModelLoaded = true
        logger.info("Model loaded successfully: \(modelName)")
    }

    func transcribe(audioSamples: [Float]) async throws -> TranscriptionResult {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        let results = try await whisperKit.transcribe(audioArray: audioSamples)

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let fullText = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let segments = results.flatMap { result in
            (result.segments ?? []).map { seg in
                TranscriptionResult.TranscriptionSegment(
                    text: seg.text,
                    start: TimeInterval(seg.start),
                    end: TimeInterval(seg.end)
                )
            }
        }

        let language = results.first?.language ?? "en"

        logger.info("Transcription complete in \(String(format: "%.2f", elapsed))s: \"\(fullText.prefix(50))...\"")

        return TranscriptionResult(
            text: fullText,
            segments: segments,
            language: language,
            processingTime: elapsed
        )
    }

    func unloadModel() {
        whisperKit = nil
        isModelLoaded = false
        currentModelName = nil
        logger.info("Model unloaded")
    }
}

enum TranscriptionError: Error, LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "No WhisperKit model is loaded"
        }
    }
}
