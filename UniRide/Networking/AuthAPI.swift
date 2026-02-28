import Foundation

struct AuthStartEmailRequest: Encodable {
    let email: String
}

struct AuthVerifyEmailRequest: Encodable {
    let email: String
    let code: String
}

struct AuthStartPhoneRequest: Encodable {
    let phone: String
}

struct AuthVerifyPhoneRequest: Encodable {
    let phone: String
    let code: String
}

struct AuthVerifyEmailResponse: Decodable {
    let existingUser: Bool
    let user: AuthRemoteUser?
    let accessToken: String?
}

struct AuthVerifyPhoneResponse: Decodable {
    let verified: Bool
}

struct AuthRemoteUser: Decodable {
    let id: String?
    let email: String
    let phone: String?
    let isEmailVerified: Bool?
    let isPhoneVerified: Bool?
    let fullName: String?
    let role: String?
    let courseName: String?
    let year: Int?
    let employeeID: String?
    let photoURL: String?
}

final class AuthAPI {
    static let shared = AuthAPI()

    private let client: APIClient
    private let sessionStore: SessionStore

    init(client: APIClient = .shared, sessionStore: SessionStore = .shared) {
        self.client = client
        self.sessionStore = sessionStore
    }

    func startEmailVerification(email: String) async throws {
        let body = try client.encodeBody(AuthStartEmailRequest(email: email))
        let endpoint = APIEndpoint(path: "/auth/email/start", method: "POST", body: body)
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func verifyEmailOTP(email: String, code: String) async throws -> AuthVerifyEmailResponse {
        let body = try client.encodeBody(AuthVerifyEmailRequest(email: email, code: code))
        let endpoint = APIEndpoint(path: "/auth/email/verify", method: "POST", body: body)
        let response: AuthVerifyEmailResponse = try await client.send(endpoint, as: AuthVerifyEmailResponse.self)
        if let token = response.accessToken, !token.isEmpty {
            sessionStore.accessToken = token
        }
        return response
    }

    func startPhoneVerification(phone: String) async throws {
        let body = try client.encodeBody(AuthStartPhoneRequest(phone: phone))
        let endpoint = APIEndpoint(path: "/auth/phone/start", method: "POST", body: body)
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func verifyPhoneOTP(phone: String, code: String) async throws -> Bool {
        let body = try client.encodeBody(AuthVerifyPhoneRequest(phone: phone, code: code))
        let endpoint = APIEndpoint(path: "/auth/phone/verify", method: "POST", body: body)
        let response: AuthVerifyPhoneResponse = try await client.send(endpoint, as: AuthVerifyPhoneResponse.self)
        return response.verified
    }
}

final class SessionStore {
    static let shared = SessionStore()

    private let key = "session.accessToken"
    private init() {}

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
