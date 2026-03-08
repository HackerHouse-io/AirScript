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

    // MARK: - Pipeline Components
    let audioPipeline = AudioPipeline()
    let transcriptionEngine = TranscriptionEngine()
    let llmProcessor = LLMProcessor()
    let hotkeyManager = HotkeyManager()
    let smartInsertion = SmartInsertionManager()
    let flowBar = FlowBarController()

    private var durationTimer: Timer?
    private let logger = Logger.general

    init() {
        setupHotkeyCallbacks()
        // Defer FlowBar setup to after app is ready
        DispatchQueue.main.async { [self] in
            flowBar.setup()
        }
        logger.info("AppState initialized")
    }

    // MARK: - Dictation Orchestration

    func startDictation(mode: RecordingMode = .pushToTalk) {
        guard !isRecording else { return }
        do {
            try audioPipeline.startCapture()
            isRecording = true
            recordingMode = mode
            recordingDuration = 0
            lastError = nil

            // Show Flow Bar
            flowBar.state = flowBarState(for: mode)
            flowBar.show()

            // Start duration timer
            startDurationTimer()

            logger.info("Dictation started: \(mode.rawValue)")
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to start dictation: \(error.localizedDescription)")
        }
    }

    func stopDictation() {
        guard isRecording else { return }
        let samples = audioPipeline.stopCapture()
        isRecording = false
        isProcessing = true
        let wasCommand = recordingMode == .command
        recordingMode = .idle
        stopDurationTimer()

        // Update Flow Bar
        flowBar.state = .processing

        logger.info("Dictation stopped, processing \(samples.count) samples")

        Task.detached { [weak self] in
            guard let self else { return }
            await self.processAndInject(samples: samples, isCommand: wasCommand)
        }
    }

    func cancelDictation() {
        if isRecording {
            let _ = audioPipeline.stopCapture()
            isRecording = false
            recordingMode = .idle
            stopDurationTimer()
            flowBar.hide()
            logger.info("Dictation cancelled")
        }
    }

    private func flowBarState(for mode: RecordingMode) -> FlowBarState {
        switch mode {
        case .pushToTalk: .recordingPTT
        case .handsFree: .recordingHandsFree
        case .command: .command
        case .idle: .idle
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordingDuration += 0.1
            self.flowBar.duration = self.recordingDuration
            self.flowBar.audioLevel = self.audioPipeline.audioLevel

            // Hands-free time limits
            if self.recordingMode == .handsFree {
                if self.recordingDuration >= Constants.Defaults.maxHandsFreeDuration {
                    Task { @MainActor in self.stopDictation() }
                } else if self.recordingDuration >= Constants.Defaults.handsFreeWarningDuration {
                    self.flowBar.partialTranscript = "Auto-stop in \(Int(Constants.Defaults.maxHandsFreeDuration - self.recordingDuration))s"
                }
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - Model Loading

    func loadModels() async {
        do {
            try await transcriptionEngine.loadModel(named: selectedWhisperModel)
            isWhisperModelLoaded = true
            logger.info("Whisper model loaded")
        } catch {
            lastError = "Failed to load Whisper model: \(error.localizedDescription)"
            logger.error("Whisper model load failed: \(error.localizedDescription)")
        }

        if isLLMEnabled {
            do {
                try await llmProcessor.loadModel(named: selectedLLMModel)
                isLLMModelLoaded = true
                logger.info("LLM model loaded")
            } catch {
                lastError = "Failed to load LLM model: \(error.localizedDescription)"
                logger.error("LLM model load failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Permission Checks

    func checkPermissions() async {
        hasMicrophonePermission = await PermissionChecker.checkMicrophonePermission()
        hasAccessibilityPermission = PermissionChecker.isAccessibilityGranted
        hasInputMonitoringPermission = PermissionChecker.isInputMonitoringGranted
    }

    func startHotkeyListening() {
        hotkeyManager.start()
    }

    // MARK: - Private

    private func setupHotkeyCallbacks() {
        hotkeyManager.onPushToTalkStart = { [weak self] in
            Task { @MainActor in
                self?.startDictation(mode: .pushToTalk)
            }
        }

        hotkeyManager.onPushToTalkEnd = { [weak self] in
            Task { @MainActor in
                self?.stopDictation()
            }
        }

        hotkeyManager.onHandsFreeToggle = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.isRecording {
                    self.stopDictation()
                } else {
                    self.startDictation(mode: .handsFree)
                }
            }
        }

        hotkeyManager.onCancel = { [weak self] in
            Task { @MainActor in
                self?.cancelDictation()
            }
        }

        hotkeyManager.onCommandModeStart = { [weak self] in
            Task { @MainActor in
                self?.startDictation(mode: .command)
            }
        }
    }

    @MainActor
    private func processAndInject(samples: [Float], isCommand: Bool) async {
        defer {
            isProcessing = false
            flowBar.hide()
        }

        do {
            let result = try await transcriptionEngine.transcribe(audioSamples: samples)
            rawTranscript = result.text

            var finalText = result.text

            if isLLMEnabled && llmProcessor.isModelLoaded {
                finalText = try await llmProcessor.process(rawText: result.text)
            }

            let context = smartInsertion.getCursorContext()
            finalText = smartInsertion.adjustText(finalText, for: context)

            currentTranscript = finalText

            await TextInjector.inject(text: finalText)
            logger.info("Text injected: \"\(finalText.prefix(50))...\"")

        } catch {
            lastError = error.localizedDescription
            flowBar.state = .error
            logger.error("Processing failed: \(error.localizedDescription)")
        }
    }
}
