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
                    heroBanner
                    controlBar
                    voiceCommandsSection
                    appAliasesSection
                    customCommandsSection
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddAlias) {
            AddAliasSheet()
        }
        .sheet(isPresented: $showingAddCommand) {
            AddCustomCommandSheet()
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Commands & Shortcuts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("View all built-in voice commands and app aliases, or create your own custom commands and shortcuts.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "command")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.green, Color.green.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search commands...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
    }

    // MARK: - Voice Commands Section

    private var voiceCommandsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Voice Commands", icon: "mic.fill", subtitle: "Built-in")

            let filtered = filteredVoiceCommands
            if filtered.isEmpty {
                searchEmptyState("No matching voice commands")
            } else {
                ForEach(Array(filtered.enumerated()), id: \.offset) { index, category in
                    if index > 0 { Divider() }
                    voiceCommandCategoryView(category)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .frame(width: 20)
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            ForEach(Array(category.rows.enumerated()), id: \.offset) { _, row in
                Divider().padding(.leading, 44)
                HStack(spacing: 12) {
                    Spacer().frame(width: 20)
                    Text(row.phrases)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.action)
                        .font(.caption)
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
            HStack {
                sectionHeader("App Aliases", icon: "app.fill", subtitle: "\(Self.builtInAliases.count) built-in")
                Spacer()
                Button {
                    showingAddAlias = true
                } label: {
                    Label("Add Alias", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.trailing, 16)
                .padding(.top, 12)
            }

            let builtIn = filteredBuiltInAliases
            let custom = filteredCustomAliases

            if builtIn.isEmpty && custom.isEmpty {
                searchEmptyState("No matching aliases")
            } else {
                // Custom aliases first
                ForEach(custom) { alias in
                    Divider()
                    aliasRow(spoken: alias.spokenName, app: alias.appName, isBuiltIn: false) {
                        modelContext.delete(alias)
                    }
                }

                // Built-in aliases
                ForEach(Array(builtIn.enumerated()), id: \.offset) { _, pair in
                    Divider()
                    aliasRow(spoken: pair.spoken, app: pair.app, isBuiltIn: true, onDelete: nil)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private func aliasRow(spoken: String, app: String, isBuiltIn: Bool, onDelete: (() -> Void)?) -> some View {
        HStack(spacing: 12) {
            Text(spoken)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(app)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isBuiltIn {
                Text("Built-in")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Custom Commands Section

    private var customCommandsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("Custom Commands", icon: "terminal.fill", subtitle: "User-created")
                Spacer()
                Button {
                    showingAddCommand = true
                } label: {
                    Label("Add Command", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.trailing, 16)
                .padding(.top, 12)
            }

            let filtered = filteredCustomCommands
            if filtered.isEmpty {
                customCommandsEmptyState
            } else {
                ForEach(filtered) { command in
                    Divider()
                    customCommandRow(command)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filteredCustomCommands: [CustomVoiceCommand] {
        if searchText.isEmpty { return customCommands }
        return customCommands.filter {
            $0.trigger.localizedCaseInsensitiveContains(searchText) ||
            $0.actionValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func customCommandRow(_ command: CustomVoiceCommand) -> some View {
        HStack(spacing: 12) {
            Text("\"\(command.trigger)\"")
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(actionTypeLabel(command.actionType))
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(actionTypeColor(command.actionType).opacity(0.15))
                .foregroundStyle(actionTypeColor(command.actionType))
                .clipShape(Capsule())

            Text(command.actionValue)
                .font(.caption)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var customCommandsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No custom commands yet" : "No matching commands")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Create custom voice commands to automate keystrokes, open apps, or launch URLs")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.green)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func searchEmptyState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
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

    private func actionTypeColor(_ type: CustomCommandActionType) -> Color {
        switch type {
        case .keystroke: .orange
        case .openApp: .blue
        case .openURL: .purple
        }
    }

    // MARK: - Built-in Data

    struct VoiceCommandRow {
        let phrases: String
        let action: String
    }

    struct VoiceCommandCategory {
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
