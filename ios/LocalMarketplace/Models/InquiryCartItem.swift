import Foundation

struct InquiryCartItem: Identifiable, Hashable {
    let item: MarketplaceItem
    var quantity: Int

    var id: String { item.id }
}
