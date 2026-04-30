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

extension Message {
    static let inquiryPrefix = "[INQUIRY]"

    var isInquiry: Bool {
        body.hasPrefix(Self.inquiryPrefix)
    }

    var inquiryData: InquiryMessageData? {
        guard isInquiry else { return nil }
        let jsonString = String(body.dropFirst(Self.inquiryPrefix.count))
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(InquiryMessageData.self, from: data)
    }
}
