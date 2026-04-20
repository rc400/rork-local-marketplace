import Foundation

nonisolated enum UserRole: String, Codable, Sendable, CaseIterable {
    case buyer
    case vendor
    case admin

    var displayName: String {
        switch self {
        case .buyer: "Buyer"
        case .vendor: "Vendor"
        case .admin: "Admin"
        }
    }
}

nonisolated enum ApplicationStatus: String, Codable, Sendable {
    case pending
    case approved
    case rejected
}

nonisolated enum ItemCategory: String, Codable, Sendable, CaseIterable {
    case sealed
    case single
    case slab
    case accessory

    var displayName: String {
        switch self {
        case .sealed: "Sealed"
        case .single: "Single"
        case .slab: "Slab"
        case .accessory: "Accessory"
        }
    }

    var icon: String {
        switch self {
        case .sealed: "shippingbox.fill"
        case .single: "rectangle.portrait.fill"
        case .slab: "rectangle.fill"
        case .accessory: "tag.fill"
        }
    }

    var hasCondition: Bool {
        self == .single
    }
}

nonisolated enum ItemCondition: String, Codable, Sendable, CaseIterable {
    case NM
    case LP
    case MP
    case HP
    case DMG

    var displayName: String {
        switch self {
        case .NM: "Near Mint"
        case .LP: "Lightly Played"
        case .MP: "Moderately Played"
        case .HP: "Heavily Played"
        case .DMG: "Damaged"
        }
    }

    var shortName: String { rawValue }
    var requiresImages: Bool { self != .NM }
}

nonisolated enum ItemStatus: String, Codable, Sendable {
    case draft
    case active
    case inactive
    case sold
}

nonisolated enum ReportStatus: String, Codable, Sendable {
    case open
    case closed
}

nonisolated enum ActiveDuration: Int, CaseIterable, Sendable {
    case fourHours = 4
    case sixHours = 6
    case eightHours = 8

    var displayName: String { "\(rawValue)h" }
    var fullDisplayName: String { "\(rawValue) hours" }
}

nonisolated enum CardConditionOption: String, Codable, Sendable, CaseIterable, Identifiable {
    case NM
    case LP
    case MP
    case HP
    case DMG
    case Graded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .NM: "Near Mint"
        case .LP: "Lightly Played"
        case .MP: "Moderately Played"
        case .HP: "Heavily Played"
        case .DMG: "Damaged"
        case .Graded: "Graded"
        }
    }

    var shortName: String { rawValue }
}

nonisolated enum GradeValue: String, Codable, Sendable, CaseIterable, Identifiable {
    case ten = "10"
    case ninePointFive = "9.5"
    case nine = "9"
    case eightPointFive = "8.5"
    case eight = "8"
    case sevenPointFive = "7.5"
    case seven = "7"
    case sixPointFive = "6.5"
    case six = "6"
    case five = "5"
    case four = "4"
    case three = "3"
    case two = "2"
    case one = "1"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

nonisolated enum SlabCompany: String, Codable, Sendable, CaseIterable, Identifiable {
    case PSA
    case BGS
    case CGC
    case SGC
    case ACE
    case TAG
    case MNT
    case KSA
    case other = "Other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .PSA: "PSA"
        case .BGS: "BGS (Beckett)"
        case .CGC: "CGC"
        case .SGC: "SGC"
        case .ACE: "ACE"
        case .TAG: "TAG"
        case .MNT: "MNT"
        case .KSA: "KSA"
        case .other: "Other"
        }
    }

    var shortName: String {
        switch self {
        case .BGS: "BGS"
        default: rawValue
        }
    }
}
