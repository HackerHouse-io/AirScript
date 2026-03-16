import SwiftUI
import SwiftData

struct HomePage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Transcript> { !$0.isArchived },
        sort: \Transcript.createdAt,
        order: .reverse
    )
    private var recentTranscripts: [Transcript]

    @State private var selectedTranscript: Transcript?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PageHeader(title: "Home", subtitle: "Your voice, your words")

                // Status pills
                HStack(spacing: 12) {
                    statusPill(
                        icon: "mic",
                        label: appState.hasMicrophonePermission ? "Mic Ready" : "Mic Needed",
                        ok: appState.hasMicrophonePermission
                    )
                    statusPill(
                        icon: "hand.raised",
                        label: appState.hasAccessibilityPermission ? "Accessibility OK" : "Accessibility Needed",
                        ok: appState.hasAccessibilityPermission
                    )
                    statusPill(
                        icon: "waveform",
                        label: appState.isWhisperModelDownloading
                            ? "Whisper: \(Int(appState.modelDownloadProgress * 100))%"
                            : appState.isWhisperModelLoaded
                                ? "Whisper: \(ModelInfo.whisperDisplayName(for: appState.selectedWhisperModel))"
                                : "Whisper Not Loaded",
                        ok: appState.isWhisperModelLoaded,
                        busy: appState.isWhisperModelDownloading
                    )
                    statusPill(
                        icon: "brain",
                        label: appState.isLLMModelDownloading
                            ? "LLM: \(Int(appState.llmModelDownloadProgress * 100))%"
                            : appState.isLLMModelLoaded
                                ? "LLM: \(ModelInfo.llmDisplayName(for: appState.selectedLLMModel))"
                                : "LLM Not Loaded",
                        ok: appState.isLLMModelLoaded,
                        busy: appState.isLLMModelDownloading
                    )
                    Spacer()
                }
                .padding(.horizontal)

                statsSection
                recentActivitySection
            }
            .padding(.bottom, 8)
        }
        .sheet(item: $selectedTranscript) { transcript in
            TranscriptDetailView(transcript: transcript) {
                selectedTranscript = nil
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    // MARK: - Status Pill

    private func statusPill(icon: String, label: String, ok: Bool, busy: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            busy ? Color.orange.opacity(0.12)
                : ok ? AirScriptTheme.statusSuccess.opacity(0.12)
                : AirScriptTheme.statusError.opacity(0.12)
        )
        .foregroundStyle(
            busy ? Color.orange
                : ok ? AirScriptTheme.statusSuccess
                : AirScriptTheme.statusError
        )
        .clipShape(Capsule())
    }

    // MARK: - Stats (Bento Grid)

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Stats")

            HStack(spacing: 12) {
                statCard(label: "Words Today", value: "\(todayWords)", detail: "\(weekWords) this week", index: 0, accent: true)
                statCard(label: "Sessions Today", value: "\(todaySessions)", detail: "\(totalSessions) total", index: 1)
                statCard(label: "Time Saved", value: timeSaved, detail: "vs typing", index: 2)
            }
            .padding(.horizontal)
        }
    }

    private func statCard(label: String, value: String, detail: String, index: Int, accent: Bool = false) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Text(label)
                    .font(AirScriptTheme.fontStatLabel)
                    .foregroundStyle(AirScriptTheme.textSecondary)
                Text(value)
                    .font(AirScriptTheme.fontStatValue)
                    .foregroundStyle(accent ? AirScriptTheme.accent : .primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(detail)
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(index: index)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Recent Transcriptions",
                trailing: {
                    Text("\(recentTranscripts.count) total")
                        .font(AirScriptTheme.fontCaption)
                        .foregroundStyle(AirScriptTheme.textTertiary)
                }
            )

            if recentTranscripts.isEmpty {
                EmptyStateView(
                    icon: "waveform",
                    title: "No transcriptions yet",
                    subtitle: "Hold fn to start dictating"
                )
                .frame(height: 160)
            } else {
                GlassCard(padding: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(recentTranscripts.prefix(20).enumerated()), id: \.element.id) { index, transcript in
                            if index > 0 { Divider() }
                            TranscriptRow(
                                transcript: transcript,
                                onTap: { selectedTranscript = transcript },
                                onDelete: {
                                    withAnimation {
                                        modelContext.delete(transcript)
                                    }
                                }
                            )
                            .staggeredAppear(index: index)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Computed Stats (derived from transcripts so deletions are reflected)

    private var todayTranscripts: [Transcript] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return recentTranscripts.filter { $0.createdAt >= startOfToday }
    }

    private var todayWords: Int {
        todayTranscripts.reduce(0) { $0 + $1.wordCount }
    }

    private var todaySessions: Int {
        todayTranscripts.count
    }

    private var weekWords: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentTranscripts.filter { $0.createdAt >= weekAgo }.reduce(0) { $0 + $1.wordCount }
    }

    private var totalSessions: Int {
        recentTranscripts.count
    }

    private var timeSaved: String {
        let totalWords = recentTranscripts.reduce(0) { $0 + $1.wordCount }
        let typingMinutes = Double(totalWords) / 45.0
        if typingMinutes < 1 { return "0m" }
        if typingMinutes < 60 { return "\(Int(typingMinutes))m" }
        return "\(Int(typingMinutes / 60))h \(Int(typingMinutes.truncatingRemainder(dividingBy: 60)))m"
    }
}
