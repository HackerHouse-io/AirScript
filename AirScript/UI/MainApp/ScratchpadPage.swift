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
                    PageHeader(title: "Scratchpad")

                    // Controls
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search notes...")
                        Spacer()
                        Button {
                            showingNewNote = true
                        } label: {
                            Label("New Note", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AirScriptTheme.accent)
                    }
                    .padding(.horizontal)

                    if notes.isEmpty {
                        EmptyStateView(
                            icon: "note.text",
                            title: "No notes yet",
                            subtitle: "Create a note or use voice to capture quick thoughts"
                        )
                        .frame(height: 200)
                    } else {
                        notesList
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteSheet()
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        let pinned = pinnedNotes
        let unpinned = unpinnedNotes
        return VStack(spacing: 16) {
            if !pinned.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Pinned")

                    GlassCard(padding: 0) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(pinned.enumerated()), id: \.element.id) { index, note in
                                if index > 0 { Divider() }
                                HoverRow {
                                    noteRowContent(note)
                                }
                                .staggeredAppear(index: index)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            if !unpinned.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !pinned.isEmpty {
                        SectionHeader(title: "Notes")
                    }

                    GlassCard(padding: 0) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(unpinned.enumerated()), id: \.element.id) { index, note in
                                if index > 0 { Divider() }
                                HoverRow {
                                    noteRowContent(note)
                                }
                                .staggeredAppear(index: index)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func noteRowContent(_ note: AirNote) -> some View {
        Button {
            selectedNote = note
        } label: {
            HStack(spacing: 12) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(AirScriptTheme.accentWarm)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.text)
                        .font(AirScriptTheme.fontBodyPrimary)
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
                                .foregroundStyle(AirScriptTheme.accentMuted)
                        }

                        if !note.tags.isEmpty {
                            Text(note.tags.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(AirScriptTheme.accent)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text(note.duration.compactDuration)
                    .font(AirScriptTheme.fontMono)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
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
}

// MARK: - New Note Sheet

struct NewNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""

    var body: some View {
        AirSheet(title: "New Note") {
            VStack(spacing: 16) {
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
                    .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
        .frame(width: 400)
    }
}

// MARK: - Note Detail Sheet

struct NoteDetailSheet: View {
    let note: AirNote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AirSheet(title: "Note", onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(note.createdAt, style: .date)
                        .font(AirScriptTheme.fontCaption)
                        .foregroundStyle(.secondary)
                    Spacer()
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
                        .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 300)
    }
}
