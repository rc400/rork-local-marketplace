import Foundation

nonisolated struct VendorApplication: Codable, Identifiable, Sendable {
    let id: String
    var userID: String
    var status: ApplicationStatus
    var contactEmail: String
    var contactPhone: String
    var answersJSON: [String: String]
    var adminNote: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case userID = "user_id"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case answersJSON = "answers_json"
        case adminNote = "admin_note"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
