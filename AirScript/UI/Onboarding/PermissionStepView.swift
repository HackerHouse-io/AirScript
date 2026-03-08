import SwiftUI

struct PermissionStepView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            Text("Grant Permissions")
                .font(.title2)
            Text("AirScript needs these permissions to work properly.")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                permissionCard(
                    icon: "mic.fill",
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
                    icon: "hand.raised.fill",
                    title: "Accessibility",
                    description: "Read text context and inject dictated text",
                    granted: appState.hasAccessibilityPermission,
                    action: {
                        PermissionChecker.requestAccessibilityIfNeeded()
                    }
                )

                permissionCard(
                    icon: "keyboard",
                    title: "Input Monitoring",
                    description: "Listen for the fn key hotkey",
                    granted: appState.hasInputMonitoringPermission,
                    action: {
                        PermissionChecker.requestInputMonitoringIfNeeded()
                    }
                )
            }
        }
        .padding()
        .task {
            await appState.checkPermissions()
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
                .foregroundStyle(granted ? .green : .blue)

            VStack(alignment: .leading) {
                Text(title).font(.subheadline.weight(.medium))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
