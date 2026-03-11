import SwiftUI

struct NoteRowView: View {
    let note: AirNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(AirScriptTheme.accentWarm)
                }
                Text(note.text)
                    .lineLimit(2)
                    .font(AirScriptTheme.fontBodyPrimary)
            }

            HStack {
                Text(note.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AirScriptTheme.textSecondary)

                if note.audioFileURL != nil {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(AirScriptTheme.accentMuted)
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
