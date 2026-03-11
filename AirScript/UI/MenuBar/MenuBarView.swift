import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            header
            Divider()
            statusSection
            Divider()
            actionButtons
            Divider()
            quitButton
        }
        .padding()
        .frame(width: 260)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundStyle(AirScriptTheme.accent)
            Text("AirScript")
                .font(AirScriptTheme.fontSectionTitle)
            Spacer()
            Text("v1.0")
                .font(AirScriptTheme.fontCaption2)
                .foregroundStyle(AirScriptTheme.textTertiary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if appState.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Recording (\(appState.recordingMode.rawValue))")
                        .font(AirScriptTheme.fontBodyMedium)
                }
            } else if appState.isProcessing {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Processing...")
                        .font(AirScriptTheme.fontBodyMedium)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AirScriptTheme.statusSuccess)
                        .frame(width: 8, height: 8)
                    Text("Ready")
                        .font(AirScriptTheme.fontBodyMedium)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                permissionDot("Mic", ok: appState.hasMicrophonePermission)
                permissionDot("AX", ok: appState.hasAccessibilityPermission)
                permissionDot("Input", ok: appState.hasInputMonitoringPermission)
            }
            .font(.caption2)
        }
    }

    private func permissionDot(_ label: String, ok: Bool) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(ok ? AirScriptTheme.statusSuccess : AirScriptTheme.statusError)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 4) {
            Button {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: {
                    $0.title.contains("AirScript") &&
                    !$0.title.contains("Setup") &&
                    $0.className != "NSStatusBarWindow"
                }) {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Label("Open AirScript", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label("Settings...", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
    }

    private var quitButton: some View {
        Button("Quit AirScript") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
