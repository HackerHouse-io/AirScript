import SwiftUI
import SwiftData

struct CommandsPage: View {
    @Query(sort: \CustomAppAlias.createdAt, order: .reverse)
    private var customAliases: [CustomAppAlias]
    @Query(sort: \CustomVoiceCommand.createdAt, order: .reverse)
    private var customCommands: [CustomVoiceCommand]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddAlias = false
    @State private var showingAddCommand = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    PageHeader(title: "Commands", subtitle: "Control your Mac with your voice")

                    // Info card
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AirScriptTheme.accent)
                        Text("Say these phrases while recording to trigger actions. Built-in commands work out of the box.")
                            .font(AirScriptTheme.fontCaption)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AirScriptTheme.accent.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)

                    // Search
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search commands...")
                        Spacer()
                    }
                    .padding(.horizontal)

                    voiceCommandsSection
                    appAliasesSection
                    customCommandsSection
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddAlias) {
            AddAliasSheet()
        }
        .sheet(isPresented: $showingAddCommand) {
            AddCustomCommandSheet()
        }
    }

    // MARK: - Voice Commands Section

    private var voiceCommandsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Voice Commands", subtitle: "Say these while dictating")

            GlassCard(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    let filtered = filteredVoiceCommands
                    if filtered.isEmpty {
                        searchEmptyState("No matching voice commands")
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, category in
                            if index > 0 { Divider() }
                            voiceCommandCategoryView(category)
                                .staggeredAppear(index: index)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var filteredVoiceCommands: [VoiceCommandCategory] {
        if searchText.isEmpty { return Self.voiceCommandCategories }
        return Self.voiceCommandCategories.compactMap { category in
            let matchingRows = category.rows.filter { row in
                row.phrases.localizedCaseInsensitiveContains(searchText) ||
                row.action.localizedCaseInsensitiveContains(searchText) ||
                category.name.localizedCaseInsensitiveContains(searchText)
            }
            if matchingRows.isEmpty { return nil }
            return VoiceCommandCategory(name: category.name, icon: category.icon, rows: matchingRows)
        }
    }

    private func voiceCommandCategoryView(_ category: VoiceCommandCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(AirScriptTheme.accent)
                    .frame(width: 20)
                Text(category.name)
                    .font(AirScriptTheme.fontBodyMedium)
                StatusBadge(text: "Built-in", color: .secondary, style: .subtle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(category.rows.enumerated()), id: \.element.id) { _, row in
                Divider().padding(.leading, 44)
                HStack(spacing: 12) {
                    Spacer().frame(width: 20)
                    Text(row.phrases)
                        .font(AirScriptTheme.fontCaption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.action)
                        .font(AirScriptTheme.fontCaption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - App Aliases Section

    private var appAliasesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "App Aliases",
                subtitle: "Say 'open [alias]' to launch apps",
                trailing: {
                    Button {
                        showingAddAlias = true
                    } label: {
                        Label("Add Alias", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                }
            )

            GlassCard(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    let builtIn = filteredBuiltInAliases
                    let custom = filteredCustomAliases

                    if builtIn.isEmpty && custom.isEmpty {
                        searchEmptyState("No matching aliases")
                    } else {
                        ForEach(Array(custom.enumerated()), id: \.element.id) { index, alias in
                            if index > 0 { Divider() }
                            HoverRow {
                                aliasRowContent(spoken: alias.spokenName, app: alias.appName, isBuiltIn: false) {
                                    modelContext.delete(alias)
                                }
                            }
                            .staggeredAppear(index: index)
                        }

                        ForEach(Array(builtIn.enumerated()), id: \.element.app) { index, pair in
                            Divider()
                            HoverRow {
                                aliasRowContent(spoken: pair.spoken, app: pair.app, isBuiltIn: true, onDelete: nil)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var filteredBuiltInAliases: [(spoken: String, app: String)] {
        if searchText.isEmpty { return Self.builtInAliases }
        return Self.builtInAliases.filter {
            $0.spoken.localizedCaseInsensitiveContains(searchText) ||
            $0.app.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredCustomAliases: [CustomAppAlias] {
        if searchText.isEmpty { return customAliases }
        return customAliases.filter {
            $0.spokenName.localizedCaseInsensitiveContains(searchText) ||
            $0.appName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func aliasRowContent(spoken: String, app: String, isBuiltIn: Bool, onDelete: (() -> Void)?) -> some View {
        HStack(spacing: 12) {
            Text(spoken)
                .font(AirScriptTheme.fontBodyPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(app)
                .font(AirScriptTheme.fontBodyMedium)
                .foregroundStyle(AirScriptTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isBuiltIn {
                StatusBadge(text: "Built-in", color: .secondary, style: .subtle)
            }

            if let onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .frame(width: 30)
            } else {
                Spacer().frame(width: 30)
            }
        }
    }

    // MARK: - Custom Commands Section

    private var customCommandsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "Custom Commands",
                subtitle: "Create your own voice triggers",
                trailing: {
                    Button {
                        showingAddCommand = true
                    } label: {
                        Label("Add Command", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                }
            )

            GlassCard(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    let filtered = filteredCustomCommands
                    if filtered.isEmpty {
                        customCommandsEmptyState
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, command in
                            if index > 0 { Divider() }
                            HoverRow {
                                customCommandRowContent(command)
                            }
                            .staggeredAppear(index: index)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var filteredCustomCommands: [CustomVoiceCommand] {
        if searchText.isEmpty { return customCommands }
        return customCommands.filter {
            $0.trigger.localizedCaseInsensitiveContains(searchText) ||
            $0.actionValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func customCommandRowContent(_ command: CustomVoiceCommand) -> some View {
        HStack(spacing: 12) {
            Text("\"\(command.trigger)\"")
                .font(AirScriptTheme.fontBodyMedium)
                .frame(maxWidth: .infinity, alignment: .leading)

            StatusBadge(text: actionTypeLabel(command.actionType), style: .mono)

            Text(command.actionValue)
                .font(AirScriptTheme.fontCaption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                modelContext.delete(command)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
            .frame(width: 30)
        }
    }

    private var customCommandsEmptyState: some View {
        EmptyStateView(
            icon: "terminal",
            title: searchText.isEmpty ? "No custom commands yet" : "No matching commands",
            subtitle: searchText.isEmpty ? "Create custom voice commands to automate keystrokes, open apps, or launch URLs" : nil
        )
        .frame(height: 200)
    }

    // MARK: - Helpers

    private func searchEmptyState(_ message: String) -> some View {
        Text(message)
            .font(AirScriptTheme.fontSubtitle)
            .foregroundStyle(AirScriptTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func actionTypeLabel(_ type: CustomCommandActionType) -> String {
        switch type {
        case .keystroke: "Keystroke"
        case .openApp: "Open App"
        case .openURL: "Open URL"
        }
    }

    // MARK: - Built-in Data

    struct VoiceCommandRow: Identifiable {
        let id = UUID()
        let phrases: String
        let action: String
    }

    struct VoiceCommandCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let rows: [VoiceCommandRow]
    }

    static let voiceCommandCategories: [VoiceCommandCategory] = [
        VoiceCommandCategory(name: "App Switching", icon: "square.grid.2x2", rows: [
            VoiceCommandRow(phrases: "\"switch to…\", \"go to…\", \"open…\", \"open up…\"", action: "Activates named app"),
            VoiceCommandRow(phrases: "\"launch…\", \"start…\"", action: "Launches named app"),
        ]),
        VoiceCommandCategory(name: "Desktop", icon: "desktopcomputer", rows: [
            VoiceCommandRow(phrases: "\"next desktop\", \"next space\", \"right desktop\"", action: "Ctrl+Right Arrow"),
            VoiceCommandRow(phrases: "\"previous desktop\", \"previous space\", \"left desktop\"", action: "Ctrl+Left Arrow"),
        ]),
        VoiceCommandCategory(name: "Volume", icon: "speaker.wave.3", rows: [
            VoiceCommandRow(phrases: "\"volume up\", \"louder\"", action: "Increase volume"),
            VoiceCommandRow(phrases: "\"volume down\", \"quieter\", \"softer\"", action: "Decrease volume"),
            VoiceCommandRow(phrases: "\"mute\", \"unmute\"", action: "Toggle mute"),
        ]),
        VoiceCommandCategory(name: "Media", icon: "play.circle", rows: [
            VoiceCommandRow(phrases: "\"play\", \"pause\", \"play pause\"", action: "Play/Pause"),
            VoiceCommandRow(phrases: "\"next track\", \"next song\", \"skip\"", action: "Next track"),
            VoiceCommandRow(phrases: "\"previous track\", \"previous song\"", action: "Previous track"),
        ]),
        VoiceCommandCategory(name: "Window", icon: "macwindow", rows: [
            VoiceCommandRow(phrases: "\"close window\", \"close this\"", action: "⌘W"),
            VoiceCommandRow(phrases: "\"minimize\", \"minimize window\"", action: "⌘M"),
            VoiceCommandRow(phrases: "\"full screen\", \"fullscreen\", \"enter full screen\"", action: "⌘⌃F"),
        ]),
        VoiceCommandCategory(name: "Clipboard", icon: "doc.on.clipboard", rows: [
            VoiceCommandRow(phrases: "\"copy\", \"copy that\"", action: "⌘C"),
            VoiceCommandRow(phrases: "\"paste\"", action: "⌘V"),
            VoiceCommandRow(phrases: "\"cut\"", action: "⌘X"),
            VoiceCommandRow(phrases: "\"select all\"", action: "⌘A"),
        ]),
        VoiceCommandCategory(name: "Tabs", icon: "square.on.square", rows: [
            VoiceCommandRow(phrases: "\"new tab\"", action: "⌘T"),
            VoiceCommandRow(phrases: "\"new window\"", action: "⌘N"),
            VoiceCommandRow(phrases: "\"close tab\"", action: "⌘W"),
        ]),
        VoiceCommandCategory(name: "System", icon: "gear", rows: [
            VoiceCommandRow(phrases: "\"take screenshot\", \"screenshot\"", action: "⌘⇧3"),
            VoiceCommandRow(phrases: "\"search for…\", \"google…\", \"look up…\"", action: "Web search"),
            VoiceCommandRow(phrases: "\"undo\"", action: "⌘Z"),
            VoiceCommandRow(phrases: "\"redo\"", action: "⌘⇧Z"),
            VoiceCommandRow(phrases: "\"lock screen\"", action: "⌘⌃Q"),
        ]),
    ]

    static let builtInAliases: [(spoken: String, app: String)] = [
        ("terminal", "Terminal"),
        ("chrome", "Google Chrome"),
        ("firefox", "Firefox"),
        ("code", "Visual Studio Code"),
        ("vscode", "Visual Studio Code"),
        ("finder", "Finder"),
        ("messages", "Messages"),
        ("mail", "Mail"),
        ("music", "Music"),
        ("slack", "Slack"),
        ("discord", "Discord"),
        ("safari", "Safari"),
        ("notes", "Notes"),
        ("cursor", "Cursor"),
        ("xcode", "Xcode"),
        ("iterm", "iTerm2"),
        ("warp", "Warp"),
    ]
}
