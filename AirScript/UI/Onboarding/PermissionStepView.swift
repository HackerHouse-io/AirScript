import SwiftUI

struct PermissionStepView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            Text("Grant Permissions")
                .font(AirScriptTheme.fontSectionTitle)
            Text("AirScript needs these permissions to work properly.")
                .foregroundStyle(AirScriptTheme.textSecondary)

            VStack(spacing: 12) {
                permissionCard(
                    icon: "mic",
                    title: "Microphone",
                    description: "Record your voice for dictation",
                    granted: appState.hasMicrophonePermission,
                    action: {
                        Task {
                            appState.hasMicrophonePermission = await PermissionChecker.checkMicrophonePermission()
                        }
                    }
                )

                permissionCard(
                    icon: "hand.raised",
                    title: "Accessibility",
                    description: "Read screen context and inject text",
                    granted: appState.hasAccessibilityPermission,
                    action: {
                        PermissionChecker.requestAccessibilityIfNeeded()
                    }
                )

                permissionCard(
                    icon: "keyboard",
                    title: "Input Monitoring",
                    description: "Listen for the fn key to start dictation",
                    granted: appState.hasInputMonitoringPermission,
                    action: {
                        PermissionChecker.requestInputMonitoringIfNeeded()
                        PermissionChecker.openInputMonitoringSettings()
                    }
                )
            }
        }
        .padding()
        .task {
            await appState.checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await appState.checkPermissions()
            }
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)
                .foregroundStyle(granted ? AirScriptTheme.statusSuccess : AirScriptTheme.accent)

            VStack(alignment: .leading) {
                Text(title).font(AirScriptTheme.fontBodyMedium)
                Text(description).font(AirScriptTheme.fontCaption).foregroundStyle(AirScriptTheme.textSecondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AirScriptTheme.statusSuccess)
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.md))
    }
}
