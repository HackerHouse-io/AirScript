import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 12) {
            header
            Divider()
            statusSection
            Divider()
            quitButton
        }
        .padding()
        .frame(width: 280)
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
