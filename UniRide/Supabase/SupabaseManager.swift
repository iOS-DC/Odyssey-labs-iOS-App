// SupabaseManager.swift
// UniRide
// Central config for Supabase REST + Auth API calls (no SDK dependency).

import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}

    // ── Replace with your actual Supabase project values ──
    let projectURL = URL(string: "https://jobxehwerpvedlfkbfoi.supabase.co")!
    let anonKey   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvYnhlaHdlcnB2ZWRsZmtiZm9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNTIzODMsImV4cCI6MjA4NzgyODM4M30.xftgy_ZnxXDl6Ow5ZFL3m0Y_RojJDjsJEdq1DbYM3c0"

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
