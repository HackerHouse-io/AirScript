import SwiftUI
import SwiftData

struct HomePage: View {
    @Environment(AppState.self) private var appState
    @Query(
        filter: #Predicate<Transcript> { !$0.isArchived },
        sort: \Transcript.createdAt,
        order: .reverse
    )
    private var recentTranscripts: [Transcript]

    @Query private var allStats: [ProductivityStat]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroBanner
                statsSection
                recentActivitySection
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to AirScript")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Your voice, your words. Dictate naturally and let AI handle the rest — punctuation, grammar, and formatting, all processed locally on your Mac.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.3))
            }

            // Quick status
            HStack(spacing: 16) {
                statusPill(
                    icon: "mic.fill",
                    label: appState.hasMicrophonePermission ? "Mic Ready" : "Mic Needed",
                    ok: appState.hasMicrophonePermission
                )
                statusPill(
                    icon: "hand.raised.fill",
                    label: appState.hasAccessibilityPermission ? "Accessibility OK" : "Accessibility Needed",
                    ok: appState.hasAccessibilityPermission
                )
                statusPill(
                    icon: "brain",
                    label: appState.isWhisperModelLoaded ? "Model Loaded" : "Model Not Loaded",
                    ok: appState.isWhisperModelLoaded
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statusPill(icon: String, label: String, ok: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ok ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                statCard(value: "\(todayWords)", label: "Words Today", icon: "character.cursor.ibeam")
                statCard(value: "\(weekWords)", label: "This Week", icon: "calendar")
                statCard(value: "\(todaySessions)", label: "Sessions Today", icon: "mic.fill")
                statCard(value: timeSaved, label: "Time Saved", icon: "clock.arrow.circlepath")
            }
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transcriptions")
                    .font(.headline)
                Spacer()
                Text("\(recentTranscripts.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if recentTranscripts.isEmpty {
                emptyState
            } else {
                VStack(spacing: 1) {
                    ForEach(recentTranscripts.prefix(20)) { transcript in
                        transcriptRow(transcript)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func transcriptRow(_ transcript: Transcript) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transcript.wasCommand ? "terminal" : "text.quote")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(transcript.text)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let appName = transcript.appName {
                        Text(appName)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    Text(formatDuration(transcript.duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(transcript.wordCount) words")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(transcript.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcript.text, forType: .string)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No transcriptions yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Hold fn to start dictating")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allStats.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.wordsTranscribed }
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
