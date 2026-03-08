import SwiftUI

struct PrivacySettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("contextAwareness") private var contextAwareness = false
    @AppStorage("audioRetention") private var audioRetention = false
    @AppStorage("audioRetentionDays") private var audioRetentionDays = 7

    var body: some View {
        Form {
            Section("Context Awareness") {
                Toggle("Read active window text for better accuracy", isOn: $contextAwareness)
                Text("When enabled, AirScript reads text visible on screen to improve transcription accuracy. All data stays local.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Audio Retention") {
                Toggle("Save audio recordings", isOn: $audioRetention)
                if audioRetention {
                    Stepper("Keep for \(audioRetentionDays) days", value: $audioRetentionDays, in: 1...365)
                }
            }

            Section("Data") {
                Button("Export All Data...") {
                    // TODO: Export SwiftData to JSON
                }
                Button("Delete All Data...", role: .destructive) {
                    // TODO: Clear SwiftData + audio files
                }
            }

            Section("Permissions") {
                permissionRow("Microphone", granted: appState.hasMicrophonePermission) {
                    PermissionChecker.openMicrophoneSettings()
                }
                permissionRow("Accessibility", granted: appState.hasAccessibilityPermission) {
                    PermissionChecker.openAccessibilitySettings()
                }
                permissionRow("Input Monitoring", granted: appState.hasInputMonitoringPermission) {
                    PermissionChecker.openInputMonitoringSettings()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func permissionRow(_ name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(granted ? .green : .red)
            Text(name)
            Spacer()
            if !granted {
                Button("Grant") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}
