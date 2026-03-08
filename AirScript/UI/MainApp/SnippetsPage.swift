import SwiftUI
import SwiftData

struct SnippetsPage: View {
    @Query(sort: \Snippet.createdAt, order: .reverse)
    private var snippets: [Snippet]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddSheet = false

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty { return snippets }
        return snippets.filter {
            $0.trigger.localizedCaseInsensitiveContains(searchText) ||
            $0.value.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    heroBanner
                    controlBar
                    snippetList
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddSnippetSheet()
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Snippets")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Create voice-activated shortcuts. Say a trigger phrase to instantly expand text, run shell commands, or simulate keystrokes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "text.insert")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.orange.opacity(0.7)],
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
                TextField("Search snippets...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Snippet", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Snippet List

    private var snippetList: some View {
        VStack(spacing: 0) {
            if filteredSnippets.isEmpty {
                emptyState
            } else {
                ForEach(filteredSnippets) { snippet in
                    snippetRow(snippet)
                    if snippet.id != filteredSnippets.last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func snippetRow(_ snippet: Snippet) -> some View {
        HStack(spacing: 16) {
            // Type icon
            Image(systemName: snippetIcon(for: snippet.actionType))
                .font(.title3)
                .foregroundStyle(snippetColor(for: snippet.actionType))
                .frame(width: 32)

            // Trigger and value
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\"\(snippet.trigger)\"")
                        .font(.body)
                        .fontWeight(.medium)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(snippet.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Type badge
            Text(snippetTypeLabel(for: snippet.actionType))
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(snippetColor(for: snippet.actionType).opacity(0.15))
                .foregroundStyle(snippetColor(for: snippet.actionType))
                .clipShape(Capsule())

            // Usage
            VStack(spacing: 2) {
                Text("\(snippet.usageCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
                Text("uses")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 40)

            // Delete
            Button {
                modelContext.delete(snippet)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.insert")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No snippets yet" : "No matches found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Create a snippet to expand text with your voice")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func snippetIcon(for type: SnippetActionType) -> String {
        switch type {
        case .text: "doc.text"
        case .shell: "terminal"
        case .keystroke: "keyboard"
        }
    }

    private func snippetColor(for type: SnippetActionType) -> Color {
        switch type {
        case .text: .blue
        case .shell: .green
        case .keystroke: .orange
        }
    }

    private func snippetTypeLabel(for type: SnippetActionType) -> String {
        switch type {
        case .text: "Text"
        case .shell: "Shell"
        case .keystroke: "Keystroke"
        }
    }
}

// MARK: - Add Snippet Sheet

struct AddSnippetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var trigger = ""
    @State private var value = ""
    @State private var actionType: SnippetActionType = .text

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Snippet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trigger phrase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. insert signature", text: $trigger)
                        .textFieldStyle(.roundedBorder)
                }

                Picker("Type", selection: $actionType) {
                    Text("Text").tag(SnippetActionType.text)
                    Text("Shell Command").tag(SnippetActionType.shell)
                    Text("Keystroke").tag(SnippetActionType.keystroke)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(valueLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if actionType == .text {
                        TextEditor(text: $value)
                            .font(.body)
                            .frame(height: 80)
                            .border(Color(nsColor: .separatorColor))
                    } else {
                        TextField(valuePlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    let snippet = Snippet(
                        trigger: trigger,
                        actionType: actionType,
                        value: value
                    )
                    modelContext.insert(snippet)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trigger.isEmpty || value.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private var valueLabel: String {
        switch actionType {
        case .text: "Expansion text"
        case .shell: "Shell command"
        case .keystroke: "Keystroke (keyCode:flags)"
        }
    }

    private var valuePlaceholder: String {
        switch actionType {
        case .text: "Text to insert..."
        case .shell: "e.g. open -a Safari"
        case .keystroke: "e.g. 36:cmd (Enter with Cmd)"
        }
    }
}
