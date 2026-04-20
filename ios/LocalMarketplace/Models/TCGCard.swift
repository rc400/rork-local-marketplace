import Foundation

nonisolated struct TCGCard: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let number: String
    let setName: String
    let setId: String
    let releaseDate: String
    let subtypes: [String]
    let rarity: String
    let imageSmall: String
    let imageLarge: String

    var displayName: String {
        "\(name) \(number)"
    }

    var smallImageURL: URL? {
        guard !imageSmall.isEmpty else { return nil }
        return URL(string: imageSmall)
    }

    var largeImageURL: URL? {
        guard !imageLarge.isEmpty else { return nil }
        return URL(string: imageLarge)
    }
}
