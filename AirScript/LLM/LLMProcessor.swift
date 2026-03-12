import Foundation
import os

@Observable
final class LLMProcessor {
    var isModelLoaded = false
    var currentModelName: String?
    var isProcessing = false

    private let logger = Logger.llm

    func loadModel(named modelName: String) async throws {
        logger.info("Loading LLM model: \(modelName)")
        // TODO: Wire to mlx-swift-examples LLM module when dependency builds
        self.currentModelName = modelName
        self.isModelLoaded = true
        logger.info("LLM model loaded: \(modelName)")
    }

    func process(rawText: String, context: ProcessingContext? = nil) async throws -> String {
        guard isModelLoaded else {
            throw LLMError.modelNotLoaded
        }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = PromptBuilder.dictationCleanup(rawText: rawText, context: context)
        logger.debug("LLM prompt: \(String(prompt.prefix(100)))...")

        // TODO: Replace with actual MLX LLM inference
        // For now, do basic rule-based cleanup as a fallback
        let cleaned = basicCleanup(rawText)

        logger.info("LLM processing complete")
        return cleaned
    }

    func processCommand(selectedText: String, command: String) async throws -> String {
        guard isModelLoaded else {
            throw LLMError.modelNotLoaded
        }

        isProcessing = true
        defer { isProcessing = false }

        let _ = PromptBuilder.commandMode(selectedText: selectedText, command: command)

        // Rule-based command processing (fallback until MLX is wired)
        let commandType = RuleBasedCommandProcessor.classify(command)
        if let result = RuleBasedCommandProcessor.apply(commandType, to: selectedText) {
            return result
        }

        return selectedText
    }

    func unloadModel() {
        isModelLoaded = false
        currentModelName = nil
        logger.info("LLM model unloaded")
    }

    // MARK: - Basic rule-based cleanup (fallback until MLX is wired)

    private func basicCleanup(_ text: String) -> String {
        var result = text

        // Remove common fillers
        let fillers = [
            "\\bum\\b", "\\buh\\b", "\\blike\\b(?=\\s+(?:I|we|they|he|she|it|the|a|an|to|in|on|at|for))",
            "\\byou know\\b", "\\bbasically\\b", "\\bI mean\\b",
            "\\bso\\b(?=\\s*,)", "\\bactually\\b(?=\\s*,)"
        ]

        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: filler, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Clean up multiple spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        // Capitalize first letter
        if let first = result.first, first.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }

        // Ensure ends with period
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if !result.isEmpty && !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }

        return result
    }
}

enum LLMError: Error, LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "No LLM model is loaded"
        }
    }
}
