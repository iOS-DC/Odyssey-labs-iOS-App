import Foundation

/// Handles all data persistence for reporting content and blocking users.
final class SafetyService {
    
    static let shared = SafetyService()
    private let mgr = SupabaseManager.shared
    
    enum ContentType: String {
        case user
        case chatMessage = "chat_message"
        case post
        case comment
    }
    
    enum ReportReason: String, CaseIterable {
        case harassment = "Harassment"
        case abusiveLanguage = "Abusive language"
        case spam = "Spam"
        case fakeAccount = "Fake account"
        case unsafeBehavior = "Unsafe behavior"
        case other = "Other"
    }
    
    private init() {}
    
    // MARK: - Reporting
    
    func report(
        reportedUserID: UUID,
        contentType: ContentType,
        contentID: UUID? = nil,
        reason: ReportReason
    ) async throws {
        try await SessionManager.shared.validateSession()
        guard let currentUserID = SessionManager.shared.userID else {
            throw NSError(domain: "SafetyService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        var payload: [String: Any] = [
            "reporter_id": currentUserID.uuidString,
            "reported_user_id": reportedUserID.uuidString,
            "content_type": contentType.rawValue,
            "reason": reason.rawValue
        ]
        if let cid = contentID {
            payload["content_id"] = cid.uuidString
        }
        
        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "reports")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }
    
    // MARK: - Blocking
    
    func blockUser(blockedUserID: UUID) async throws {
        try await SessionManager.shared.validateSession()
        guard let currentUserID = SessionManager.shared.userID else {
            throw NSError(domain: "SafetyService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let payload: [String: Any] = [
            "blocker_id": currentUserID.uuidString,
            "blocked_user_id": blockedUserID.uuidString
        ]
        
        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "blocked_users")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        
        invalidateBlockedCache()
    }
    
    func unblockUser(blockedUserID: UUID) async throws {
        try await SessionManager.shared.validateSession()
        guard let currentUserID = SessionManager.shared.userID else { return }
        
        let url = mgr.restURL(table: "blocked_users", 
                              query: "blocker_id=eq.\(currentUserID.uuidString)&blocked_user_id=eq.\(blockedUserID.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = mgr.userHeaders
        
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        
        invalidateBlockedCache()
    }
    
    // MARK: - Fetching Blocked List
    
    private var cachedBlockedIDs: Set<UUID>?
    
    func fetchBlockedUserIDs() async -> Set<UUID> {
        if let cached = cachedBlockedIDs { return cached }
        
        guard let currentUserID = UserDataModel.shared.getCurrentUser()?.id else { return [] }
        
        do {
            try await SessionManager.shared.validateSession()
            // Fetch records where I am blocker OR I am blocked
            let url = mgr.restURL(table: "blocked_users", 
                                  query: "or=(blocker_id.eq.\(currentUserID.uuidString),blocked_user_id.eq.\(currentUserID.uuidString))")
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = mgr.userHeaders
            
            let (data, response) = try await URLSession.shared.data(for: req)
            try checkHTTP(response, data: data)
            
            let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
            var ids = Set<UUID>()
            for row in rows {
                if let bIDStr = row["blocker_id"] as? String, let bID = UUID(uuidString: bIDStr),
                   let uIDStr = row["blocked_user_id"] as? String, let uID = UUID(uuidString: uIDStr) {
                    if bID == currentUserID {
                        ids.insert(uID)
                    } else {
                        ids.insert(bID)
                    }
                }
            }
            cachedBlockedIDs = ids
            return ids
        } catch {
            print("Error fetching blocked users: \(error)")
            return []
        }
    }
    
    func invalidateBlockedCache() {
        cachedBlockedIDs = nil
        NotificationCenter.default.post(name: .BlockedUsersDidUpdate, object: nil)
    }
    
    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        let msg = (body["message"] as? String)
               ?? (body["error"]   as? String)
               ?? (body["msg"]     as? String)
               ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
        throw NSError(domain: "SafetyService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

extension Notification.Name {
    static let BlockedUsersDidUpdate = Notification.Name("BlockedUsersDidUpdate")
}
