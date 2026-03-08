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
                    heroBanner
                    controlBar
                    entryList
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddDictionaryEntrySheet()
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dictionary")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Teach AirScript your vocabulary. Add custom words, names, and technical terms so they're always transcribed correctly.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "textformat.abc")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.7)],
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
                TextField("Search dictionary...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Picker("", selection: $sourceFilter) {
                ForEach(DictionarySourceFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)

            Spacer()

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Word", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        VStack(spacing: 0) {
            if filteredEntries.isEmpty {
                emptyState
            } else {
                // Header row
                HStack {
                    Text("Spoken")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("Written")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50)
                    Text("Source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80)
                    Spacer()
                        .frame(width: 30)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()

                ForEach(filteredEntries) { entry in
                    dictionaryRow(entry)
                    Divider()
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dictionaryRow(_ entry: DictionaryEntry) -> some View {
        HStack {
            Text(entry.spoken)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(entry.written)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(entry.usageCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 50)

            Text(entry.source == .manual ? "Manual" : "Learned")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(entry.source == .manual ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundStyle(entry.source == .manual ? .blue : .green)
                .clipShape(Capsule())
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "textformat.abc")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No dictionary entries yet" : "No matches found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Add custom words to improve transcription accuracy")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
        VStack(spacing: 20) {
            Text("Add Dictionary Entry")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spoken form")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. whisperkit", text: $spoken)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Written form")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. WhisperKit", text: $written)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Case sensitive", isOn: $caseSensitive)
            }

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
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
