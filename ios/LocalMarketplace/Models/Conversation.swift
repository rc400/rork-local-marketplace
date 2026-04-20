import Foundation

nonisolated struct Conversation: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var participant1ID: String
    var participant2ID: String
    var createdAt: Date?
    var updatedAt: Date?

    var lastMessage: Message?
    var otherUserName: String?
    var otherUserAvatar: String?

    func otherParticipantID(currentUserID: String) -> String {
        participant1ID == currentUserID ? participant2ID : participant1ID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case participant1ID = "participant1_id"
        case participant2ID = "participant2_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
