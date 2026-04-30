import Foundation

nonisolated struct InquiryMessageData: Codable, Sendable {
    let items: [InquiryItemData]
    let note: String?
    let total: Double
    let intent: InquiryIntent?

    /// "buy" = buyer wants to purchase from vendor storefront
    /// "sell" = seller offering a card someone posted on wanted board
    var resolvedIntent: InquiryIntent {
        intent ?? .buy
    }
}

enum InquiryIntent: String, Codable, Sendable {
    case buy   // "I want to buy this from you"
    case sell  // "I have this card you're looking for"
}

nonisolated struct InquiryItemData: Codable, Sendable, Identifiable {
    let itemID: String
    let name: String
    let price: Double
    let condition: String?
    let quantity: Int
    let imageURL: String?

    var id: String { itemID }

    var formattedPrice: String {
        String(format: "$%.2f CAD", price)
    }
}
