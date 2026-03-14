import Foundation

enum BackendConfig {
    // MARK: - Supabase project constants (single source of truth)
    // These are the fallback values used when no env var or Info.plist key is present.
    static let supabaseProjectURL = "https://jobxehwerpvedlfkbfoi.supabase.co"
    static let supabaseAnonKeyFallback = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvYnhlaHdlcnB2ZWRsZmtiZm9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNTIzODMsImV4cCI6MjA4NzgyODM4M30.xftgy_ZnxXDl6Ow5ZFL3m0Y_RojJDjsJEdq1DbYM3c0"

    // MARK: - Backend gate
    // Defaults to TRUE — the real Supabase backend is always used unless explicitly disabled.
    static var useRealBackend: Bool {
        if let explicit = ProcessInfo.processInfo.environment["USE_REAL_BACKEND"] {
            return explicit == "1" || explicit.lowercased() == "true"
        }
        if let flag = Bundle.main.object(forInfoDictionaryKey: "USE_REAL_BACKEND") as? Bool {
            return flag
        }
        return true // ← was false; backend is now always on by default
    }

    // MARK: - Base URL
    // Falls back to the hardcoded Supabase project URL so APIClient always has a valid base.
    static var baseURL: URL? {
        if let raw = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        return URL(string: supabaseProjectURL) // hardcoded fallback
    }

    // MARK: - Anon Key
    // Falls back to the hardcoded anon key so APIClient can always authenticate.
    static var supabaseAnonKey: String? {
        if let raw = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return supabaseAnonKeyFallback // hardcoded fallback
    }

    // MARK: - Dev helpers
    /// Dev-only override for phone OTP (e.g., "111111"). When set, skips remote SMS.
    static var devFixedPhoneOTP: String? {
        if let raw = ProcessInfo.processInfo.environment["DEV_FIXED_PHONE_OTP"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "DEV_FIXED_PHONE_OTP") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }
}
