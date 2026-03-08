import Foundation
import os

final class VADFilter {
    var onSpeechStarted: (() -> Void)?
    var onSpeechEnded: (() -> Void)?

    private let onsetThreshold: Float
    private let offsetThreshold: Float
    private let onsetDuration: TimeInterval
    private let offsetDuration: TimeInterval
    private let frameSize: Int // samples per frame (e.g. 480 = 30ms at 16kHz)

    private var isSpeaking = false
    private var onsetFrames = 0
    private var offsetFrames = 0
    private let requiredOnsetFrames: Int
    private let requiredOffsetFrames: Int

    private let logger = Logger.audio

    init(
        sampleRate: Double = Constants.Defaults.sampleRate,
        onsetThreshold: Float = Constants.Defaults.vadOnsetThreshold,
        offsetThreshold: Float = Constants.Defaults.vadOffsetThreshold,
        onsetDuration: TimeInterval = Constants.Defaults.vadOnsetDuration,
        offsetDuration: TimeInterval = Constants.Defaults.vadOffsetDuration
    ) {
        self.onsetThreshold = onsetThreshold
        self.offsetThreshold = offsetThreshold
        self.onsetDuration = onsetDuration
        self.offsetDuration = offsetDuration
        self.frameSize = Int(sampleRate * 0.03) // 30ms frames
        self.requiredOnsetFrames = Int(onsetDuration / 0.03)
        self.requiredOffsetFrames = Int(offsetDuration / 0.03)
    }

    func process(samples: [Float]) {
        var offset = 0
        while offset + frameSize <= samples.count {
            let frame = Array(samples[offset..<offset + frameSize])
            let rms = computeRMS(frame)
            processFrame(rms: rms)
            offset += frameSize
        }
    }

    func reset() {
        isSpeaking = false
        onsetFrames = 0
        offsetFrames = 0
    }

    private func processFrame(rms: Float) {
        if !isSpeaking {
            if rms > onsetThreshold {
                onsetFrames += 1
                if onsetFrames >= requiredOnsetFrames {
                    isSpeaking = true
                    onsetFrames = 0
                    offsetFrames = 0
                    logger.debug("Speech started")
                    onSpeechStarted?()
                }
            } else {
                onsetFrames = 0
            }
        } else {
            if rms < offsetThreshold {
                offsetFrames += 1
                if offsetFrames >= requiredOffsetFrames {
                    isSpeaking = false
                    offsetFrames = 0
                    onsetFrames = 0
                    logger.debug("Speech ended")
                    onSpeechEnded?()
                }
            } else {
                offsetFrames = 0
            }
        }
    }

    private func computeRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(samples.count))
    }
}
