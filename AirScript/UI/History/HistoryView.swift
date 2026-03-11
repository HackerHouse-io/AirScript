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
                    PageHeader(title: "History", subtitle: "Past transcriptions")

                    let filtered = filteredTranscripts

                    // Controls
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search transcripts...")
                        Spacer()
                        Text("\(filtered.count) transcripts")
                            .font(AirScriptTheme.fontCaption)
                            .foregroundStyle(AirScriptTheme.textTertiary)
                    }
                    .padding(.horizontal)

                    // Transcript list
                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: searchText.isEmpty ? "No transcriptions yet" : "No matches found",
                            subtitle: searchText.isEmpty ? "Hold fn to start dictating — your history will appear here" : nil
                        )
                        .frame(height: 200)
                    } else {
                        GlassCard(padding: 0) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, transcript in
                                    if index > 0 { Divider() }
                                    HoverRow {
                                        transcriptRowContent(transcript)
                                    }
                                    .staggeredAppear(index: index)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(item: $selectedTranscript) { transcript in
            TranscriptDetailView(transcript: transcript) {
                selectedTranscript = nil
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    private func transcriptRowContent(_ transcript: Transcript) -> some View {
        Button {
            selectedTranscript = transcript
        } label: {
            HStack(spacing: 12) {
                Image(systemName: transcript.wasCommand ? "terminal" : "text.quote")
                    .font(AirScriptTheme.fontSubtitle)
                    .foregroundStyle(transcript.wasCommand ? AirScriptTheme.accentWarm : AirScriptTheme.accentMuted)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(transcript.text)
                        .font(AirScriptTheme.fontBodyPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(formatDuration(transcript.duration))
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins)m \(secs)s"
    }
}
