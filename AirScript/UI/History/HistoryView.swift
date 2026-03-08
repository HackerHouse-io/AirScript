import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcript.createdAt, order: .reverse) private var transcripts: [Transcript]
    @State private var searchText = ""
    @State private var selectedTranscript: Transcript?
    @State private var showArchived = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                searchBar
                List(filteredTranscripts, selection: $selectedTranscript) { transcript in
                    TranscriptRowView(transcript: transcript)
                        .tag(transcript)
                }
            }
            .navigationTitle("History")
        } detail: {
            if let transcript = selectedTranscript {
                TranscriptDetailView(transcript: transcript)
            } else {
                Text("Select a transcript")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var searchBar: some View {
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
    }

    private var filteredTranscripts: [Transcript] {
        var results = transcripts.filter { !$0.isArchived || showArchived }
        if !searchText.isEmpty {
            results = results.filter {
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
        return results
    }
}
