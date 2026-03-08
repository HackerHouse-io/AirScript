import Foundation
import os

final class RingBuffer: @unchecked Sendable {
    private var buffer: [Float]
    private var writeIndex = 0
    private var count = 0
    private let capacity: Int
    private let lock = OSAllocatedUnfairLock()

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = [Float](repeating: 0, count: capacity)
    }

    convenience init(duration: TimeInterval, sampleRate: Double = Constants.Defaults.sampleRate) {
        self.init(capacity: Int(duration * sampleRate))
    }

    func append(_ samples: [Float]) {
        lock.lock()
        defer { lock.unlock() }

        for sample in samples {
            buffer[writeIndex] = sample
            writeIndex = (writeIndex + 1) % capacity
            if count < capacity {
                count += 1
            }
        }
    }

    func flush() -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        guard count > 0 else { return [] }

        var result = [Float](repeating: 0, count: count)
        if count < capacity {
            let start = 0
            for i in 0..<count {
                result[i] = buffer[(start + i) % capacity]
            }
        } else {
            for i in 0..<count {
                result[i] = buffer[(writeIndex + i) % capacity]
            }
        }

        count = 0
        writeIndex = 0
        return result
    }

    var currentDuration: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return Double(count) / Constants.Defaults.sampleRate
    }

    var sampleCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}
