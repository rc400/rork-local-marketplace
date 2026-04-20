import Foundation

nonisolated struct Vendor: Codable, Identifiable, Sendable, Hashable {
    var userID: String
    var storeName: String
    var bio: String?
    var categories: [String]
    var meetupAddress: String
    var meetupSpotNote: String?
    var profileImageURL: String?
    var coverImageURL: String?
    var lat: Double?
    var lng: Double?
    var approved: Bool
    var isDisabled: Bool
    var isActive: Bool
    var activeUntil: Date?
    var createdAt: Date?
    var updatedAt: Date?

    var id: String { userID }

    enum CodingKeys: String, CodingKey {
        case bio, categories, lat, lng, approved
        case userID = "user_id"
        case storeName = "store_name"
        case meetupAddress = "meetup_address"
        case meetupSpotNote = "meetup_spot_note"
        case profileImageURL = "profile_image_url"
        case coverImageURL = "cover_image_url"
        case isDisabled = "is_disabled"
        case isActive = "is_active"
        case activeUntil = "active_until"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var hasRequiredFields: Bool {
        !storeName.isEmpty && !meetupAddress.isEmpty && !categories.isEmpty
    }

    var isExpired: Bool {
        guard let until = activeUntil else { return false }
        return Date() > until
    }
}
