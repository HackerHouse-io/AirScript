import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showingRecordingTest = false
    @State private var showingModelManager = false
    @State private var showingHistory = false
    @State private var showingNotes = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 12) {
            header
            Divider()
            statusSection
            Divider()
            navigationButtons
            Divider()
            quitButton
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showingRecordingTest) {
            RecordingTestView()
                .environment(appState)
        }
        .sheet(isPresented: $showingModelManager) {
            ModelManagerView()
                .environment(appState)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingNotes) {
            NotesView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(appState)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("AirScript")
                .font(.headline)
            Spacer()
            Text("v1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusRow(
                icon: "mic.fill",
                label: "Microphone",
                status: appState.hasMicrophonePermission
            )
            statusRow(
                icon: "hand.raised.fill",
                label: "Accessibility",
                status: appState.hasAccessibilityPermission
            )
            statusRow(
                icon: "keyboard",
                label: "Input Monitoring",
                status: appState.hasInputMonitoringPermission
            )

            if appState.isRecording {
                HStack {
                    Image(systemName: "record.circle")
                        .foregroundStyle(.red)
                    Text("Recording...")
                        .font(.subheadline)
                }
            }
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 4) {
            menuButton("Recording Test", icon: "waveform.circle") {
                showingRecordingTest = true
            }
            menuButton("Model Manager", icon: "arrow.down.circle") {
                showingModelManager = true
            }
            menuButton("History", icon: "clock") {
                showingHistory = true
            }
            menuButton("Notes", icon: "note.text") {
                showingNotes = true
            }
            menuButton("Settings", icon: "gear") {
                showingSettings = true
            }
        }
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.borderless)
    }

    private func statusRow(icon: String, label: String, status: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(status ? .green : .secondary)
            Text(label)
                .font(.subheadline)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(status ? .green : .red)
                .font(.caption)
        }
    }

    private var quitButton: some View {
        Button("Quit AirScript") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
