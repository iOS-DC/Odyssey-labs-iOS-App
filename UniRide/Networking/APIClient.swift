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

        let normalizedPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let url = baseURL.appendingPathComponent(normalizedPath)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
}

private struct ServerErrorPayload: Decodable {
    let message: String
}

struct EmptyResponse: Decodable {}
