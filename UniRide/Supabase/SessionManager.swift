// SessionManager.swift
// UniRide
// Stores and refreshes the Supabase session locally.

import Foundation

final class SessionManager {
    static let shared = SessionManager()
    private init() { loadFromDisk() }

    // MARK: - Stored session data
    private(set) var accessToken:  String?
    private(set) var refreshToken: String?
    private(set) var userID:       UUID?
    private(set) var userEmail:    String?

    var isLoggedIn: Bool { accessToken != nil && userID != nil }

    // MARK: - Save / Clear

    func save(accessToken: String, refreshToken: String, userID: UUID, email: String?) {
        self.accessToken  = accessToken
        self.refreshToken = refreshToken
        self.userID       = userID
        self.userEmail    = email
        persistToDisk()
    }

    func clear() {
        accessToken  = nil
        refreshToken = nil
        userID       = nil
        userEmail    = nil
        UserDefaults.standard.removeObject(forKey: "sb_session")
    }

    // MARK: - Refresh token

    func refreshIfNeeded() async {
        guard let rt = refreshToken else { return }
        let url = SupabaseManager.shared.authURL(path: "token?grant_type=refresh_token")
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
        save(accessToken: newAccess, refreshToken: newRefresh, userID: uid, email: email)
    }

    // MARK: - Disk persistence

    private struct Persisted: Codable {
        let accessToken:  String
        let refreshToken: String
        let userID:       String
        let userEmail:    String?
    }

    private func persistToDisk() {
        guard let at = accessToken, let rt = refreshToken, let uid = userID else { return }
        let p = Persisted(accessToken: at, refreshToken: rt, userID: uid.uuidString, userEmail: userEmail)
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: "sb_session")
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: "sb_session"),
              let p = try? JSONDecoder().decode(Persisted.self, from: data),
              let uid = UUID(uuidString: p.userID) else { return }
        accessToken  = p.accessToken
        refreshToken = p.refreshToken
        userID       = uid
        userEmail    = p.userEmail
    }
}
