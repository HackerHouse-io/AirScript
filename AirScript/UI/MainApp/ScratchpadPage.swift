import SwiftUI
import SwiftData

struct ScratchpadPage: View {
    @Query(
        filter: #Predicate<AirNote> { !$0.isArchived },
        sort: \AirNote.createdAt,
        order: .reverse
    )
    private var notes: [AirNote]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedNote: AirNote?
    @State private var showingNewNote = false

    private var pinnedNotes: [AirNote] {
        filteredNotes.filter { $0.isPinned }
    }

    private var unpinnedNotes: [AirNote] {
        filteredNotes.filter { !$0.isPinned }
    }

    private var filteredNotes: [AirNote] {
        if searchText.isEmpty { return Array(notes) }
        return notes.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    heroBanner
                    controlBar

                    if notes.isEmpty {
                        emptyState
                    } else {
                        notesList
                    }
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingNewNote) {
            NewNoteSheet()
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Scratchpad")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Quick voice notes and scratch thoughts. Capture ideas instantly with your voice — pin the important ones for easy access.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.teal, Color.teal.opacity(0.7)],
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
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Button {
                showingNewNote = true
            } label: {
                Label("New Note", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(spacing: 16) {
            if !pinnedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pinned")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 1) {
                        ForEach(pinnedNotes) { note in
                            noteRow(note)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if !unpinnedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !pinnedNotes.isEmpty {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    VStack(spacing: 1) {
                        ForEach(unpinnedNotes) { note in
                            noteRow(note)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func noteRow(_ note: AirNote) -> some View {
        Button {
            selectedNote = note
        } label: {
            HStack(spacing: 12) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.text)
                        .font(.subheadline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(note.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        if note.audioFileURL != nil {
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if !note.tags.isEmpty {
                            Text(note.tags.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text(formatDuration(note.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(note.isPinned ? "Unpin" : "Pin") {
                note.isPinned.toggle()
            }
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(note.text, forType: .string)
            }
            Divider()
            Button("Archive") {
                note.isArchived = true
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(note)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Create a note or use voice to capture quick thoughts")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 { return "\(Int(duration))s" }
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return "\(mins)m \(secs)s"
    }
}

// MARK: - New Note Sheet

struct NewNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Note")
                .font(.headline)

            TextEditor(text: $text)
                .font(.body)
                .frame(height: 120)
                .border(Color(nsColor: .separatorColor))

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let note = AirNote(
                        text: text,
                        rawText: text,
                        duration: 0
                    )
                    modelContext.insert(note)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Note Detail Sheet

struct NoteDetailSheet: View {
    let note: AirNote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Note")
                    .font(.headline)
                Spacer()
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(note.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)

            HStack {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(note.text, forType: .string)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 450, minHeight: 300)
    }
}
