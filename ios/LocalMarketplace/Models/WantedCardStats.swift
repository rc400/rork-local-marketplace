import Foundation

nonisolated struct WantedCardStats: Codable, Identifiable, Sendable {
    var id: String { tcgCardID }
    var tcgCardID: String
    var activeCount: Int
    var conditionCounts: [String: Int]
    var avgBidByCondition: [String: Double]
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case tcgCardID = "tcg_card_id"
        case activeCount = "active_count"
        case conditionCounts = "condition_counts"
        case avgBidByCondition = "avg_bid_by_condition"
        case updatedAt = "updated_at"
    }
}
