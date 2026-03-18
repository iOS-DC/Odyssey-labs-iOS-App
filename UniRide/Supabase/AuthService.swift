// AuthService.swift
// UniRide
// Handles Supabase Auth via REST API (no SDK).

import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let mgr = SupabaseManager.shared
    private let session = SessionManager.shared

    // MARK: - Send OTP (magic-link / OTP to email)

    func sendEmailOTP(email: String) async throws {
        let url  = mgr.authURL(path: "otp")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.anonHeaders
        // Use JSONSerialization — JSONEncoder cannot encode plain [String:Any] dicts
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email":       email,
            "create_user": true          // boolean, not string
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Verify OTP

    func verifyEmailOTP(email: String, token: String) async throws {
        let url  = mgr.authURL(path: "verify")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.anonHeaders
        // Use JSONSerialization — JSONEncoder cannot encode plain [String:Any] dicts
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "type":  "email",
            "email": email,
            "token": token
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)

        // Parse session
        guard let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let at      = json["access_token"]  as? String,
              let rt      = json["refresh_token"] as? String,
              let userObj = json["user"]           as? [String: Any],
              let idStr   = userObj["id"]          as? String,
              let uid     = UUID(uuidString: idStr) else {
            throw AuthError.invalidResponse
        }
        let email = userObj["email"] as? String
        var expiresAt: Date? = nil
        if let exp = json["expires_at"] as? TimeInterval {
            expiresAt = Date(timeIntervalSince1970: exp)
        }
        session.save(accessToken: at, refreshToken: rt, userID: uid, email: email,
                     expiresAt: expiresAt, preserveLoginDate: false)
    }

    func signInWithPassword(email: String, password: String) async throws {
        var components = URLComponents(url: mgr.authURL(path: "token"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        let url = components.url!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.anonHeaders
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let at = json["access_token"] as? String,
              let rt = json["refresh_token"] as? String,
              let userObj = json["user"] as? [String: Any],
              let idStr = userObj["id"] as? String,
              let uid = UUID(uuidString: idStr) else {
            throw AuthError.invalidResponse
        }

        let resolvedEmail = (userObj["email"] as? String) ?? email
        var expiresAt: Date? = nil
        if let exp = json["expires_at"] as? TimeInterval {
            expiresAt = Date(timeIntervalSince1970: exp)
        }

        session.save(accessToken: at, refreshToken: rt, userID: uid, email: resolvedEmail,
                     expiresAt: expiresAt, preserveLoginDate: false)
    }

    // MARK: - Sign out

    func signOut() async throws {
        guard let token = session.accessToken else { session.clear(); return }
        let url  = mgr.authURL(path: "logout")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.authHeaders(token: token)
        _ = try? await URLSession.shared.data(for: req)
        session.clear()
    }

    // MARK: - Delete Account
    
    /// Permanently deletes the user data from Supabase.
    /// This calls an RPC 'delete_user_data' which must handle the deletion of auth.users
    /// and all related public tables due to RLS/Foreign Key constraints.
    func deleteAccount() async throws {
        guard let token = session.accessToken else { 
            session.clear()
            return 
        }
        
        // 1. Call the RPC to delete data from Supabase
        let url = mgr.restURL(table: "rpc/delete_user_data")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.authHeaders(token: token)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        
        // 2. Perform local cleanup
        session.clear()
    }

    // MARK: - Get current user profile from Supabase Auth

    func getCurrentUser() async throws -> [String: Any] {
        guard let token = session.accessToken else { throw AuthError.notLoggedIn }
        let url  = mgr.authURL(path: "user")
        var req  = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.authHeaders(token: token)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        return json
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode >= 400 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["msg"] as? String
                   ?? (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error_description"] as? String
                   ?? "HTTP \(http.statusCode)"
            throw AuthError.serverError(msg)
        }
    }

    enum AuthError: LocalizedError {
        case notLoggedIn
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:         return "You are not logged in."
            case .invalidResponse:     return "Unexpected server response."
            case .serverError(let m):  return m
            }
        }
    }
}
