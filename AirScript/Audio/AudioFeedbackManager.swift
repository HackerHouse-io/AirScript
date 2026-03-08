import AppKit
import AVFoundation
import os

final class AudioFeedbackManager {
    private var pingPlayer: NSSound?
    private var clickPlayer: NSSound?
    private let logger = Logger.audio

    var isEnabled = true

    func setup() {
        pingPlayer = NSSound(named: "Ping")
        clickPlayer = NSSound(named: "Pop")
    }

    func playRecordStart() {
        guard isEnabled else { return }
        pingPlayer?.play()
    }

    func playRecordStop() {
        guard isEnabled else { return }
        clickPlayer?.play()
    }

    func playError() {
        NSSound.beep()
    }

    func muteSystemAudio() {
        // Mute system audio during dictation via AppleScript
        let script = NSAppleScript(source: "set volume with output muted")
        script?.executeAndReturnError(nil)
    }

    func unmuteSystemAudio() {
        let script = NSAppleScript(source: "set volume without output muted")
        script?.executeAndReturnError(nil)
    }

    func pauseMediaPlayback() {
        // Simulate media pause key for AirPods
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((Int32(NX_KEYTYPE_PLAY) << 16) | (0xA << 8)),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cgSessionEventTap)

        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((Int32(NX_KEYTYPE_PLAY) << 16) | (0xB << 8)),
            data2: -1
        )
        keyUp?.cgEvent?.post(tap: .cgSessionEventTap)
    }
}
