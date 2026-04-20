import Foundation

nonisolated struct Message: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var conversationID: String
    var senderID: String
    var body: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, body
        case conversationID = "conversation_id"
        case senderID = "sender_id"
        case createdAt = "created_at"
    }
}
