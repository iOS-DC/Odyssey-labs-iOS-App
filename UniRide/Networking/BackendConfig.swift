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
}
