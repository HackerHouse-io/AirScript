import Foundation
import Observation
import SwiftData
import os

enum RecordingMode: String {
    case idle
    case pushToTalk
    case handsFree
    case command
}

@MainActor
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
    var selectedWhisperModel: String = UserDefaults.standard.string(forKey: "selectedWhisperModel")
        ?? Constants.Defaults.whisperModel {
        didSet { UserDefaults.standard.set(selectedWhisperModel, forKey: "selectedWhisperModel") }
    }
    var selectedLLMModel: String = UserDefaults.standard.string(forKey: "selectedLLMModel")
        ?? Constants.Defaults.llmModel {
        didSet { UserDefaults.standard.set(selectedLLMModel, forKey: "selectedLLMModel") }
    }
    var isLLMEnabled = true
    var isWhisperModelLoaded = false
    var isLLMModelLoaded = false
    var isWhisperModelDownloading = false
    var modelDownloadProgress: Double = 0
    var isLLMModelDownloading = false
    var llmModelDownloadProgress: Double = 0

    // MARK: - Feature Toggles
    var isContextAwarenessEnabled = false
    var isWhisperMode = false
    var isDeveloperMode = false
    var isAudioSavingEnabled = false

    // MARK: - Error
    var lastError: String?

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
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
    let formattingEngine = FormattingEngine()
    let dictionaryManager = DictionaryManager()
    let styleManager = StyleManager()
    let snippetManager = SnippetManager()
    let commandRouter = CommandRouter()
    let contextReader = ContextReader()
    let developerModeManager = DeveloperModeManager()
    let audioRecorder = AudioRecorder()
    let transcriptStore = TranscriptStore()
    let audioFeedbackManager = AudioFeedbackManager()
    let backtrackingEngine = BacktrackingEngine()
    let autoLearnManager = AutoLearnManager()
    let commandModeEngine: CommandModeEngine

    var modelContainer: ModelContainer?

    private var durationTimer: Timer?
    private var pendingCorrectionOriginal: String?
    private var didMuteAudio = false
    private var whisperSwitchTask: Task<Void, Never>?
    private var llmSwitchTask: Task<Void, Never>?
    private let logger = Logger.general

    init() {
        self.commandModeEngine = CommandModeEngine(llmProcessor: llmProcessor)
        setupHotkeyCallbacks()
        flowBar.setup()
        audioFeedbackManager.setup()
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

            audioFeedbackManager.playRecordStart()

            if UserDefaults.standard.bool(forKey: "muteDuringDictation") {
                audioFeedbackManager.lowerSystemVolume()
                audioFeedbackManager.pauseMediaPlayback()
                didMuteAudio = true
            }

            flowBar.state = flowBarState(for: mode)
            flowBar.show()

            startDurationTimer()

            logger.info("Dictation started: \(mode.rawValue)")
        } catch {
            lastError = error.localizedDescription
            audioFeedbackManager.playError()
            logger.error("Failed to start dictation: \(error.localizedDescription)")
        }
    }

    func stopDictation() {
        guard isRecording else { return }
        let samples = audioPipeline.stopCapture()
        isRecording = false
        isProcessing = true
        let wasCommand = recordingMode == .command
        let duration = recordingDuration
        recordingMode = .idle
        stopDurationTimer()

        audioFeedbackManager.playRecordStop()

        if didMuteAudio {
            audioFeedbackManager.restoreSystemVolume()
            audioFeedbackManager.resumeMediaPlayback()
            didMuteAudio = false
        }

        flowBar.state = .processing

        logger.info("Dictation stopped, processing \(samples.count) samples")

        Task.detached { [weak self] in
            guard let self else { return }
            await self.processAndInject(samples: samples, isCommand: wasCommand, duration: duration)
        }
    }

    func cancelDictation() {
        if isRecording {
            let _ = audioPipeline.stopCapture()
            isRecording = false
            recordingMode = .idle
            stopDurationTimer()

            if didMuteAudio {
                audioFeedbackManager.restoreSystemVolume()
                audioFeedbackManager.resumeMediaPlayback()
                didMuteAudio = false
            }

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

    func switchWhisperModel(to modelName: String) {
        guard modelName != selectedWhisperModel else { return }
        whisperSwitchTask?.cancel()
        selectedWhisperModel = modelName
        transcriptionEngine.unloadModel()
        isWhisperModelLoaded = false
        whisperSwitchTask = Task {
            do {
                try await transcriptionEngine.loadModel(named: modelName)
                guard !Task.isCancelled else { return }
                isWhisperModelLoaded = true
                logger.info("Switched Whisper model to: \(modelName)")
            } catch is CancellationError {
                // Superseded by a newer switch
            } catch {
                lastError = "Failed to load Whisper model: \(error.localizedDescription)"
                logger.error("Whisper model switch failed: \(error.localizedDescription)")
            }
        }
    }

    func switchLLMModel(to modelName: String) {
        guard modelName != selectedLLMModel else { return }
        llmSwitchTask?.cancel()
        selectedLLMModel = modelName
        llmProcessor.unloadModel()
        isLLMModelLoaded = false
        llmSwitchTask = Task {
            do {
                try await llmProcessor.loadModel(named: modelName)
                guard !Task.isCancelled else { return }
                isLLMModelLoaded = true
                logger.info("Switched LLM model to: \(modelName)")
            } catch is CancellationError {
                // Superseded by a newer switch
            } catch {
                lastError = "Failed to load LLM model: \(error.localizedDescription)"
                logger.error("LLM model switch failed: \(error.localizedDescription)")
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
        let success = hotkeyManager.start()
        if !success {
            lastError = "Failed to start hotkey listener. Grant Input Monitoring permission in System Settings → Privacy & Security."
            logger.error("Event tap creation failed — Input Monitoring permission likely missing")
        }
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

        hotkeyManager.onCommandModeEnd = { [weak self] in
            Task { @MainActor in
                self?.stopDictation()
            }
        }
    }

    private func processAndInject(samples: [Float], isCommand: Bool, duration: TimeInterval = 0) async {
        var skipDeferCleanup = false
        defer {
            if !skipDeferCleanup {
                isProcessing = false
                flowBar.hide()
            }
        }

        do {
            // Step 0: Read screen context via AX APIs
            var appContext: AppContext?
            if isContextAwarenessEnabled {
                appContext = contextReader.readActiveContext()
            }

            // Step 1: Fetch SwiftData records
            var dictionaryEntries: [DictionaryEntry] = []
            var snippets: [Snippet] = []
            var appStyles: [AppStyle] = []
            var customCommands: [CustomVoiceCommand] = []
            var customAliases: [CustomAppAlias] = []
            var ctx: ModelContext?

            if let container = modelContainer {
                let modelContext = ModelContext(container)
                ctx = modelContext
                dictionaryEntries = (try? modelContext.fetch(FetchDescriptor<DictionaryEntry>())) ?? []
                snippets = (try? modelContext.fetch(FetchDescriptor<Snippet>())) ?? []
                appStyles = (try? modelContext.fetch(FetchDescriptor<AppStyle>())) ?? []
                customCommands = (try? modelContext.fetch(FetchDescriptor<CustomVoiceCommand>())) ?? []
                customAliases = (try? modelContext.fetch(FetchDescriptor<CustomAppAlias>())) ?? []
            }

            // Step 2: WhisperKit transcription
            let result = try await transcriptionEngine.transcribe(audioSamples: samples)
            rawTranscript = result.text
            let rawText = result.text

            guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.info("Empty transcription, skipping pipeline")
                return
            }

            // Step 2.5: "Correct that" detection
            if backtrackingEngine.isCorrectThatTrigger(rawText) {
                guard backtrackingEngine.lastInjected != nil else {
                    logger.info("Correct-that triggered but no previous injection")
                    return
                }
                pendingCorrectionOriginal = backtrackingEngine.lastInjected
                backtrackingEngine.selectLastInjected()

                do {
                    try await Task.sleep(nanoseconds: 150_000_000) // 150ms for selection to register
                } catch {
                    return // Task was cancelled
                }

                flowBar.partialTranscript = "Say it again..."
                flowBar.state = .recordingPTT
                flowBar.show()

                // Prevent defer from hiding the flow bar and resetting isProcessing
                skipDeferCleanup = true
                isProcessing = false
                startDictation(mode: .pushToTalk)
                return
            }

            // Step 3: Snippet check — if trigger matches, execute and return early
            if let matchedSnippet = snippetManager.findMatch(for: rawText, in: snippets) {
                await snippetManager.execute(snippet: matchedSnippet)
                matchedSnippet.usageCount += 1
                saveTranscript(text: matchedSnippet.value, rawText: rawText, duration: duration,
                               appContext: appContext, wasCommand: false, commandAction: nil,
                               audioFileURL: nil, modelContext: ctx)
                try? ctx?.save()
                logger.info("Snippet executed: \(matchedSnippet.trigger)")
                return
            }

            // Step 4: Smart intent classification — handles both command and dictation modes
            let commandRouted = await commandRouter.route(
                text: rawText, isCommandMode: isCommand,
                customCommands: customCommands, customAliases: customAliases
            )
            if commandRouted {
                saveTranscript(text: rawText, rawText: rawText, duration: duration,
                               appContext: appContext, wasCommand: true, commandAction: rawText,
                               audioFileURL: nil, modelContext: ctx)
                updateStats(wordCount: 0, duration: duration, wasCommand: true, modelContext: ctx)
                try? ctx?.save()
                audioFeedbackManager.playCommandExecuted()
                logger.info("Command executed: \(String(rawText.prefix(50)))")
                return
            }

            // Step 4.5: In command mode, fall back to LLM-based command interpretation
            if isCommand {
                if let commandResult = try? await commandModeEngine.execute(command: rawText) {
                    currentTranscript = commandResult
                    saveTranscript(text: commandResult, rawText: rawText, duration: duration,
                                   appContext: appContext, wasCommand: true, commandAction: rawText,
                                   audioFileURL: nil, modelContext: ctx)
                    updateStats(wordCount: 0, duration: duration, wasCommand: true, modelContext: ctx)
                    try? ctx?.save()
                    audioFeedbackManager.playCommandExecuted()
                    logger.info("Command mode LLM result: \(String(commandResult.prefix(50)))")
                    return
                }
                // Both router and LLM fallback failed in command mode
                audioFeedbackManager.playError()
                logger.info("Command mode: no handler matched: \(String(rawText.prefix(50)))")
                return
            }

            var finalText = rawText

            // Step 5: LLM cleanup with full context
            if isLLMEnabled && llmProcessor.isModelLoaded {
                var processingContext = ProcessingContext()
                processingContext.appBundleID = appContext?.bundleID
                processingContext.visibleText = appContext?.visibleText
                processingContext.styleInstruction = styleManager.styleInstruction(
                    for: appContext?.bundleID, styles: appStyles)
                if let lastInjected = backtrackingEngine.lastInjected {
                    processingContext.isBacktrackingEnabled = true
                    processingContext.previousTranscript = lastInjected
                }
                finalText = try await llmProcessor.process(rawText: rawText, context: processingContext)
            }

            // Step 6: Formatting — punctuation dictation, line breaks, list detection
            finalText = formattingEngine.format(finalText)

            // Step 7: Dictionary replacements
            if !dictionaryEntries.isEmpty {
                finalText = dictionaryManager.applyReplacements(to: finalText, using: dictionaryEntries)
            }

            // Step 8: Developer mode — variable recognition + backtick wrapping
            if isDeveloperMode && IDEDetector.isInIDE {
                let visibleCode = appContext?.visibleText ?? ""
                finalText = developerModeManager.recognizeVariables(in: finalText, visibleCode: visibleCode)
            }

            // Step 9: Smart insertion — cursor context adjustment
            let cursorContext = smartInsertion.getCursorContext()
            finalText = smartInsertion.adjustText(finalText, for: cursorContext)

            // Step 10: Inject text via ⌘V
            currentTranscript = finalText
            await TextInjector.inject(text: finalText)
            audioFeedbackManager.playTranscriptionComplete()
            logger.info("Text injected: \"\(String(finalText.prefix(50)))...\"")

            // Step 10.5: Log correction if this was a "correct that" replacement
            if let original = pendingCorrectionOriginal, let modelContext = ctx {
                autoLearnManager.logCorrection(
                    original: original,
                    corrected: finalText,
                    appBundleID: appContext?.bundleID,
                    in: modelContext
                )
                pendingCorrectionOriginal = nil
            }

            // Step 11: Store for backtracking ("correct that")
            backtrackingEngine.setLastInjected(finalText)

            // Step 12: Save audio recording if enabled
            var audioFileURL: URL?
            if isAudioSavingEnabled {
                audioFileURL = try? audioRecorder.save(samples: samples)
            }

            // Step 13: Save transcript to SwiftData
            saveTranscript(text: finalText, rawText: rawText, duration: duration,
                           appContext: appContext, wasCommand: false, commandAction: nil,
                           audioFileURL: audioFileURL, modelContext: ctx)

            // Step 14: Update productivity stats
            let wordCount = finalText.split(separator: " ").count
            updateStats(wordCount: wordCount, duration: duration, wasCommand: false, modelContext: ctx)

            try? ctx?.save()

        } catch {
            lastError = error.localizedDescription
            flowBar.state = .error
            audioFeedbackManager.playError()
            logger.error("Processing failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Pipeline Helpers

    private func saveTranscript(text: String, rawText: String, duration: TimeInterval,
                                appContext: AppContext?, wasCommand: Bool, commandAction: String?,
                                audioFileURL: URL?, modelContext: ModelContext?) {
        guard let ctx = modelContext else { return }
        transcriptStore.save(
            text: text,
            rawText: rawText,
            duration: duration,
            model: selectedWhisperModel,
            llmModel: isLLMEnabled ? selectedLLMModel : nil,
            appBundleID: appContext?.bundleID,
            appName: appContext?.appName,
            wasCommand: wasCommand,
            commandAction: commandAction,
            in: ctx
        )
    }

    private func updateStats(wordCount: Int, duration: TimeInterval, wasCommand: Bool, modelContext: ModelContext?) {
        guard let ctx = modelContext else { return }
        let today = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<ProductivityStat> { $0.date == today }
        let descriptor = FetchDescriptor<ProductivityStat>(predicate: predicate)
        let stat: ProductivityStat
        if let existing = (try? ctx.fetch(descriptor))?.first {
            stat = existing
        } else {
            stat = ProductivityStat(date: .now)
            ctx.insert(stat)
        }
        stat.sessionsCount += 1
        stat.wordsTranscribed += wordCount
        stat.totalDurationSeconds += duration
        if wasCommand {
            stat.commandsExecuted += 1
        }
    }
}
