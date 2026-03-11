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

    @Query private var allStats: [ProductivityStat]

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
                        icon: "brain",
                        label: appState.isWhisperModelLoaded ? "Model Loaded" : "Model Not Loaded",
                        ok: appState.isWhisperModelLoaded
                    )
                    Spacer()
                }
                .padding(.horizontal)

                statsSection
                recentActivitySection
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Status Pill

    private func statusPill(icon: String, label: String, ok: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ok ? AirScriptTheme.statusSuccess.opacity(0.12) : AirScriptTheme.statusError.opacity(0.12))
        .foregroundStyle(ok ? AirScriptTheme.statusSuccess : AirScriptTheme.statusError)
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
    }

    private func transcriptRowContent(_ transcript: Transcript) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transcript.wasCommand ? "terminal" : "text.quote")
                .font(AirScriptTheme.fontSubtitle)
                .foregroundStyle(AirScriptTheme.accentMuted)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(transcript.text)
                    .font(AirScriptTheme.fontBodyPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let appName = transcript.appName {
                        StatusBadge(text: appName, style: .mono)
                    }
                    Text(formatDuration(transcript.duration))
                        .font(AirScriptTheme.fontCaption2)
                        .foregroundStyle(AirScriptTheme.textSecondary)
                    Text("\(transcript.wordCount) words")
                        .font(AirScriptTheme.fontCaption2)
                        .foregroundStyle(AirScriptTheme.textSecondary)
                }
            }

            Spacer()

            Text(transcript.createdAt, style: .relative)
                .font(AirScriptTheme.fontCaption2)
                .foregroundStyle(AirScriptTheme.textTertiary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcript.text, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                modelContext.delete(transcript)
            }
        }
    }

    // MARK: - Computed Stats

    private var todayStats: ProductivityStat? {
        let today = Calendar.current.startOfDay(for: Date())
        return allStats.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var todayWords: Int {
        todayStats?.wordsTranscribed ?? 0
    }

    private var todaySessions: Int {
        todayStats?.sessionsCount ?? 0
    }

    private var weekWords: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allStats.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.wordsTranscribed }
    }

    private var totalSessions: Int {
        allStats.reduce(0) { $0 + $1.sessionsCount }
    }

    private var timeSaved: String {
        let totalWords = allStats.reduce(0) { $0 + $1.wordsTranscribed }
        let typingMinutes = Double(totalWords) / 45.0
        if typingMinutes < 1 { return "0m" }
        if typingMinutes < 60 { return "\(Int(typingMinutes))m" }
        return "\(Int(typingMinutes / 60))h \(Int(typingMinutes.truncatingRemainder(dividingBy: 60)))m"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration))s"
        }
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return "\(mins)m \(secs)s"
    }
}
