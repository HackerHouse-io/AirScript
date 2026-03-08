import Foundation

enum PromptBuilder {
    static func dictationCleanup(rawText: String, context: ProcessingContext? = nil) -> String {
        var prompt = """
        Clean up the following dictated text. Follow these rules strictly:
        - Remove filler words (um, uh, like, you know, so, basically, actually, I mean)
        - Fix grammar and punctuation
        - Add proper capitalization
        - Keep the original meaning exactly
        - Do not add or remove content
        - Do not paraphrase or rewrite
        - Output ONLY the cleaned text, nothing else
        """

        if let style = context?.styleInstruction {
            prompt += "\n- Style: \(style)"
        }

        if let previousText = context?.previousTranscript, context?.isBacktrackingEnabled == true {
            prompt += "\n- Previous text for context: \"\(previousText)\""
        }

        prompt += "\n\nDictated text: \(rawText)"
        return prompt
    }

    static func commandMode(selectedText: String, command: String) -> String {
        """
        Apply this instruction to the following text.
        Only output the modified text, nothing else.
        Do not add explanations or commentary.

        Instruction: \(command)

        Text: \(selectedText)
        """
    }

    static func backtrackCorrection(fullText: String, correction: String) -> String {
        """
        The user dictated the following text and then made a correction.
        Apply the correction to the text and output only the corrected version.

        Original text: \(fullText)
        Correction: \(correction)
        """
    }
}
