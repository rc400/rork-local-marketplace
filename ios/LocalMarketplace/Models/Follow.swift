import Foundation

nonisolated struct Follow: Codable, Identifiable, Sendable {
    let id: String
    var followerID: String
    var vendorID: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case followerID = "follower_id"
        case vendorID = "vendor_id"
        case createdAt = "created_at"
    }
}
