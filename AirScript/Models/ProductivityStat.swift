import Foundation
import SwiftData

@Model
final class ProductivityStat {
    var date: Date
    var wordsTranscribed: Int
    var sessionsCount: Int
    var totalDurationSeconds: Double
    var commandsExecuted: Int

    init(date: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.wordsTranscribed = 0
        self.sessionsCount = 0
        self.totalDurationSeconds = 0
        self.commandsExecuted = 0
    }
}
