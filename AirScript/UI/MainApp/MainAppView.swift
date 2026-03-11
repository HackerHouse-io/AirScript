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
        case .home: "house"
        case .history: "clock.arrow.circlepath"
        case .commands: "command"
        case .dictionary: "textformat.abc"
        case .snippets: "text.insert"
        case .style: "paintbrush"
        case .scratchpad: "note.text"
        }
    }

    var title: String { rawValue }
}

struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var selectedItem: SidebarItem? = .home
    @State private var showingSettings = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, id: \.self, selection: $selectedItem) { item in
                Label(item.title, systemImage: item.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if appState.isRecording {
                        HStack(spacing: 6) {
                            Circle().fill(.red).frame(width: 6, height: 6)
                            Text("Recording").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                    HStack {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("v\(appVersion)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tint(AirScriptTheme.accent)
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
        .onChange(of: selectedItem) { _, newValue in
            if newValue == nil { selectedItem = .home }
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

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .home, nil:
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
