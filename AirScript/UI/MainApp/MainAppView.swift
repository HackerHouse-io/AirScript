import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case history = "History"
    case commands = "Commands"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case style = "Style"
    case scratchpad = "Scratchpad"

    var id: Self { self }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .history: "clock.arrow.circlepath"
        case .commands: "command"
        case .dictionary: "textformat.abc"
        case .snippets: "text.insert"
        case .style: "paintbrush.fill"
        case .scratchpad: "note.text"
        }
    }
}

struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var selectedItem: SidebarItem = .home
    @State private var showingSettings = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 560)
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
                .environment(appState)
        }
        .task {
            await appState.checkPermissions()
            if !appState.hasCompletedOnboarding {
                openWindow(id: "onboarding")
            } else {
                await appState.loadModels()
                appState.startHotkeyListening()
            }
        }
        .onChange(of: appState.hasCompletedOnboarding) { _, completed in
            if completed {
                Task {
                    await appState.loadModels()
                    appState.startHotkeyListening()
                }
            }
        }
        .onChange(of: appState.hasInputMonitoringPermission) { wasGranted, isGranted in
            if !wasGranted && isGranted && appState.hasCompletedOnboarding {
                appState.startHotkeyListening()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await appState.checkPermissions()
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                Text("AirScript")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Nav items
            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    sidebarButton(for: item)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            Divider()

            // Bottom bar
            VStack(spacing: 8) {
                // Recording status
                if appState.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text("Recording...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                }

                HStack {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text("v1.0")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
        .frame(width: 220)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func sidebarButton(for item: SidebarItem) -> some View {
        let isSelected = selectedItem == item
        return Button {
            selectedItem = item
        } label: {
            Label(item.rawValue, systemImage: item.icon)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .home:
            HomePage()
                .environment(appState)
        case .history:
            HistoryView()
        case .commands:
            CommandsPage()
        case .dictionary:
            DictionaryPage()
        case .snippets:
            SnippetsPage()
        case .style:
            StylePage()
        case .scratchpad:
            ScratchpadPage()
        }
    }
}
