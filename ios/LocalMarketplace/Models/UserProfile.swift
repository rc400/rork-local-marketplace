import Foundation

nonisolated struct UserProfile: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var username: String
    var displayName: String? = nil
    var bio: String? = nil
    var avatarURL: String?
    var role: UserRole
    var isDeleted: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, role, bio
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
