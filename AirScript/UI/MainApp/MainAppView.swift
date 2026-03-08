import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case style = "Style"
    case scratchpad = "Scratchpad"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .dictionary: "textformat.abc"
        case .snippets: "text.insert"
        case .style: "paintbrush.fill"
        case .scratchpad: "note.text"
        }
    }
}

struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedItem: SidebarItem = .home
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 820, minHeight: 560)
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
                .environment(appState)
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
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .font(.body)
                    .padding(.vertical, 2)
            }
            .listStyle(.sidebar)

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
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .home:
            HomePage()
                .environment(appState)
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
