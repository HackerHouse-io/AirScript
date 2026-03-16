import SwiftUI

struct TranscriptRow: View {
    let transcript: Transcript
    var isSelectMode: Bool = false
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    var onDelete: () -> Void = {}
    var onToggleSelection: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HoverRow(content: {
            rowContent
        }, trailing: { isHovered in
            if isSelectMode {
                EmptyView()
            } else {
                deleteButton(rowHovered: isHovered)
            }
        })
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcript.text, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private var rowContent: some View {
        Button {
            if isSelectMode {
                onToggleSelection()
            } else {
                onTap()
            }
        } label: {
            HStack(spacing: 12) {
                if isSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? AirScriptTheme.accent : AirScriptTheme.textTertiary)
                } else {
                    Image(systemName: transcript.wasCommand ? "terminal" : "text.quote")
                        .font(AirScriptTheme.fontSubtitle)
                        .foregroundStyle(transcript.wasCommand ? AirScriptTheme.accentWarm : AirScriptTheme.accentMuted)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(transcript.text)
                        .font(AirScriptTheme.fontBodyPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(transcript.duration.compactDuration)
                            .font(AirScriptTheme.fontCaption2)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                        Text("\(transcript.wordCount) words")
                            .font(AirScriptTheme.fontCaption2)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                        if let appName = transcript.appName {
                            StatusBadge(text: appName, style: .mono)
                        }
                    }
                }

                Spacer()

                Text(transcript.createdAt, style: .relative)
                    .font(AirScriptTheme.fontCaption2)
                    .foregroundStyle(AirScriptTheme.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func deleteButton(rowHovered: Bool) -> some View {
        DeleteHoverButton(visible: rowHovered || reduceMotion, action: onDelete)
    }

}

// MARK: - Delete Hover Button

private struct DeleteHoverButton: View {
    let visible: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 12))
                .foregroundStyle(isHovered ? AirScriptTheme.statusError : AirScriptTheme.textTertiary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .opacity(visible ? 1 : 0)
        .animation(AirScriptTheme.Anim.fast, value: visible)
        .animation(AirScriptTheme.Anim.fast, value: isHovered)
    }
}
