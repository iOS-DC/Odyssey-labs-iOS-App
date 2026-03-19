// SessionManager.swift
// UniRide
// Stores and refreshes the Supabase session locally.

import Foundation

final class SessionManager {
    static let shared = SessionManager()
    private init() { loadFromDisk() }

    /// Maximum age of a session before the user must log in again (3 days).
    static let sessionMaxAgeSeconds: TimeInterval = 3 * 24 * 60 * 60

    // MARK: - Stored session data
    private(set) var accessToken:  String?
    private(set) var refreshToken: String?
    private(set) var userID:       UUID?
    private(set) var userEmail:    String?
    /// When the access token expires (Unix timestamp from Supabase `expires_at`).
    private(set) var accessTokenExpiresAt: Date?
    /// When the user first logged in — used to enforce 3-day session limit.
    private(set) var loginDate: Date?

    /// True only when a token exists AND the 3-day session window hasn't expired.
    var isLoggedIn: Bool {
        guard accessToken != nil, userID != nil else { return false }
        if let loginDate, Date().timeIntervalSince(loginDate) > Self.sessionMaxAgeSeconds {
            // Session is older than 3 days — treat as logged out
            clear()
            return false
        }
        return true
    }

    /// True when the access token itself is expired (needs refresh).
    var isAccessTokenExpired: Bool {
        guard let exp = accessTokenExpiresAt else { return false }
        // Treat token as expired 60 s before actual expiry for safety.
        return Date().addingTimeInterval(60) >= exp
    }

    // MARK: - Save / Clear

    func save(accessToken: String, refreshToken: String, userID: UUID, email: String?,
              expiresAt: Date? = nil, preserveLoginDate: Bool = false) {
        self.accessToken  = accessToken
        self.refreshToken = refreshToken
        self.userID       = userID
        self.userEmail    = email
        self.accessTokenExpiresAt = expiresAt
        // Keep original loginDate on token refresh; set now on first login.
        if !preserveLoginDate || self.loginDate == nil {
            self.loginDate = Date()
        }
        persistToDisk()
        
        // Notify the app that session has updated
        NotificationCenter.default.post(name: Notification.Name("SessionUpdated"), object: nil)
    }

    func clear() {
        accessToken          = nil
        refreshToken         = nil
        userID               = nil
        userEmail            = nil
        accessTokenExpiresAt = nil
        loginDate            = nil
        UserDefaults.standard.removeObject(forKey: "sb_session")
        
        // Notify the app that user logged out
        NotificationCenter.default.post(name: Notification.Name("UserLoggedOut"), object: nil)
    }

    // MARK: - Session Validation
    
    /// Throws an error if the session is invalid or expired. Forces a refresh if needed.
    func validateSession() async throws {
        if !isLoggedIn {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        if isAccessTokenExpired {
            await refreshIfNeeded()
            if isAccessTokenExpired {
                clear()
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired, please log in again"])
            }
        }
    }

    // MARK: - Refresh token

    /// Refreshes the access token only if it is expired (or close to expiry).
    func refreshIfNeeded() async {
        guard isLoggedIn, isAccessTokenExpired, let rt = refreshToken else { return }
        var components = URLComponents(url: SupabaseManager.shared.authURL(path: "token"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        let url = components.url!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = SupabaseManager.shared.anonHeaders
        req.httpBody = try? JSONEncoder().encode(["refresh_token": rt])
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccess  = json["access_token"]  as? String,
              let newRefresh = json["refresh_token"] as? String,
              let userObj    = json["user"]           as? [String: Any],
              let idStr      = userObj["id"]          as? String,
              let uid        = UUID(uuidString: idStr) else { return }
        let email = userObj["email"] as? String
        // Parse `expires_at` (Unix timestamp) returned by Supabase
        var expiresAt: Date? = nil
        if let exp = json["expires_at"] as? TimeInterval {
            expiresAt = Date(timeIntervalSince1970: exp)
        }
        // preserveLoginDate = true so the 3-day clock isn't reset on every token refresh
        save(accessToken: newAccess, refreshToken: newRefresh, userID: uid, email: email,
             expiresAt: expiresAt, preserveLoginDate: true)
    }

    // MARK: - Disk persistence

    private struct Persisted: Codable {
        let accessToken:  String
        let refreshToken: String
        let userID:       String
        let userEmail:    String?
        let accessTokenExpiresAt: Date?
        let loginDate: Date?
    }

    private func persistToDisk() {
        guard let at = accessToken, let rt = refreshToken, let uid = userID else { return }
        let p = Persisted(accessToken: at, refreshToken: rt, userID: uid.uuidString,
                          userEmail: userEmail, accessTokenExpiresAt: accessTokenExpiresAt,
                          loginDate: loginDate)
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: "sb_session")
        }
    }

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "sb_session"),
           let p = try? JSONDecoder().decode(Persisted.self, from: data) {
            self.accessToken = p.accessToken
            self.refreshToken = p.refreshToken
            self.userID = UUID(uuidString: p.userID)
            self.userEmail = p.userEmail
            self.accessTokenExpiresAt = p.accessTokenExpiresAt
            self.loginDate = p.loginDate
            
            // Check session validity immediately upon loading
            if !self.isLoggedIn {
                self.clear()
            }
        }
    }
}
