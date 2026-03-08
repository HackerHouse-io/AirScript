import AVFoundation
import os

final class AudioRecorder {
    private let logger = Logger.audio

    func save(samples: [Float], sampleRate: Double = Constants.Defaults.sampleRate) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dayDir = URL.audioRecordings.appendingPathComponent(dateFormatter.string(from: Date()))
        try URL.ensureDirectoryExists(dayDir)

        let fileName = "recording-\(Int(Date().timeIntervalSince1970)).m4a"
        let fileURL = dayDir.appendingPathComponent(fileName)

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioRecorderError.invalidFormat
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            throw AudioRecorderError.bufferCreationFailed
        }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples.count {
            channelData[i] = samples[i]
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000,
        ]

        let file = try AVAudioFile(
            forWriting: fileURL,
            settings: outputSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        try file.write(from: buffer)

        logger.info("Audio saved: \(fileURL.lastPathComponent)")
        return fileURL
    }

    func cleanup(olderThan days: Int) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let baseDir = URL.audioRecordings

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseDir,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        for dir in contents {
            let attrs = try FileManager.default.attributesOfItem(atPath: dir.path)
            if let created = attrs[.creationDate] as? Date, created < cutoff {
                try FileManager.default.removeItem(at: dir)
                logger.info("Cleaned up old audio: \(dir.lastPathComponent)")
            }
        }
    }
}

enum AudioRecorderError: Error, LocalizedError {
    case invalidFormat
    case bufferCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidFormat: "Could not create audio format"
        case .bufferCreationFailed: "Could not create audio buffer"
        }
    }
}
