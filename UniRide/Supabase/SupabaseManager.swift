// SupabaseManager.swift
// UniRide
// Central config for Supabase REST + Auth API calls (no SDK dependency).

import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}

    // Reads from BackendConfig — single source of truth shared with the APIClient layer.
    let projectURL = BackendConfig.baseURL ?? URL(string: "https://jobxehwerpvedlfkbfoi.supabase.co")!
    let anonKey   = BackendConfig.supabaseAnonKey ?? BackendConfig.supabaseAnonKeyFallback

    // MARK: - Headers

    /// Headers for unauthenticated requests (anon key only)
    var anonHeaders: [String: String] {
        [
            "apikey":        anonKey,
            "Content-Type":  "application/json"
        ]
    }

    /// Headers for authenticated requests (anon key + bearer token)
    func authHeaders(token: String) -> [String: String] {
        [
            "apikey":        anonKey,
            "Authorization": "Bearer \(token)",
            "Content-Type":  "application/json"
        ]
    }

    /// Headers for the currently signed-in user (reads from SessionManager)
    var userHeaders: [String: String] {
        if let token = SessionManager.shared.accessToken {
            return authHeaders(token: token)
        }
        return anonHeaders
    }

    // MARK: - REST URL helpers

    func restURL(table: String, query: String = "") -> URL {
        var components = URLComponents(url: projectURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.query = query }
        return components.url!
    }

    func authURL(path: String) -> URL {
        projectURL.appendingPathComponent("auth/v1/\(path)")
    }
}
