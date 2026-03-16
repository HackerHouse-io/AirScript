import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Transcript> { !$0.isArchived },
        sort: \Transcript.createdAt,
        order: .reverse
    )
    private var transcripts: [Transcript]
    @State private var searchText = ""
    @State private var selectedTranscript: Transcript?
    @State private var isSelectMode = false
    @State private var selectedTranscriptIDs: Set<UUID> = []
    @State private var showBulkDeleteConfirmation = false

    private var filteredTranscripts: [Transcript] {
        if searchText.isEmpty { return transcripts }
        return transcripts.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        let filtered = filteredTranscripts
        let allSelected = !filtered.isEmpty && filtered.allSatisfy { selectedTranscriptIDs.contains($0.id) }

        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    PageHeader(title: "History", subtitle: "Past transcriptions")

                    // Controls
                    HStack(spacing: 12) {
                        AirSearchBar(text: $searchText, placeholder: "Search transcripts...")
                        Spacer()

                        if isSelectMode {
                            controlBarButton(allSelected ? "Deselect All" : "Select All") {
                                if allSelected {
                                    selectedTranscriptIDs.removeAll()
                                } else {
                                    selectedTranscriptIDs = Set(filtered.map(\.id))
                                }
                            }
                        }

                        if !filtered.isEmpty {
                            controlBarButton(isSelectMode ? "Done" : "Select") {
                                withAnimation(AirScriptTheme.Anim.fast) {
                                    isSelectMode.toggle()
                                    if !isSelectMode {
                                        selectedTranscriptIDs.removeAll()
                                    }
                                }
                            }
                        }

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
                                    TranscriptRow(
                                        transcript: transcript,
                                        isSelectMode: isSelectMode,
                                        isSelected: selectedTranscriptIDs.contains(transcript.id),
                                        onTap: { selectedTranscript = transcript },
                                        onDelete: { deleteSingle(transcript) },
                                        onToggleSelection: { toggleSelection(transcript) }
                                    )
                                    .staggeredAppear(index: index)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, isSelectMode && !selectedTranscriptIDs.isEmpty ? 64 : 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelectMode && !selectedTranscriptIDs.isEmpty {
                bulkActionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(AirScriptTheme.Anim.medium, value: selectedTranscriptIDs.isEmpty)
        .sheet(item: $selectedTranscript) { transcript in
            TranscriptDetailView(transcript: transcript) {
                selectedTranscript = nil
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        .alert("Delete \(selectedTranscriptIDs.count) Transcripts?", isPresented: $showBulkDeleteConfirmation) {
            Button("Delete \(selectedTranscriptIDs.count)", role: .destructive) {
                performBulkDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These transcripts will be permanently deleted.")
        }
        .onChange(of: searchText) {
            selectedTranscriptIDs.removeAll()
        }
        .onKeyPress(.delete) {
            guard isSelectMode, !selectedTranscriptIDs.isEmpty else { return .ignored }
            requestBulkDelete()
            return .handled
        }
    }

    // MARK: - Bulk Action Bar

    private var bulkActionBar: some View {
        HStack {
            Text("\(selectedTranscriptIDs.count) selected")
                .font(AirScriptTheme.fontBodyMedium)
                .foregroundStyle(AirScriptTheme.textSecondary)

            Spacer()

            Button(role: .destructive) {
                requestBulkDelete()
            } label: {
                Label("Delete Selected (\(selectedTranscriptIDs.count))", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Control Bar Button

    private func controlBarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AirScriptTheme.fontBodyPrimary)
                .foregroundStyle(AirScriptTheme.accent)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AirScriptTheme.Spacing.md)
        .padding(.vertical, AirScriptTheme.Spacing.sm)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous))
    }

    // MARK: - Actions

    private func toggleSelection(_ transcript: Transcript) {
        if selectedTranscriptIDs.contains(transcript.id) {
            selectedTranscriptIDs.remove(transcript.id)
        } else {
            selectedTranscriptIDs.insert(transcript.id)
        }
    }

    private func deleteSingle(_ transcript: Transcript) {
        withAnimation {
            if selectedTranscript == transcript {
                selectedTranscript = nil
            }
            selectedTranscriptIDs.remove(transcript.id)
            modelContext.delete(transcript)
        }
    }

    private func requestBulkDelete() {
        if selectedTranscriptIDs.count >= 2 {
            showBulkDeleteConfirmation = true
        } else {
            performBulkDelete()
        }
    }

    private func performBulkDelete() {
        withAnimation {
            let idsToDelete = selectedTranscriptIDs
            for transcript in transcripts where idsToDelete.contains(transcript.id) {
                if selectedTranscript == transcript {
                    selectedTranscript = nil
                }
                modelContext.delete(transcript)
            }
            selectedTranscriptIDs.removeAll()
            isSelectMode = false
        }
    }
}
