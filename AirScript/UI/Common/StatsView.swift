import SwiftUI

struct StatsView: View {
    let stats: StatsCalculator.Stats

    var body: some View {
        VStack(spacing: 12) {
            Text("Productivity")
                .font(AirScriptTheme.fontSectionTitle)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                statCard("Today", value: "\(stats.wordsToday)", unit: "words")
                statCard("This Week", value: "\(stats.wordsThisWeek)", unit: "words")
                statCard("All Time", value: "\(stats.wordsAllTime)", unit: "words")
                statCard("Sessions", value: "\(stats.sessionsToday)", unit: "today")
                statCard("Avg Speed", value: String(format: "%.0f", stats.averageWPM), unit: "WPM")
                statCard("Time Saved", value: formatTimeSaved(stats.estimatedTimeSaved), unit: "")
            }
        }
        .padding()
    }

    private func statCard(_ title: String, value: String, unit: String) -> some View {
        GlassCard(hoverLift: true) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AirScriptTheme.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(unit.isEmpty ? title : "\(title)")
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textSecondary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(AirScriptTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatTimeSaved(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
