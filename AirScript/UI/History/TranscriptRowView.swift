import SwiftUI

struct TranscriptRowView: View {
    let transcript: Transcript

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcript.text)
                .lineLimit(2)
                .font(.body)

            HStack(spacing: 8) {
                if let appName = transcript.appName {
                    Label(appName, systemImage: "app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(formatDuration(transcript.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(transcript.wordCount) words")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(transcript.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}
