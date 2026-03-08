import SwiftUI
import SwiftData

struct DictionarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DictionaryEntry.spoken) private var entries: [DictionaryEntry]
    @State private var newSpoken = ""
    @State private var newWritten = ""
    @State private var filterSource: DictionarySource?

    var body: some View {
        VStack(spacing: 0) {
            // Add new entry
            HStack {
                TextField("Spoken", text: $newSpoken)
                    .textFieldStyle(.roundedBorder)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                TextField("Written", text: $newWritten)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addEntry()
                }
                .disabled(newSpoken.isEmpty || newWritten.isEmpty)
            }
            .padding()

            Divider()

            // Filter
            Picker("Source", selection: $filterSource) {
                Text("All").tag(nil as DictionarySource?)
                Text("Manual").tag(DictionarySource.manual as DictionarySource?)
                Text("Auto-learned").tag(DictionarySource.autoLearned as DictionarySource?)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // List
            List {
                ForEach(filteredEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.spoken)
                                .font(.body)
                            Text(entry.written)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text("\(entry.usageCount)x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
        }
    }

    private var filteredEntries: [DictionaryEntry] {
        if let source = filterSource {
            return entries.filter { $0.source == source }
        }
        return entries
    }

    private func addEntry() {
        let entry = DictionaryEntry(spoken: newSpoken, written: newWritten)
        modelContext.insert(entry)
        newSpoken = ""
        newWritten = ""
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
        }
    }
}
