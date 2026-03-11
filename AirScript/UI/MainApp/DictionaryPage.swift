import SwiftUI
import SwiftData

struct DictionaryPage: View {
    @Query(sort: \DictionaryEntry.createdAt, order: .reverse)
    private var entries: [DictionaryEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var sourceFilter: DictionarySourceFilter = .all

    enum DictionarySourceFilter: String, CaseIterable {
        case all = "All"
        case manual = "Manual"
        case autoLearned = "Auto-learned"
    }

    private var filteredEntries: [DictionaryEntry] {
        var result = entries
        if sourceFilter == .manual {
            result = result.filter { $0.source == .manual }
        } else if sourceFilter == .autoLearned {
            result = result.filter { $0.source == .autoLearned }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.spoken.localizedCaseInsensitiveContains(searchText) ||
                $0.written.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    PageHeader(title: "Dictionary")

                    // Controls
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search dictionary...")

                        Picker("", selection: $sourceFilter) {
                            ForEach(DictionarySourceFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()

                        Spacer()

                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Word", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AirScriptTheme.accent)
                    }
                    .padding(.horizontal)

                    // Entry list
                    let filtered = filteredEntries
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            if filtered.isEmpty {
                                EmptyStateView(
                                    icon: "textformat.abc",
                                    title: searchText.isEmpty ? "No dictionary entries yet" : "No matches found",
                                    subtitle: searchText.isEmpty ? "Add custom words to improve transcription accuracy" : nil
                                )
                                .frame(height: 200)
                            } else {
                                // Header row
                                HStack {
                                    Text("Spoken")
                                        .font(AirScriptTheme.fontCaption)
                                        .foregroundStyle(AirScriptTheme.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text("Written")
                                        .font(AirScriptTheme.fontCaption)
                                        .foregroundStyle(AirScriptTheme.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Used")
                                        .font(AirScriptTheme.fontCaption)
                                        .foregroundStyle(AirScriptTheme.textTertiary)
                                        .frame(width: 50)
                                    Text("Source")
                                        .font(AirScriptTheme.fontCaption)
                                        .foregroundStyle(AirScriptTheme.textTertiary)
                                        .frame(width: 80)
                                    Spacer()
                                        .frame(width: 30)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)

                                Divider()

                                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, entry in
                                    HoverRow {
                                        dictionaryRowContent(entry)
                                    }
                                    .staggeredAppear(index: index)
                                    Divider()
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
            AddDictionaryEntrySheet()
        }
    }

    private func dictionaryRowContent(_ entry: DictionaryEntry) -> some View {
        HStack {
            Text(entry.spoken)
                .font(AirScriptTheme.fontBodyPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(entry.written)
                .font(AirScriptTheme.fontBodyMedium)
                .foregroundStyle(AirScriptTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(entry.usageCount)")
                .font(AirScriptTheme.fontMono)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 50)

            StatusBadge(
                text: entry.source == .manual ? "Manual" : "Learned",
                color: entry.source == .manual ? AirScriptTheme.accent : AirScriptTheme.statusSuccess,
                style: .mono
            )
            .frame(width: 80)

            Button {
                modelContext.delete(entry)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
            .frame(width: 30)
        }
    }
}

// MARK: - Add Entry Sheet

struct AddDictionaryEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var spoken = ""
    @State private var written = ""
    @State private var caseSensitive = false

    var body: some View {
        AirSheet(title: "Add Dictionary Entry") {
            VStack(spacing: 16) {
                AirTextField(label: "Spoken form", text: $spoken, placeholder: "e.g. whisperkit")
                AirTextField(label: "Written form", text: $written, placeholder: "e.g. WhisperKit")
                Toggle("Case sensitive", isOn: $caseSensitive)

                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Add") {
                        let entry = DictionaryEntry(
                            spoken: spoken,
                            written: written,
                            caseSensitive: caseSensitive
                        )
                        modelContext.insert(entry)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(spoken.isEmpty || written.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
        .frame(width: 360)
    }
}
