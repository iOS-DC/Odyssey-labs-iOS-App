import Foundation

enum BackendConfig {
    static var useRealBackend: Bool {
        if let explicit = ProcessInfo.processInfo.environment["USE_REAL_BACKEND"] {
            return explicit == "1" || explicit.lowercased() == "true"
        }
        if let flag = Bundle.main.object(forInfoDictionaryKey: "USE_REAL_BACKEND") as? Bool {
            return flag
        }
        return false
    }

    static var baseURL: URL? {
        if let raw = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        return nil
    }

    static var supabaseAnonKey: String? {
        if let raw = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }

    /// Dev-only override for phone OTP fallback (e.g., "111111").
    /// When present, phone OTP flow uses local verification instead of remote SMS provider.
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
