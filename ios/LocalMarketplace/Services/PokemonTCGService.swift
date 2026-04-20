import Foundation

@Observable
@MainActor
class PokemonTCGService {
    static let shared = PokemonTCGService()

    var searchResults: [TCGCard] = []
    var isSearching: Bool = false
    var searchError: String?

    private var cache: [String: [TCGCard]] = [:]
    private var searchTask: Task<Void, Never>?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()

    private let baseURL = "https://api.scrydex.com/pokemon/v1/cards"

    func debouncedSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
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

        let cacheKey = trimmed.lowercased()
        if let cached = cache[cacheKey] {
            searchResults = cached
            searchError = nil
            return
        }

        isSearching = true
        searchError = nil

        let result = await fetchFromScrydex(query: trimmed)
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

    private func fetchFromScrydex(query: String) async -> Result<[TCGCard], SearchError> {
        let scrydexQuery = buildScrydexQuery(query)

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: scrydexQuery),
            URLQueryItem(name: "pageSize", value: "30"),
            URLQueryItem(name: "select", value: "id,name,number,rarity,images,expansion")
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
            let cards = decoded.data.map { card in
                let frontImage = card.images?.first { $0.type == "front" } ?? card.images?.first
                return TCGCard(
                    id: card.id,
                    name: card.name,
                    number: card.number ?? "",
                    setName: card.expansion?.name ?? "",
                    setId: card.expansion?.id ?? "",
                    releaseDate: card.expansion?.releaseDate ?? "",
                    subtypes: card.subtypes ?? [],
                    rarity: card.rarity ?? "",
                    imageSmall: frontImage?.small ?? "",
                    imageLarge: frontImage?.large ?? ""
                )
            }
            return .success(cards)
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
            .lowercased()
        let tokens = normalized.split(separator: " ").map(String.init)

        guard !tokens.isEmpty else { return "name:\(input)*" }

        var nameParts: [String] = []
        var numberPart: String?

        let lastToken = tokens[tokens.count - 1]
        if tokens.count > 1, lastToken.contains(where: \.isNumber) {
            if lastToken.contains("/") {
                numberPart = String(lastToken.split(separator: "/").first ?? Substring(lastToken))
            } else {
                let stripped = lastToken.drop(while: { $0 == "0" })
                numberPart = stripped.isEmpty ? lastToken : String(stripped)
            }
            nameParts = Array(tokens.dropLast())
        } else {
            nameParts = tokens
        }

        let name = nameParts.joined(separator: " ")

        var q: String
        if name.contains(" ") {
            q = "name:\"\(name)*\""
        } else {
            q = "name:\(name)*"
        }

        if let num = numberPart {
            q += " number:\(num)"
        }

        return q
    }

    func clearSearch() {
        searchResults = []
        searchError = nil
        isSearching = false
        searchTask?.cancel()
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

nonisolated struct ScrydexCard: Codable, Sendable {
    let id: String
    let name: String
    let number: String?
    let subtypes: [String]?
    let rarity: String?
    let images: [ScrydexImage]?
    let expansion: ScrydexExpansion?
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

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, series
        case releaseDate = "release_date"
    }
}
