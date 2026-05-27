import Foundation

final class EventAdminSession {
    static let shared = EventAdminSession()

    static let email = "admin@chitkara.edu.in"
    static let otp = "202606"

    private let sessionKey = "event_admin_session"
    private init() {}

    var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: sessionKey)
    }

    func login() {
        UserDefaults.standard.set(true, forKey: sessionKey)
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func isAdminEmail(_ email: String) -> Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == Self.email
    }

    func isValidOTP(_ otp: String) -> Bool {
        otp == Self.otp
    }
}
