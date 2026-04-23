import Foundation

nonisolated struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

nonisolated struct AuthUser: Codable, Sendable {
    let id: String
    let email: String?
}

nonisolated struct AuthSignUpResponse: Codable, Sendable {
    let id: String
    let email: String?
    let role: String?
    let confirmationSentAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case confirmationSentAt = "confirmation_sent_at"
    }
}

nonisolated struct AuthSignUpWrappedResponse: Codable, Sendable {
    let user: AuthSignUpResponse
}

nonisolated enum SignUpResult: Sendable {
    case session(AuthSession)
    case userCreated(userID: String)
}

nonisolated enum SupabaseAPIError: Error, LocalizedError, Sendable {
    case notConfigured
    case invalidURL
    case httpError(Int, String)
    case decodingError(String)
    case notAuthenticated
    case storageError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Supabase is not configured"
        case .invalidURL: "Invalid URL"
        case .httpError(let code, let msg): "HTTP \(code): \(msg)"
        case .decodingError(let msg): "Decoding error: \(msg)"
        case .notAuthenticated: "Not authenticated"
        case .storageError(let msg): "Storage error: \(msg)"
        }
    }
}

@Observable
@MainActor
class SupabaseClient {
    static let shared = SupabaseClient()

    private enum SessionStorageKeys {
        static let accessToken = "lm_access_token"
        static let refreshToken = "lm_refresh_token"
        static let userID = "lm_user_id"
    }

    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var currentUserID: String?

    var baseURL: String { Config.EXPO_PUBLIC_SUPABASE_URL }
    var anonKey: String { Config.EXPO_PUBLIC_SUPABASE_ANON_KEY }
    var isConfigured: Bool { !baseURL.isEmpty && !anonKey.isEmpty }

