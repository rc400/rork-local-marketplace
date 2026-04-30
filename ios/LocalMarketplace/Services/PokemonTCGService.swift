import Foundation

@Observable
@MainActor
class PokemonTCGService {
    static let shared = PokemonTCGService()

    var searchResults: [TCGCard] = []
    var isSearching: Bool = false
    var searchError: String?
    var availableExpansions: [ScrydexExpansionInfo] { expansions }

    private var cache: [String: [TCGCard]] = [:]
    private var searchTask: Task<Void, Never>?
    private var expansions: [ScrydexExpansionInfo] = []
    private var expansionsLoadTask: Task<Void, Never>?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()

    private let baseURL = "https://api.scrydex.com/pokemon/v1/cards"
    private let expansionsURL = "https://api.scrydex.com/pokemon/v1/expansions"

    func debouncedSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await searchCards(query: trimmed)
        }
    }

    func searchCards(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        startExpansionLoadIfNeeded()

        let scrydexQuery = buildScrydexQuery(trimmed)
        let cacheKey = scrydexQuery.lowercased()
        if let cached = cache[cacheKey] {
            searchResults = cached
            searchError = nil
            return
        }

        isSearching = true
        searchError = nil

        let result = await fetchFromScrydex(scrydexQuery: scrydexQuery)
        switch result {
        case .success(let cards):
            cache[cacheKey] = cards
            searchResults = cards
            searchError = nil
        case .failure(let error):
            searchError = error.userMessage
        }

        isSearching = false
    }

    func loadExpansions() async {
        guard expansions.isEmpty else { return }

        guard let url = URL(string: expansionsURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_API_KEY, forHTTPHeaderField: "X-Api-Key")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_TEAM_ID, forHTTPHeaderField: "X-Team-ID")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(ScrydexExpansionsResponse.self, from: data)
            expansions = decoded.data
        } catch {
            return
        }
    }

    private func startExpansionLoadIfNeeded() {
        guard expansions.isEmpty, expansionsLoadTask == nil else { return }

        expansionsLoadTask = Task { [weak self] in
            await self?.loadExpansions()
            self?.expansionsLoadTask = nil
        }
    }

    private func fetchFromScrydex(scrydexQuery: String) async -> Result<[TCGCard], SearchError> {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: scrydexQuery),
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "orderBy", value: "-expansion.release_date")
        ]

        guard let url = components?.url else {
            return .failure(.invalidQuery)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_API_KEY, forHTTPHeaderField: "X-Api-Key")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_TEAM_ID, forHTTPHeaderField: "X-Team-ID")

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return .failure(.serverError)
            }

            if http.statusCode == 429 {
                return .failure(.rateLimited)
            }

            guard http.statusCode == 200 else {
                return .failure(.serverError)
            }

            let decoded = try JSONDecoder().decode(ScrydexResponse.self, from: data)
            let cards = decoded.data.map(mapScrydexCard)
            return .success(sortCardsBySearchPreference(cards))
        } catch is CancellationError {
            return .failure(.cancelled)
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout)
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            return .failure(.noInternet)
        } catch {
            return .failure(.decodingError)
        }
    }

    private func buildScrydexQuery(_ input: String) -> String {
        let normalized = input.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let tokens = normalized.split(separator: " ").map(String.init)

        guard !tokens.isEmpty else { return "\(input) -expansion.is_online_only:true" }

        var nameParts: [String] = []
        var numberPart: String?
        var expansionName: String?
        var subtype: String?

        for token in tokens {
            if let cardNumber = cardNumber(from: token) {
                numberPart = numberPart ?? cardNumber
            } else {
                nameParts.append(token)
            }
        }

        let expansionExtraction = extractExpansionName(from: nameParts)
        nameParts = expansionExtraction.remainingTokens
        expansionName = expansionExtraction.expansionName

        let subtypeExtraction = extractSubtype(from: nameParts)
        nameParts = subtypeExtraction.remainingTokens
        subtype = subtypeExtraction.subtype

        let nameQuery = nameParts.joined(separator: " ")

        var queryParts: [String] = []
        if !nameQuery.isEmpty {
            // Use wildcard for partial names (e.g. "pika" → name:pika*)
            // Use plain text for full names to also match Japanese translations
            let isFullName = PokemonNameSuggester.shared.containsExactName(nameQuery)
            if isFullName {
                queryParts.append(nameQuery)
            } else if nameQuery.contains(" ") {
                queryParts.append("name:\"\(nameQuery)*\"")
            } else {
                queryParts.append("name:\(nameQuery)*")
            }
        }
        if let subtype {
            queryParts.append("subtypes:\(subtype)")
        }
        if let num = numberPart {
            // Use wildcard prefix so "03" matches "TG03", "003", etc.
            queryParts.append("number:*\(num)")
        }
        if let expansionName {
            queryParts.append("expansion.name:\"\(expansionName)\"")
        }

        // Plain text search matches across translations, returning both EN and JA.
        var q = queryParts.joined(separator: " ")

        // Always exclude digital-only (TCG Pocket) cards
        q += " -expansion.is_online_only:true"

        return q
    }

    private func cardNumber(from token: String) -> String? {
        let rawNumber: String

        if token.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            rawNumber = token
        } else if token.range(of: #"^\d+/[\w]+$"#, options: .regularExpression) != nil {
            // "098/165" or "TG03/swsh11tg" — take part before slash
            rawNumber = String(token.split(separator: "/", maxSplits: 1).first ?? "")
        } else if token.range(of: #"^#\d+$"#, options: .regularExpression) != nil {
            rawNumber = String(token.dropFirst())
        } else {
            return nil
        }

        return rawNumber
    }

    private func extractExpansionName(from tokens: [String]) -> (remainingTokens: [String], expansionName: String?) {
        guard !tokens.isEmpty, !expansions.isEmpty else {
            return (tokens, nil)
        }

        for windowSize in stride(from: tokens.count, through: 1, by: -1) {
            guard tokens.count >= windowSize else { continue }

            for startIndex in 0...(tokens.count - windowSize) {
                let endIndex = startIndex + windowSize
                let candidate = tokens[startIndex..<endIndex].joined(separator: " ")

                if let expansion = expansions.first(where: { $0.name.caseInsensitiveCompare(candidate) == .orderedSame }) {
                    var remaining = tokens
                    remaining.removeSubrange(startIndex..<endIndex)
                    return (remaining, expansion.name)
                }
            }
        }

        return (tokens, nil)
    }

    private func extractSubtype(from tokens: [String]) -> (remainingTokens: [String], subtype: String?) {
        guard !tokens.isEmpty else {
            return (tokens, nil)
        }

        if tokens.count >= 2 {
            let suffix = tokens.suffix(2).joined(separator: " ")
            if suffix.caseInsensitiveCompare("TAG TEAM") == .orderedSame {
                var remaining = tokens
                remaining.removeLast(2)
                return (remaining, "\"tag team\"")
            }
        }

        guard let lastToken = tokens.last else {
            return (tokens, nil)
        }

        let normalized = lastToken.lowercased()
        let knownSubtypes = ["ex", "gx", "v", "vmax", "vstar", "break"]
        guard knownSubtypes.contains(normalized) else {
            return (tokens, nil)
        }

        if normalized == "v", tokens.count == 1 {
            return (tokens, nil)
        }

        var remaining = tokens
        remaining.removeLast()
        return (remaining, normalized)
    }

    private func sortCardsBySearchPreference(_ cards: [TCGCard]) -> [TCGCard] {
        cards.enumerated().sorted { lhs, rhs in
            let left = lhs.element
            let right = rhs.element

            if left.releaseDate != right.releaseDate {
                return left.releaseDate > right.releaseDate
            }

            let leftTier = rarityTier(left.rarity)
            let rightTier = rarityTier(right.rarity)
            if leftTier != rightTier {
                return leftTier < rightTier
            }

            let sameNameAndSet = left.name.localizedCaseInsensitiveCompare(right.name) == .orderedSame
                && left.setId.localizedCaseInsensitiveCompare(right.setId) == .orderedSame
            if sameNameAndSet && left.languageCode != right.languageCode {
                return left.languageCode == "EN"
            }

            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func rarityTier(_ rarity: String) -> Int {
        let normalized = rarity.lowercased()

        if normalized.isEmpty {
            return 5
        }

        let tier1 = [
            "illustration rare",
            "special art rare",
            "hyper rare",
            "secret rare",
            "art rare",
            "sar",
            "sir",
            "crown rare"
        ]
        if tier1.contains(where: { normalized.contains($0) }) {
            return 1
        }

        let tier2 = [
            "ultra rare",
            "double rare",
            "vmax",
            "vstar"
        ]
        if tier2.contains(where: { normalized.contains($0) }) {
            return 2
        }
        if containsRarityCode("v", in: normalized)
            || containsRarityCode("ex", in: normalized)
            || containsRarityCode("gx", in: normalized) {
            return 2
        }

        let tier3 = [
            "rare holo",
            "holo rare",
            "rare"
        ]
        if tier3.contains(where: { normalized.contains($0) }) {
            return 3
        }

        if normalized.contains("uncommon") {
            return 4
        }

        return 5
    }

    private func containsRarityCode(_ code: String, in rarity: String) -> Bool {
        rarity.range(
            of: #"(^|[^a-z0-9])\#(code)([^a-z0-9]|$)"#,
            options: .regularExpression
        ) != nil
    }

    func clearSearch() {
        searchResults = []
        searchError = nil
        isSearching = false
        searchTask?.cancel()
    }

    func fetchSetCards(expansionId: String) async -> [TCGCard] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: "expansion.id:\(expansionId) -expansion.is_online_only:true"),
            URLQueryItem(name: "pageSize", value: "250"),
            URLQueryItem(name: "orderBy", value: "number")
        ]

        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_API_KEY, forHTTPHeaderField: "X-Api-Key")
        request.setValue(Config.EXPO_PUBLIC_SCRYDEX_TEAM_ID, forHTTPHeaderField: "X-Team-ID")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

            let decoded = try JSONDecoder().decode(ScrydexResponse.self, from: data)
            return decoded.data.map(mapScrydexCard).sorted { lhs, rhs in
                compareCardNumbers(lhs.number, rhs.number)
            }
        } catch {
            return []
        }
    }

    private func mapScrydexCard(_ card: ScrydexCard) -> TCGCard {
        let frontImage = card.images?.first { $0.type == "front" } ?? card.images?.first
        let displayName: String
        if card.languageCode == "JA", let enName = card.translation?.en?.name {
            displayName = enName
        } else {
            displayName = card.name
        }
        return TCGCard(
            id: card.id,
            name: displayName,
            number: card.number ?? "",
            setName: card.expansion?.name ?? "",
            setId: card.expansion?.id ?? "",
            releaseDate: card.expansion?.releaseDate ?? "",
            subtypes: card.subtypes ?? [],
            rarity: card.rarity ?? "",
            imageSmall: frontImage?.small ?? "",
            imageLarge: frontImage?.large ?? "",
            languageCode: card.languageCode ?? "EN"
        )
    }

    private func compareCardNumbers(_ lhs: String, _ rhs: String) -> Bool {
        let leftNumber = Int(lhs.filter(\.isNumber)) ?? Int.max
        let rightNumber = Int(rhs.filter(\.isNumber)) ?? Int.max

        if leftNumber != rightNumber {
            return leftNumber < rightNumber
        }

        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}

