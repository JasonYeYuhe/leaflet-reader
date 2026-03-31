import SwiftData
import Foundation

@Model
final class ReadingSession {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date?
    var durationSeconds: Int = 0
    var startPage: Int = 0
    var endPage: Int = 0
    var book: Book?

    var isActive: Bool {
        endTime == nil
    }

    var formattedDuration: String {
        let total = durationSeconds
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }

    init(startPage: Int) {
        self.id = UUID()
        self.startTime = Date()
        self.startPage = startPage
    }

    func stop(endPage: Int) {
        self.endTime = Date()
        self.endPage = endPage
        self.durationSeconds = Int(Date().timeIntervalSince(startTime))
    }
}
