import Foundation

nonisolated struct EventDaySchedule: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var date: Date
    var startTime: Date
    var endTime: Date

    enum CodingKeys: String, CodingKey {
        case id, date
        case startTime = "start_time"
        case endTime = "end_time"
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }
}
