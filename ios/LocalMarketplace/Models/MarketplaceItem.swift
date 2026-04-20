import Foundation

nonisolated struct MarketplaceItem: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var vendorID: String
    var binderID: String?
    var name: String
    var priceCAD: Double
    var category: ItemCategory
    var condition: ItemCondition?
    var note: String?
    var status: ItemStatus
    var image1URL: String?
    var image2URL: String?
    var tcgCardID: String?
    var tcgCardName: String?
    var tcgCardNumber: String?
    var tcgCardDisplay: String?
    var tcgCardImageURL: String?
    var slabGrade: Int?
    var slabCompany: String?
    var slabCompanyOther: String?
    var quantity: Int = 1
    var soldAt: Date?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, category, condition, note, status, quantity
        case vendorID = "vendor_id"
        case binderID = "binder_id"
        case priceCAD = "price_cad"
        case image1URL = "image1_url"
        case image2URL = "image2_url"
        case tcgCardID = "tcg_card_id"
        case tcgCardName = "tcg_card_name"
        case tcgCardNumber = "tcg_card_number"
        case tcgCardDisplay = "tcg_card_display"
        case tcgCardImageURL = "tcg_card_image_url"
        case slabGrade = "slab_grade"
        case slabCompany = "slab_company"
        case slabCompanyOther = "slab_company_other"
        case soldAt = "sold_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var canBeActivated: Bool {
        switch category {
        case .single:
            guard tcgCardID != nil, tcgCardImageURL != nil else { return false }
            if let cond = condition, cond.requiresImages {
                return image1URL != nil && image2URL != nil
            }
            return true
        case .slab:
            guard tcgCardID != nil, tcgCardImageURL != nil, slabGrade != nil, slabCompany != nil else { return false }
            return true
        case .accessory:
            return image1URL != nil
        case .sealed:
            return true
        }
    }

    var displayName: String {
        if category == .single || category == .slab, let display = tcgCardDisplay, !display.isEmpty {
            return display
        }
        return name
    }

    var primaryImageURL: String? {
        if (category == .single || category == .slab), let cardImage = tcgCardImageURL {
            return cardImage
        }
        return image1URL
    }

    var formattedPrice: String {
        String(format: "$%.2f CAD", priceCAD)
    }

    var quantityLabel: String? {
        guard quantity > 0 else { return nil }
        if quantity == 1 { return "Only 1 left" }
        return "Qty: \(quantity)"
    }

    var requiresDamagePhotos: Bool {
        guard category == .single, let cond = condition else { return false }
        return cond.requiresImages
    }

    var slabDisplayLabel: String? {
        guard category == .slab, let grade = slabGrade, let company = slabCompany else { return nil }
        let companyName: String
        if company == SlabCompany.other.rawValue, let other = slabCompanyOther, !other.isEmpty {
            companyName = other
        } else {
            companyName = company
        }
        return "\(companyName) \(grade)"
    }
}