    private let urlSession = URLSession.shared

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let fmtFrac = ISO8601DateFormatter()
        fmtFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtPlain = ISO8601DateFormatter()
        fmtPlain.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let d = fmtFrac.date(from: str) { return d }
            if let d = fmtPlain.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date: \(str)")
        }
        return decoder
    }

    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(fmt.string(from: date))
        }
        return encoder
    }

    func signUp(email: String, password: String, metadata: [String: String] = [:]) async throws -> SignUpResult {
        guard isConfigured else { throw SupabaseAPIError.notConfigured }
        let body: [String: Any] = ["email": email, "password": password, "data": metadata]
        let data = try await request(path: "/auth/v1/signup", method: "POST", body: try JSONSerialization.data(withJSONObject: body))

        if let session = try? Self.jsonDecoder.decode(AuthSession.self, from: data) {
            accessToken = session.accessToken
            refreshToken = session.refreshToken
            currentUserID = session.user.id
            persistSession()
            return .session(session)
        }

        if let userResponse = try? Self.jsonDecoder.decode(AuthSignUpResponse.self, from: data) {
            currentUserID = userResponse.id
            return .userCreated(userID: userResponse.id)
        }

        if let wrapped = try? Self.jsonDecoder.decode(AuthSignUpWrappedResponse.self, from: data) {
            currentUserID = wrapped.user.id
            return .userCreated(userID: wrapped.user.id)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = json["id"] as? String ?? (json["user"] as? [String: Any])?["id"] as? String {
            currentUserID = id
            return .userCreated(userID: id)
        }

        throw SupabaseAPIError.decodingError("Unexpected sign-up response")
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        guard isConfigured else { throw SupabaseAPIError.notConfigured }
        let body = ["email": email, "password": password]
        let data = try await request(path: "/auth/v1/token?grant_type=password", method: "POST", body: try JSONEncoder().encode(body))
        let session = try Self.jsonDecoder.decode(AuthSession.self, from: data)
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        currentUserID = session.user.id
        persistSession()
        return session
    }

    func signOut() async throws {
        if let token = accessToken {
            _ = try? await request(path: "/auth/v1/logout", method: "POST", body: nil, extraHeaders: ["Authorization": "Bearer \(token)"])
        }
        accessToken = nil
        refreshToken = nil
        currentUserID = nil
        clearSession()
    }

    func restoreSession() -> Bool {
        let defaults = UserDefaults.standard
        guard
            let accessToken = defaults.string(forKey: SessionStorageKeys.accessToken),
            let refreshToken = defaults.string(forKey: SessionStorageKeys.refreshToken),
            let currentUserID = defaults.string(forKey: SessionStorageKeys.userID)
        else {
            return false
        }

        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.currentUserID = currentUserID
        return true
    }

    func select<T: Decodable & Sendable>(_ table: String, columns: String = "*", filters: [String] = [], order: String? = nil) async throws -> [T] {
        var qi = [URLQueryItem(name: "select", value: columns)]
        for f in filters {
            let parts = f.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { qi.append(URLQueryItem(name: String(parts[0]), value: String(parts[1]))) }
        }
        if let order { qi.append(URLQueryItem(name: "order", value: order)) }
        let data = try await request(path: "/rest/v1/\(table)\(queryString(qi))", method: "GET", body: nil)
        return try Self.jsonDecoder.decode([T].self, from: data)
    }

    func selectSingle<T: Decodable & Sendable>(_ table: String, columns: String = "*", filters: [String] = []) async throws -> T? {
        let results: [T] = try await select(table, columns: columns, filters: filters)
        return results.first
    }

    func insert(_ table: String, body: Data) async throws -> Data {
        try await request(path: "/rest/v1/\(table)", method: "POST", body: body, extraHeaders: ["Prefer": "return=representation"])
    }

    func update(_ table: String, body: Data, filters: [String]) async throws {
        var qi: [URLQueryItem] = []
        for f in filters {
            let parts = f.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { qi.append(URLQueryItem(name: String(parts[0]), value: String(parts[1]))) }
        }
        _ = try await request(path: "/rest/v1/\(table)\(queryString(qi))", method: "PATCH", body: body, extraHeaders: ["Prefer": "return=minimal"])
    }

    func delete(_ table: String, filters: [String]) async throws {
        var qi: [URLQueryItem] = []
        for f in filters {
            let parts = f.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { qi.append(URLQueryItem(name: String(parts[0]), value: String(parts[1]))) }
        }
        _ = try await request(path: "/rest/v1/\(table)\(queryString(qi))", method: "DELETE", body: nil)
    }

    func uploadFile(bucket: String, path: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        guard isConfigured else { throw SupabaseAPIError.notConfigured }
        let url = URL(string: "\(baseURL)/storage/v1/object/\(bucket)/\(path)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = data

        let (_, response) = try await urlSession.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw SupabaseAPIError.invalidURL }

        if http.statusCode >= 400 {
            throw SupabaseAPIError.storageError("Upload failed with status \(http.statusCode)")
        }

        return publicURL(bucket: bucket, path: path)
    }

    func publicURL(bucket: String, path: String) -> String {
        "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)"
    }

    private func request(path: String, method: String, body: Data?, extraHeaders: [String: String] = [:]) async throws -> Data {
        guard isConfigured else { throw SupabaseAPIError.notConfigured }
        guard let url = URL(string: "\(baseURL)\(path)") else { throw SupabaseAPIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = body
        let (data, response) = try await urlSession.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw SupabaseAPIError.invalidURL }
        if http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseAPIError.httpError(http.statusCode, msg)
        }
        return data
    }

    private func queryString(_ items: [URLQueryItem]) -> String {
        guard !items.isEmpty else { return "" }
        var c = URLComponents()
        c.queryItems = items
        return "?" + (c.query ?? "")
    }

    private func persistSession() {
        let defaults = UserDefaults.standard
        defaults.set(accessToken, forKey: SessionStorageKeys.accessToken)
        defaults.set(refreshToken, forKey: SessionStorageKeys.refreshToken)
        defaults.set(currentUserID, forKey: SessionStorageKeys.userID)
    }

    private func clearSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: SessionStorageKeys.accessToken)
        defaults.removeObject(forKey: SessionStorageKeys.refreshToken)
        defaults.removeObject(forKey: SessionStorageKeys.userID)
    }
}
