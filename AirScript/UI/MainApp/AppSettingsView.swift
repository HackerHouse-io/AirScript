import SwiftUI

struct AppSettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .general

    enum SettingsSection: String, CaseIterable, Identifiable {
        case general = "General"
        case audio = "Audio"
        case models = "Models"
        case hotkeys = "Hotkeys"
        case privacy = "Privacy"
        case advanced = "Advanced"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: "gear"
            case .audio: "mic"
            case .models: "brain"
            case .hotkeys: "keyboard"
            case .privacy: "lock.shield"
            case .advanced: "wrench.and.screwdriver"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Settings sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.rawValue, systemImage: section.icon)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                selectedSection == section
                                    ? AirScriptTheme.accent.opacity(0.15)
                                    : Color.clear
                            )
                            .foregroundStyle(
                                selectedSection == section ? AirScriptTheme.accent : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                    .padding(16)
            }
            .frame(width: 180)

            Divider()

            // Settings content
            VStack {
                settingsContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 480)
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch selectedSection {
        case .general:
            GeneralSettingsView()
        case .audio:
            AudioSettingsView()
        case .models:
            ModelSettingsView()
                .environment(appState)
        case .hotkeys:
            HotkeySettingsView()
        case .privacy:
            PrivacySettingsView()
                .environment(appState)
        case .advanced:
            AdvancedSettingsView()
                .environment(appState)
        }
    }
}
