import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AirNote.createdAt, order: .reverse) private var notes: [AirNote]
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)

            Divider()

            List {
                // Pinned section
                let pinned = filteredNotes.filter(\.isPinned)
                if !pinned.isEmpty {
                    Section("Pinned") {
                        ForEach(pinned) { note in
                            NoteRowView(note: note)
                        }
                    }
                }

                // All notes
                let unpinned = filteredNotes.filter { !$0.isPinned }
                Section("Notes") {
                    ForEach(unpinned) { note in
                        NoteRowView(note: note)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(unpinned[index])
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }

    private var filteredNotes: [AirNote] {
        let active = notes.filter { !$0.isArchived }
        if searchText.isEmpty { return active }
        return active.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
}
