import Foundation
import CoreLocation

nonisolated struct WantedCard: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var userID: String
    var slotIndex: Int
    var tcgCardID: String
    var tcgCardName: String
    var tcgCardImageURL: String
    var tcgCardNumber: String
    var tcgCardSetName: String
    var bidPrice: Double
    var conditions: [String]
    var gradingCompany: String?
    var grades: [String]?
    var notes: String?
    var latitude: Double
    var longitude: Double
    var createdAt: Date?
    var updatedAt: Date?

    var ownerUsername: String?
    var ownerAvatarURL: String?

    var isGraded: Bool {
        conditions.contains("Graded")
    }

    var conditionsDisplay: String {
        conditions.joined(separator: ", ")
    }

    var gradesDisplay: String {
        guard let grades, !grades.isEmpty else { return "" }
        return grades.joined(separator: ", ")
    }

    func distance(from coordinate: CLLocationCoordinate2D) -> Double {
        let cardLocation = CLLocation(latitude: latitude, longitude: longitude)
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return cardLocation.distance(from: userLocation) / 1000.0
    }

    enum CodingKeys: String, CodingKey {
        case id, conditions, grades, notes, latitude, longitude
        case userID = "user_id"
        case slotIndex = "slot_index"
        case tcgCardID = "tcg_card_id"
        case tcgCardName = "tcg_card_name"
        case tcgCardImageURL = "tcg_card_image_url"
        case tcgCardNumber = "tcg_card_number"
        case tcgCardSetName = "tcg_card_set_name"
        case bidPrice = "bid_price"
        case gradingCompany = "grading_company"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WantedCard, rhs: WantedCard) -> Bool {
        lhs.id == rhs.id
    }
}
