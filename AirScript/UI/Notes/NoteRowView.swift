import SwiftUI

struct NoteRowView: View {
    let note: AirNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(note.text)
                    .lineLimit(2)
                    .font(.body)
            }

            HStack {
                Text(note.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if note.audioFileURL != nil {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(note.isPinned ? "Unpin" : "Pin") {
                note.isPinned.toggle()
            }
            Button("Archive") {
                note.isArchived = true
            }
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(note.text, forType: .string)
            }
        }
    }
}
