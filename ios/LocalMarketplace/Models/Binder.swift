import Foundation

nonisolated struct Binder: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var vendorID: String
    var name: String
    var sortOrder: Int
    var isHidden: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case vendorID = "vendor_id"
        case sortOrder = "sort_order"
        case isHidden = "is_hidden"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
