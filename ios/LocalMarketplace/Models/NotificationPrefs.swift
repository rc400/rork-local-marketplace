import Foundation

nonisolated struct NotificationPrefs: Codable, Sendable {
    var userID: String
    var pushEnabled: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case pushEnabled = "push_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
