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
                    PageHeader(title: "Snippets")

                    // Controls
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search snippets...")
                        Spacer()
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Snippet", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AirScriptTheme.accent)
                    }
                    .padding(.horizontal)

                    // Snippet list
                    let filtered = filteredSnippets
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            if filtered.isEmpty {
                                EmptyStateView(
                                    icon: "text.insert",
                                    title: searchText.isEmpty ? "No snippets yet" : "No matches found",
                                    subtitle: searchText.isEmpty ? "Create a snippet to expand text with your voice" : nil
                                )
                                .frame(height: 200)
                            } else {
                                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, snippet in
                                    if index > 0 { Divider() }
                                    HoverRow {
                                        snippetRowContent(snippet)
                                    }
                                    .staggeredAppear(index: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSnippetSheet()
        }
    }

    private func snippetRowContent(_ snippet: Snippet) -> some View {
        HStack(spacing: 16) {
            Image(systemName: snippetIcon(for: snippet.actionType))
                .font(.title3)
                .foregroundStyle(AirScriptTheme.accentMuted)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\"\(snippet.trigger)\"")
                        .font(AirScriptTheme.fontBodyMedium)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(snippet.value)
                    .font(AirScriptTheme.fontMono)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusBadge(text: snippetTypeLabel(for: snippet.actionType), style: .mono)

            VStack(spacing: 2) {
                Text("\(snippet.usageCount)")
                    .font(AirScriptTheme.fontMono)
                    .fontWeight(.medium)
                    .monospacedDigit()
                Text("uses")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 40)

            Button {
                modelContext.delete(snippet)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
        }
    }

    private func snippetIcon(for type: SnippetActionType) -> String {
        switch type {
        case .text: "doc.text"
        case .shell: "terminal"
        case .keystroke: "keyboard"
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
        AirSheet(title: "Add Snippet") {
            VStack(spacing: 16) {
                AirTextField(label: "Trigger phrase", text: $trigger, placeholder: "e.g. insert signature")

                Picker("Type", selection: $actionType) {
                    Text("Text").tag(SnippetActionType.text)
                    Text("Shell Command").tag(SnippetActionType.shell)
                    Text("Keystroke").tag(SnippetActionType.keystroke)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(valueLabel.uppercased())
                        .font(AirScriptTheme.fontBadge)
                        .foregroundStyle(AirScriptTheme.textTertiary)
                        .tracking(0.5)
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
                    .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
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
