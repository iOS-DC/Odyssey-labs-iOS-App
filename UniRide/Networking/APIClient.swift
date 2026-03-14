import Foundation

enum APIError: LocalizedError {
    case backendDisabled
    case missingBaseURL
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .backendDisabled:
            return "Real backend is disabled for this build."
        case .missingBaseURL:
            return "Backend base URL is not configured."
        case .invalidResponse:
            return "Invalid server response."
        case .server(_, let message):
            return message
        }
    }
}

struct APIEndpoint {
    var path: String
    var method: String = "GET"
    var headers: [String: String] = [:]
    var body: Data? = nil
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        guard BackendConfig.useRealBackend else { throw APIError.backendDisabled }
        guard let baseURL = BackendConfig.baseURL else { throw APIError.missingBaseURL }

        let url = try Self.buildURL(baseURL: baseURL, path: endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let anonKey = BackendConfig.supabaseAnonKey, !anonKey.isEmpty {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }

        if let authToken = SessionStore.shared.accessToken ?? BackendConfig.supabaseAnonKey, !authToken.isEmpty {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let serverMessage: String = {
                if let payload = try? decoder.decode(ServerErrorPayload.self, from: data) {
                    return payload.message
                }
                return HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }()
            throw APIError.server(status: http.statusCode, message: serverMessage)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try decoder.decode(T.self, from: data)
    }

    func encodeBody<T: Encodable>(_ payload: T) throws -> Data {
        try encoder.encode(payload)
    }

    private static func buildURL(baseURL: URL, path: String) throws -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }

        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let pieces = trimmed.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let rawPath = pieces.first.map(String.init) ?? ""
        let query = pieces.count > 1 ? String(pieces[1]) : nil

        let normalizedPath = rawPath.hasPrefix("/") ? String(rawPath.dropFirst()) : rawPath
        let joined = baseURL.appendingPathComponent(normalizedPath)

        guard var components = URLComponents(url: joined, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidResponse
        }
        if let query, !query.isEmpty {
            components.percentEncodedQuery = query
        }
        guard let finalURL = components.url else {
            throw APIError.invalidResponse
        }
        return finalURL
    }
}

private struct ServerErrorPayload: Decodable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
        case errorDescription = "error_description"
        case msg
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message =
            (try? container.decode(String.self, forKey: .message)) ??
            (try? container.decode(String.self, forKey: .errorDescription)) ??
            (try? container.decode(String.self, forKey: .msg)) ??
            "Server error"
    }
}

struct EmptyResponse: Decodable {}
