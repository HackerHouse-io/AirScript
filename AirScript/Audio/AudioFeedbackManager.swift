import AppKit
import AVFoundation
import os

final class AudioFeedbackManager {
    private var pingPlayer: NSSound?
    private var clickPlayer: NSSound?
    private var donePlayer: NSSound?
    private var confirmPlayer: NSSound?
    private let logger = Logger.audio

    var isEnabled = true

    private var savedVolume: Int?
    private var mediaWasPaused = false

    func setup() {
        pingPlayer = NSSound(named: "Ping")
        clickPlayer = NSSound(named: "Pop")
        donePlayer = NSSound(named: "Glass")
        confirmPlayer = NSSound(named: "Tink")

        // Recover volume if app crashed during dictation with muted audio
        restoreVolumeIfNeeded()
    }

    func playRecordStart() {
        guard isEnabled else { return }
        pingPlayer?.play()
    }

    func playRecordStop() {
        guard isEnabled else { return }
        clickPlayer?.play()
    }

    func playTranscriptionComplete() {
        guard isEnabled else { return }
        donePlayer?.play()
    }

    func playCommandExecuted() {
        guard isEnabled else { return }
        confirmPlayer?.play()
    }

    func playError() {
        NSSound.beep()
    }

    // MARK: - System Volume

    /// Lowers system volume to ~10% and saves the original level.
    /// Runs AppleScript on a background queue to avoid blocking the UI.
    func lowerSystemVolume() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let getScript = NSAppleScript(source: "output volume of (get volume settings)")
            var error: NSDictionary?
            let result = getScript?.executeAndReturnError(&error)
            guard let volume = result?.int32Value else { return }

            let intVolume = Int(volume)
            self.savedVolume = intVolume
            // Persist so we can restore on crash recovery
            UserDefaults.standard.set(intVolume, forKey: "AirScript.savedSystemVolume")

            let lowVolume = Swift.max(Int(Double(volume) * 0.1), 1)
            let setScript = NSAppleScript(source: "set volume output volume \(lowVolume)")
            setScript?.executeAndReturnError(nil)
            self.logger.info("System volume lowered from \(volume) to \(lowVolume)")
        }
    }

    /// Restores system volume to the saved level.
    /// Note: If the user manually adjusts volume during dictation, this will override their change.
    func restoreSystemVolume() {
        guard let volume = savedVolume else { return }
        savedVolume = nil
        UserDefaults.standard.removeObject(forKey: "AirScript.savedSystemVolume")

        DispatchQueue.global(qos: .userInitiated).async {
            let script = NSAppleScript(source: "set volume output volume \(volume)")
            script?.executeAndReturnError(nil)
        }
        logger.info("System volume restored to \(volume)")
    }

    /// Restores volume on launch if the app previously crashed during muted dictation.
    private func restoreVolumeIfNeeded() {
        let saved = UserDefaults.standard.integer(forKey: "AirScript.savedSystemVolume")
        guard saved > 0 else { return }
        savedVolume = saved
        restoreSystemVolume()
        logger.info("Recovered system volume after unexpected shutdown")
    }

    // MARK: - Media Playback

    /// Sends a play/pause media key toggle.
    /// Note: This is toggle-based — if no media was playing when called, resumeMediaPlayback()
    /// will inadvertently start playback. Detecting actual playback state requires private APIs
    /// (MRMediaRemoteGetNowPlayingInfo) which we avoid for App Store compatibility.
    func pauseMediaPlayback() {
        sendMediaKey(keyDown: true)
        sendMediaKey(keyDown: false)
        mediaWasPaused = true
    }

    func resumeMediaPlayback() {
        guard mediaWasPaused else { return }
        sendMediaKey(keyDown: true)
        sendMediaKey(keyDown: false)
        mediaWasPaused = false
    }

    private func sendMediaKey(keyDown: Bool) {
        let flags: Int = keyDown ? 0xA : 0xB
        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((Int32(NX_KEYTYPE_PLAY) << 16) | Int32(flags << 8)),
            data2: -1
        )
        event?.cgEvent?.post(tap: .cgSessionEventTap)
    }
}