nonisolated enum SearchError: Error, Sendable {
    case invalidQuery
    case serverError
    case rateLimited
    case networkError
    case timeout
    case noInternet
    case decodingError
    case cancelled

    var userMessage: String {
        switch self {
        case .invalidQuery: "Invalid search query."
        case .serverError: "Search failed. Try again."
        case .rateLimited: "Server busy. Please try again shortly."
        case .networkError: "Search failed. Check your connection."
        case .timeout: "Request timed out. Check your connection."
        case .noInternet: "No internet connection."
        case .decodingError: "Search failed. Try again."
        case .cancelled: ""
        }
    }
}

nonisolated struct ScrydexResponse: Codable, Sendable {
    let data: [ScrydexCard]
}

nonisolated struct ScrydexExpansionsResponse: Codable, Sendable {
    let data: [ScrydexExpansionInfo]
}

nonisolated struct ScrydexExpansionInfo: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let series: String?
    let releaseDate: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, series
        case releaseDate = "release_date"
    }
}

nonisolated struct ScrydexCard: Codable, Sendable {
    let id: String
    let name: String
    let number: String?
    let subtypes: [String]?
    let rarity: String?
    let images: [ScrydexImage]?
    let expansion: ScrydexExpansion?
    let languageCode: String?
    let translation: ScrydexTranslation?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, number, subtypes, rarity, images, expansion, translation
        case languageCode = "language_code"
    }
}

nonisolated struct ScrydexTranslation: Codable, Sendable {
    let en: ScrydexTranslationEN?
}

nonisolated struct ScrydexTranslationEN: Codable, Sendable {
    let name: String?
    let supertype: String?
    let subtypes: [String]?
    let types: [String]?
    let rarity: String?
}

nonisolated struct ScrydexImage: Codable, Sendable {
    let type: String?
    let small: String?
    let medium: String?
    let large: String?
}

nonisolated struct ScrydexExpansion: Codable, Sendable {
    let id: String?
    let name: String?
    let series: String?
    let releaseDate: String?
    let languageCode: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, series
        case releaseDate = "release_date"
        case languageCode = "language_code"
    }
}
