import Foundation

nonisolated struct Block: Codable, Identifiable, Sendable {
    let id: String
    var blockerID: String
    var blockedID: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
        case createdAt = "created_at"
    }
}
