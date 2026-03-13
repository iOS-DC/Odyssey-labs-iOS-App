import Foundation

// MARK: - Remote DTOs

private struct RemotePost: Codable {
    let id: String
    let authorUserId: String
    let text: String
    let imageUrl: String?
    let likeCount: Int
    let shareCount: Int
    let commentCount: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, text
        case authorUserId  = "author_user_id"
        case imageUrl      = "image_url"
        case likeCount     = "like_count"
        case shareCount    = "share_count"
        case commentCount  = "comment_count"
        case createdAt     = "created_at"
    }
}

private struct RemoteComment: Codable {
    let id: String
    let postId: String
    let authorUserId: String
    let text: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, text
        case postId        = "post_id"
        case authorUserId  = "author_user_id"
        case createdAt     = "created_at"
    }
}

// MARK: - Public model

struct CommunityPost {
    let id: UUID
    let authorUserID: UUID
    let text: String
    let imageURL: URL?
    var likeCount: Int
    var shareCount: Int
    var commentCount: Int
    let createdAt: Date
}

// MARK: - Repository

enum CommunityError: Error {
    case notLoggedIn
    case encodingFailed
    case serverError(Int, String)
    case decodingFailed
}

final class CommunityRepository {
    static let shared = CommunityRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Posts

    /// Fetches the most recent `limit` posts, ordered newest first.
    func fetchPosts(limit: Int = 50) async throws -> [CommunityPost] {
        try await SessionManager.shared.validateSession()
        let url = mgr.restURL(table: "community_posts",
                              query: "order=created_at.desc&limit=\(limit)")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let remote = try JSONDecoder().decode([RemotePost].self, from: data)
        return remote.compactMap(postFromRemote)
    }

    /// Inserts a new post for the current user.
    func insertPost(text: String, imageURL: URL? = nil) async throws -> UUID {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }

        var payload: [String: Any] = [
            "author_user_id": uid.uuidString,
            "text": text
        ]
        if let url = imageURL { payload["image_url"] = url.absoluteString }

        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "community_posts")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)

        let inserted = try JSONDecoder().decode([RemotePost].self, from: data)
        guard let first = inserted.first, let id = UUID(uuidString: first.id) else {
            throw CommunityError.decodingFailed
        }
        return id
    }

    // MARK: - Likes

    /// Toggles a like on a post. Returns true if the post is now liked.
    func toggleLike(postID: UUID) async throws -> Bool {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }

        // Check if already liked
        let checkURL = mgr.restURL(table: "community_likes",
                                   query: "post_id=eq.\(postID.uuidString)&user_id=eq.\(uid.uuidString)&limit=1")
        var checkReq = URLRequest(url: checkURL)
        checkReq.allHTTPHeaderFields = mgr.userHeaders
        let (checkData, checkResp) = try await URLSession.shared.data(for: checkReq)
        try checkHTTP(checkResp, data: checkData)

        let existing = (try? JSONSerialization.jsonObject(with: checkData) as? [[String: Any]]) ?? []
        if existing.isEmpty {
            // Not yet liked → insert
            let payload: [String: Any] = [
                "post_id": postID.uuidString,
                "user_id": uid.uuidString
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let insertURL = mgr.restURL(table: "community_likes")
            var insertReq = URLRequest(url: insertURL)
            insertReq.httpMethod = "POST"
            insertReq.allHTTPHeaderFields = mgr.userHeaders
            insertReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertReq.httpBody = body
            let (_, insertResp) = try await URLSession.shared.data(for: insertReq)
            try checkHTTP(insertResp, data: Data())
            return true
        } else {
            // Already liked → delete (unlike)
            let deleteURL = mgr.restURL(table: "community_likes",
                                        query: "post_id=eq.\(postID.uuidString)&user_id=eq.\(uid.uuidString)")
            var deleteReq = URLRequest(url: deleteURL)
            deleteReq.httpMethod = "DELETE"
            deleteReq.allHTTPHeaderFields = mgr.userHeaders
            let (_, deleteResp) = try await URLSession.shared.data(for: deleteReq)
            try checkHTTP(deleteResp, data: Data())
            return false
        }
    }

    // MARK: - Comments

    func fetchComments(postID: UUID) async throws -> [String] {
        try await SessionManager.shared.validateSession()
        let url = mgr.restURL(table: "community_comments",
                              query: "post_id=eq.\(postID.uuidString)&order=created_at.asc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let remote = (try? JSONDecoder().decode([RemoteComment].self, from: data)) ?? []
        return remote.map { $0.text }
    }

    func insertComment(postID: UUID, text: String) async throws {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }
        let payload: [String: Any] = [
            "post_id": postID.uuidString,
            "author_user_id": uid.uuidString,
            "text": text
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "community_comments")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Shares

    func recordShare(postID: UUID, destination: String? = nil) async throws {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }
        var payload: [String: Any] = [
            "post_id": postID.uuidString,
            "user_id": uid.uuidString
        ]
        if let dest = destination { payload["destination"] = dest }
        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "community_shares")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Event Attendance

    /// Inserts an attendance record into `event_attendance`.
    /// Call this when a user taps "Attend" / "Join Ride" on an event.
    func recordEventAttendance(eventID: UUID, isDayScholar: Bool = false) async throws {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }

        // Check for duplicate before inserting
        let checkURL = mgr.restURL(table: "event_attendance",
                                   query: "event_id=eq.\(eventID.uuidString)&user_id=eq.\(uid.uuidString)&limit=1")
        var checkReq = URLRequest(url: checkURL)
        checkReq.allHTTPHeaderFields = mgr.userHeaders
        let (checkData, _) = try await URLSession.shared.data(for: checkReq)
        let existing = (try? JSONSerialization.jsonObject(with: checkData) as? [[String: Any]]) ?? []
        guard existing.isEmpty else { return } // already attending

        let payload: [String: Any] = [
            "event_id":      eventID.uuidString,
            "user_id":       uid.uuidString,
            "is_day_scholar": isDayScholar
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let url = mgr.restURL(table: "event_attendance")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Helpers

    private func postFromRemote(_ r: RemotePost) -> CommunityPost? {
        guard let id   = UUID(uuidString: r.id),
              let auth = UUID(uuidString: r.authorUserId) else { return nil }
        let iso = ISO8601DateFormatter()
        let created = iso.date(from: r.createdAt) ?? Date()
        return CommunityPost(
            id: id, authorUserID: auth, text: r.text,
            imageURL: r.imageUrl.flatMap(URL.init(string:)),
            likeCount: r.likeCount, shareCount: r.shareCount,
            commentCount: r.commentCount, createdAt: created
        )
    }

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            let msg = (body["message"] as? String)
                   ?? (body["error"]   as? String)
                   ?? (body["msg"]     as? String)
                   ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw CommunityError.serverError(http.statusCode, msg)
        }
    }
}
