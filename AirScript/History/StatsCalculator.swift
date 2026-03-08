import Foundation
import SwiftData
import os

final class StatsCalculator {
    private let logger = Logger.general

    struct Stats {
        let wordsToday: Int
        let wordsThisWeek: Int
        let wordsAllTime: Int
        let sessionsToday: Int
        let averageWPM: Double
        let estimatedTimeSaved: TimeInterval // vs 45 WPM typing
    }

    func calculate(in context: ModelContext) -> Stats {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        let allTranscripts = fetchAll(in: context)
        let todayTranscripts = allTranscripts.filter { $0.createdAt >= startOfToday }
        let weekTranscripts = allTranscripts.filter { $0.createdAt >= startOfWeek }

        let wordsToday = todayTranscripts.reduce(0) { $0 + $1.wordCount }
        let wordsThisWeek = weekTranscripts.reduce(0) { $0 + $1.wordCount }
        let wordsAllTime = allTranscripts.reduce(0) { $0 + $1.wordCount }
        let sessionsToday = todayTranscripts.count

        let totalDuration = allTranscripts.reduce(0.0) { $0 + $1.duration }
        let averageWPM = totalDuration > 0 ? Double(wordsAllTime) / (totalDuration / 60.0) : 0

        // Time saved: typing at 45 WPM vs dictation
        let typingTime = Double(wordsAllTime) / 45.0 * 60.0 // seconds
        let timeSaved = max(0, typingTime - totalDuration)

        return Stats(
            wordsToday: wordsToday,
            wordsThisWeek: wordsThisWeek,
            wordsAllTime: wordsAllTime,
            sessionsToday: sessionsToday,
            averageWPM: averageWPM,
            estimatedTimeSaved: timeSaved
        )
    }

    private func fetchAll(in context: ModelContext) -> [Transcript] {
        let descriptor = FetchDescriptor<Transcript>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
