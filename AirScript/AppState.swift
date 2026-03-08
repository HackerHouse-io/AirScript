import Foundation
import Observation
import os

enum RecordingMode: String {
    case idle
    case pushToTalk
    case handsFree
    case command
}

@Observable
final class AppState {
    // MARK: - Recording State
    var isRecording = false
    var isProcessing = false
    var recordingMode: RecordingMode = .idle
    var currentTranscript = ""
    var rawTranscript = ""
    var audioLevel: Float = 0
    var recordingDuration: TimeInterval = 0

    // MARK: - Model State
    var selectedWhisperModel = Constants.Defaults.whisperModel
    var selectedLLMModel = Constants.Defaults.llmModel
    var isLLMEnabled = true
    var isWhisperModelLoaded = false
    var isLLMModelLoaded = false
    var modelDownloadProgress: Double = 0

    // MARK: - Feature Toggles
    var isContextAwarenessEnabled = false
    var isWhisperMode = false
    var isDeveloperMode = false

    // MARK: - Error
    var lastError: String?

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Permissions
    var hasMicrophonePermission = false
    var hasAccessibilityPermission = false
    var hasInputMonitoringPermission = false

    private let logger = Logger.general

    init() {
        logger.info("AppState initialized")
    }
}
