import SwiftUI

struct AdvancedSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("LLM Processing") {
                Toggle("Enable AI text cleanup", isOn: $state.isLLMEnabled)
                Text("When disabled, raw ASR output is used directly.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Developer Mode") {
                Toggle("Developer mode", isOn: $state.isDeveloperMode)
                Text("Recognizes code variables from screen context and wraps them in backticks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Whisper Mode") {
                Toggle("Whisper mode (low voice)", isOn: $state.isWhisperMode)
                Text("Lowers the VAD threshold by ~12dB for quiet speech.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Context Awareness") {
                Toggle("Read active window text", isOn: $state.isContextAwarenessEnabled)
                Text("Improves transcription accuracy by reading visible text on screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
