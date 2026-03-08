import SwiftUI

struct TranscriptDetailView: View {
    let transcript: Transcript
    @State private var showRawText = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(transcript.createdAt, style: .date)
                            .font(.headline)
                        Text(transcript.createdAt, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let appName = transcript.appName {
                        Label(appName, systemImage: "app")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                // Metadata
                HStack(spacing: 16) {
                    metadataItem("Duration", value: formatDuration(transcript.duration))
                    metadataItem("Words", value: "\(transcript.wordCount)")
                    metadataItem("WPM", value: String(format: "%.0f", transcript.wordsPerMinute))
                    metadataItem("Model", value: transcript.model)
                }

                Divider()

                // Toggle raw/processed
                Toggle("Show raw ASR text", isOn: $showRawText)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                // Text content
                Text(showRawText ? transcript.rawText : transcript.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Actions
                HStack {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcript.text, forType: .string)
                    }
                    .buttonStyle(.bordered)

                    Button("Re-inject") {
                        Task {
                            await TextInjector.inject(text: transcript.text)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func metadataItem(_ label: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.subheadline.weight(.medium))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}
