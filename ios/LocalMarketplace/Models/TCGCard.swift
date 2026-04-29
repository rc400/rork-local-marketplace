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
    let languageCode: String

    init(
        id: String,
        name: String,
        number: String,
        setName: String,
        setId: String,
        releaseDate: String,
        subtypes: [String],
        rarity: String,
        imageSmall: String,
        imageLarge: String,
        languageCode: String = "EN"
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.setName = setName
        self.setId = setId
        self.releaseDate = releaseDate
        self.subtypes = subtypes
        self.rarity = rarity
        self.imageSmall = imageSmall
        self.imageLarge = imageLarge
        self.languageCode = languageCode
    }

    var displayName: String {
        let cardIdentifier: String
        if number.isEmpty {
            cardIdentifier = ""
        } else if setId.isEmpty {
            cardIdentifier = number
        } else {
            cardIdentifier = "\(number)/\(setId)"
        }

        let baseName = cardIdentifier.isEmpty ? name : "\(name) · \(cardIdentifier)"

        if languageCode != "EN" {
            return "\(baseName) [\(languageCode)]"
        }
        return baseName
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
