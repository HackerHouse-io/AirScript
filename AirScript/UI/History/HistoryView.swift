import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcript.createdAt, order: .reverse) private var transcripts: [Transcript]
    @State private var searchText = ""
    @State private var selectedTranscript: Transcript?

    private var filteredTranscripts: [Transcript] {
        var results = transcripts.filter { !$0.isArchived }
        if !searchText.isEmpty {
            results = results.filter {
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
        return results
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    heroBanner
                    controlBar
                    transcriptList
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $selectedTranscript) { transcript in
            TranscriptDetailView(transcript: transcript) {
                selectedTranscript = nil
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Browse and search your transcription history. Click any entry to view details, copy text, or re-inject into your current app.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.indigo, Color.indigo.opacity(0.7)],
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
                TextField("Search transcripts...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Text("\(filteredTranscripts.count) transcripts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Transcript List

    private var transcriptList: some View {
        VStack(spacing: 0) {
            if filteredTranscripts.isEmpty {
                emptyState
            } else {
                ForEach(filteredTranscripts) { transcript in
                    if transcript.id != filteredTranscripts.first?.id {
                        Divider()
                    }
                    transcriptRow(transcript)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func transcriptRow(_ transcript: Transcript) -> some View {
        Button {
            selectedTranscript = transcript
        } label: {
            HStack(spacing: 12) {
                Image(systemName: transcript.wasCommand ? "terminal" : "text.quote")
                    .font(.subheadline)
                    .foregroundStyle(transcript.wasCommand ? .orange : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(transcript.text)
                        .font(.body)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(formatDuration(transcript.duration))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(transcript.wordCount) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let appName = transcript.appName {
                            Text(appName)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Spacer()

                Text(transcript.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcript.text, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                if selectedTranscript == transcript {
                    selectedTranscript = nil
                }
                modelContext.delete(transcript)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No transcriptions yet" : "No matches found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Hold fn to start dictating — your history will appear here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins)m \(secs)s"
    }
}
