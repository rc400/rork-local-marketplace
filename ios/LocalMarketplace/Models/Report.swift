import Foundation

nonisolated struct Report: Codable, Identifiable, Sendable {
    let id: String
    var reporterID: String
    var reportedUserID: String?
    var reportedVendorID: String?
    var conversationID: String?
    var reason: String
    var details: String?
    var status: ReportStatus
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, reason, details, status
        case reporterID = "reporter_id"
        case reportedUserID = "reported_user_id"
        case reportedVendorID = "reported_vendor_id"
        case conversationID = "conversation_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
