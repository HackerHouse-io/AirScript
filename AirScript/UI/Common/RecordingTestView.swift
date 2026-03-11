import SwiftUI

struct RecordingTestView: View {
    @Environment(AppState.self) private var appState
    @State private var audioPipeline = AudioPipeline()
    @State private var transcriptionEngine = TranscriptionEngine()
    @State private var llmProcessor = LLMProcessor()
    @State private var isRecording = false
    @State private var rawText = ""
    @State private var processedText = ""
    @State private var processingTime: TimeInterval = 0
    @State private var error: String?
    @State private var isProcessing = false
    @State private var enableLLM = true

    var body: some View {
        VStack(spacing: 16) {
            Text("Recording Test")
                .font(AirScriptTheme.fontSectionTitle)

            audioLevelMeter

            HStack {
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title2)
                        Text(isRecording ? "Stop" : "Record")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : AirScriptTheme.accent)
                .disabled(isProcessing)

                Toggle("AI Cleanup", isOn: $enableLLM)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if isProcessing {
                ProgressView("Transcribing...")
            }

            if !rawText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    resultSection(title: "Raw ASR", text: rawText)

                    if enableLLM && !processedText.isEmpty {
                        resultSection(title: "AI Cleaned", text: processedText)
                    }

                    HStack {
                        Spacer()
                        Text(String(format: "%.2fs", processingTime))
                            .font(AirScriptTheme.fontMono)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                    }
                }
            }

            if let error {
                Text(error)
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.statusError)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 350)
        .task {
            await loadModels()
        }
    }

    private func resultSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AirScriptTheme.fontBodyMedium)
            Text(text)
                .font(AirScriptTheme.fontBodyPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm))
        }
    }

    private var audioLevelMeter: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(levelColor)
                    .frame(width: max(0, geo.size.width * CGFloat(audioPipeline.audioLevel * 10)))
            }
        }
        .frame(height: 8)
    }

    private var levelColor: Color {
        let level = audioPipeline.audioLevel * 10
        if level > 0.8 { return AirScriptTheme.statusError }
        if level > 0.5 { return .yellow }
        return AirScriptTheme.statusSuccess
    }

    private func toggleRecording() {
        if isRecording {
            stopAndTranscribe()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try audioPipeline.startCapture()
            isRecording = true
            error = nil
            rawText = ""
            processedText = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func stopAndTranscribe() {
        let samples = audioPipeline.stopCapture()
        isRecording = false
        isProcessing = true

        Task {
            do {
                let result = try await transcriptionEngine.transcribe(audioSamples: samples)
                rawText = result.text
                processingTime = result.processingTime

                if enableLLM {
                    let cleaned = try await llmProcessor.process(rawText: result.text)
                    processedText = cleaned
                }
            } catch {
                self.error = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func loadModels() async {
        do {
            if !transcriptionEngine.isModelLoaded {
                try await transcriptionEngine.loadModel(named: appState.selectedWhisperModel)
            }
            if !llmProcessor.isModelLoaded {
                try await llmProcessor.loadModel(named: appState.selectedLLMModel)
            }
        } catch {
            self.error = "Failed to load model: \(error.localizedDescription)"
        }
    }
}
