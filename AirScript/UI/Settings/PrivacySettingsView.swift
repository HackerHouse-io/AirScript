import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PrivacySettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @AppStorage("contextAwareness") private var contextAwareness = false
    @AppStorage("audioRetention") private var audioRetention = false
    @AppStorage("audioRetentionDays") private var audioRetentionDays = 7
    @State private var showDeleteConfirmation = false
    @State private var showExportError = false
    @State private var exportError = ""

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
                    exportData()
                }
                Button("Delete All Data...", role: .destructive) {
                    showDeleteConfirmation = true
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
        .confirmationDialog("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all transcripts, dictionary entries, snippets, notes, styles, statistics, audio files, and preferences. This cannot be undone.")
        }
        .alert("Export Error", isPresented: $showExportError) {
            Button("OK") {}
        } message: {
            Text(exportError)
        }
    }

    // MARK: - Actions

    private func exportData() {
        do {
            let data = try DataExporter.exportAll(context: modelContext)

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            let dateString = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withFullDate])
            panel.nameFieldStringValue = "AirScript-Export-\(dateString).json"
            panel.title = "Export AirScript Data"

            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    private func deleteAllData() {
        do {
            try DataExporter.deleteAll(context: modelContext)
            DataExporter.deleteAudioFiles()
            DataExporter.clearUserDefaults()
            appState.hasCompletedOnboarding = false
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    // MARK: - Subviews

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
