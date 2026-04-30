import Foundation

nonisolated struct InquiryMessageData: Codable, Sendable {
    let items: [InquiryItemData]
    let note: String?
    let total: Double
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
