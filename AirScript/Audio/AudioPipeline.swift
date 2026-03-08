import AVFoundation
import Observation
import os

@Observable
final class AudioPipeline {
    var audioLevel: Float = 0
    var isCapturing = false

    private let engine = AVAudioEngine()
    private let ringBuffer: RingBuffer
    private let vadFilter = VADFilter()
    private var converter: AVAudioConverter?
    private let targetSampleRate = Constants.Defaults.sampleRate
    private let logger = Logger.audio

    var onSpeechStarted: (() -> Void)? {
        get { vadFilter.onSpeechStarted }
        set { vadFilter.onSpeechStarted = newValue }
    }

    var onSpeechEnded: (() -> Void)? {
        get { vadFilter.onSpeechEnded }
        set { vadFilter.onSpeechEnded = newValue }
    }

    init() {
        self.ringBuffer = RingBuffer(duration: Constants.Defaults.ringBufferDuration)
    }

    func startCapture() throws {
        guard !isCapturing else { return }

        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        logger.info("Hardware format: \(hwFormat.sampleRate)Hz, \(hwFormat.channelCount)ch")

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioPipelineError.invalidFormat
        }

        if hwFormat.sampleRate != targetSampleRate || hwFormat.channelCount != 1 {
            converter = AVAudioConverter(from: hwFormat, to: targetFormat)
            guard converter != nil else {
                throw AudioPipelineError.converterCreationFailed
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        try engine.start()
        isCapturing = true
        logger.info("Audio capture started")
    }

    func stopCapture() -> [Float] {
        guard isCapturing else { return [] }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        vadFilter.reset()
        logger.info("Audio capture stopped")
        return ringBuffer.flush()
    }

    var currentDuration: TimeInterval {
        ringBuffer.currentDuration
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        let samples: [Float]

        if let converter = converter {
            guard let convertedBuffer = convertBuffer(buffer, using: converter) else { return }
            samples = Array(UnsafeBufferPointer(
                start: convertedBuffer.floatChannelData?[0],
                count: Int(convertedBuffer.frameLength)
            ))
        } else {
            guard let channelData = buffer.floatChannelData else { return }
            samples = Array(UnsafeBufferPointer(
                start: channelData[0],
                count: Int(buffer.frameLength)
            ))
        }

        // Update audio level (RMS)
        let rms = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let level = sqrt(rms / Float(max(samples.count, 1)))
        Task { @MainActor in
            self.audioLevel = level
        }

        ringBuffer.append(samples)
        vadFilter.process(samples: samples)
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, using converter: AVAudioConverter) -> AVAudioPCMBuffer? {
        let ratio = targetSampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: outputFrameCount
        ) else { return nil }

        var error: NSError?
        var consumed = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        if let error {
            logger.error("Conversion error: \(error.localizedDescription)")
            return nil
        }

        return outputBuffer
    }
}

enum AudioPipelineError: Error, LocalizedError {
    case invalidFormat
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidFormat: "Could not create target audio format"
        case .converterCreationFailed: "Could not create audio converter"
        }
    }
}
