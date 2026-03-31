import Foundation

// No longer using RemotePost/RemoteComment/AnyCodable with JSONDecoder
// Shifting to JSONSerialization for robust Supabase join handling.

// MARK: - Public model

struct CommunityPost {
    let id: UUID
    let authorUserID: UUID
    let text: String
    let imageURL: URL?
    var likeCount: Int
    var shareCount: Int
    var commentCount: Int
    var reportCount: Int
    let createdAt: Date
    var authorProfile: UserProfile?
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
        
        // 1. Get content IDs with 2+ reports to auto-hide
        let hiddenIDs = await fetchModeratedContentIDs()
        
        // 2. Fetch posts
        let url = mgr.restURL(table: "community_posts",
                              query: "select=*,profiles!author_user_id(*)&order=created_at.desc&limit=\(limit)")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        
        // 3. Filter out moderated content and apply live counts
        let posts = rows.compactMap(postFromRow)
                       .filter { !hiddenIDs.contains($0.id) }
        let postIDs = posts.map(\.id)
        let likeCounts = await fetchCountMap(table: "community_likes", idColumn: "post_id", ids: postIDs)
        let commentCounts = await fetchCountMap(table: "community_comments", idColumn: "post_id", ids: postIDs)
        let reportCounts = await fetchReportCounts(contentIDs: postIDs, contentType: .post)

        return posts.map { post in
            var updated = post
            updated.likeCount = likeCounts[post.id] ?? 0
            updated.commentCount = commentCounts[post.id] ?? 0
            updated.reportCount = reportCounts[post.id] ?? 0
            return updated
        }
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

        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        guard let first = rows.first, let idStr = first["id"] as? String, let id = UUID(uuidString: idStr) else {
            throw CommunityError.decodingFailed
        }
        return id
    }

    /// Deletes a post. Only succeeds if the post belongs to the current user.
    func deletePost(postID: UUID) async throws {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }
        let url = mgr.restURL(table: "community_posts",
                              query: "id=eq.\(postID.uuidString)&author_user_id=eq.\(uid.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }
    
    /// Fetches IDs of posts and comments that have reached the report threshold (2+ reports).
    func fetchModeratedContentIDs() async -> Set<UUID> {
        do {
            // We use the count logic from Supabase REST. 
            // Better: use a dedicated moderation system, but for now we aggregate reports.
            let url = mgr.restURL(table: "reports", query: "select=content_id")
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = mgr.userHeaders
            let (data, _) = try await URLSession.shared.data(for: req)
            let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
            
            var counts: [UUID: Int] = [:]
            for row in rows {
                if let idStr = row["content_id"] as? String, let id = UUID(uuidString: idStr) {
                    counts[id, default: 0] += 1
                }
            }
            
            // Filter Content with 2 or more reports
            let moderated = counts.filter { $0.value >= 2 }.map { $0.key }
            return Set(moderated)
        } catch {
            return []
        }
    }

    // MARK: - Likes

    /// Toggles a like on a post.
    /// - Inserts or deletes a row in `community_likes`
    /// - Counts all likes and PATCHes `community_posts.like_count` directly (no DB trigger needed)
    /// - Returns `(isNowLiked, newLikeCount)` so the UI can update precisely
    @discardableResult
    func toggleLike(postID: UUID) async throws -> (isLiked: Bool, count: Int) {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }

        // ── Step 1: check if already liked ──
        let checkURL = mgr.restURL(table: "community_likes",
                                   query: "post_id=eq.\(postID.uuidString)&user_id=eq.\(uid.uuidString)&limit=1")
        var checkReq = URLRequest(url: checkURL)
        checkReq.allHTTPHeaderFields = mgr.userHeaders
        let (checkData, checkResp) = try await URLSession.shared.data(for: checkReq)
        try checkHTTP(checkResp, data: checkData)
        let existing = (try? JSONSerialization.jsonObject(with: checkData) as? [[String: Any]]) ?? []

        let isNowLiked: Bool
        if existing.isEmpty {
            // ── Step 2a: insert like ──
            let payload: [String: Any] = ["post_id": postID.uuidString, "user_id": uid.uuidString]
            let body = try JSONSerialization.data(withJSONObject: payload)
            var insertReq = URLRequest(url: mgr.restURL(table: "community_likes"))
            insertReq.httpMethod = "POST"
            insertReq.allHTTPHeaderFields = mgr.userHeaders
            insertReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertReq.httpBody = body
            let (_, insertResp) = try await URLSession.shared.data(for: insertReq)
            try checkHTTP(insertResp, data: Data())
            isNowLiked = true
        } else {
            // ── Step 2b: delete like ──
            let deleteURL = mgr.restURL(table: "community_likes",
                                        query: "post_id=eq.\(postID.uuidString)&user_id=eq.\(uid.uuidString)")
            var deleteReq = URLRequest(url: deleteURL)
            deleteReq.httpMethod = "DELETE"
            deleteReq.allHTTPHeaderFields = mgr.userHeaders
            let (_, deleteResp) = try await URLSession.shared.data(for: deleteReq)
            try checkHTTP(deleteResp, data: Data())
            isNowLiked = false
        }

        // ── Step 3: count the real total likes for this post ──
        let countURL = mgr.restURL(table: "community_likes",
                                   query: "post_id=eq.\(postID.uuidString)&select=id")
        var countReq = URLRequest(url: countURL)
        countReq.allHTTPHeaderFields = mgr.userHeaders
        let (countData, _) = try await URLSession.shared.data(for: countReq)
        let allLikes = (try? JSONSerialization.jsonObject(with: countData) as? [[String: Any]]) ?? []
        let newCount = allLikes.count

        // ── Step 4: PATCH like_count on community_posts ──
        let patchURL = mgr.restURL(table: "community_posts",
                                   query: "id=eq.\(postID.uuidString)")
        var patchReq = URLRequest(url: patchURL)
        patchReq.httpMethod = "PATCH"
        patchReq.allHTTPHeaderFields = mgr.userHeaders
        patchReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchReq.httpBody = try JSONSerialization.data(withJSONObject: ["like_count": newCount])
        let (_, patchResp) = try await URLSession.shared.data(for: patchReq)
        try checkHTTP(patchResp, data: Data())

        return (isNowLiked, newCount)
    }

    /// Fetches all post IDs liked by the current user.
    func fetchUserLikedPostIDs() async -> Set<UUID> {
        guard let uid = SessionManager.shared.userID else { return [] }
        do {
            try await SessionManager.shared.validateSession()
            let url = mgr.restURL(table: "community_likes", query: "user_id=eq.\(uid.uuidString)&select=post_id")
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = mgr.userHeaders
            let (data, _) = try await URLSession.shared.data(for: req)
            let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
            
            let ids = rows.compactMap { $0["post_id"] as? String }.compactMap { UUID(uuidString: $0) }
            return Set(ids)
        } catch {
            return []
        }
    }

    // MARK: - Comments

    func fetchComments(postID: UUID) async throws -> [CommunityComment] {
        try await SessionManager.shared.validateSession()
        
        // 1. Get moderated IDs
        let hiddenIDs = await fetchModeratedContentIDs()
        
        // 2. Fetch comments
        let url = mgr.restURL(table: "community_comments",
                               query: "post_id=eq.\(postID.uuidString)&select=*,profiles!author_user_id(*)&order=created_at.asc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        
        // 3. Filter out moderated content
        var comments = rows.compactMap { row in
            commentFromRow(row, postID: postID)
        }.filter { !hiddenIDs.contains($0.id) }

        let commentIDs = comments.map(\.id)
        let reportCounts = await fetchReportCounts(contentIDs: commentIDs, contentType: .comment)
        for index in comments.indices {
            comments[index].reportCount = reportCounts[comments[index].id] ?? 0
        }
        return comments
    }

    /// Inserts a new comment for a post.
    /// - Inserts a row in `community_comments`
    /// - Counts all comments for the post and PATCHes `community_posts.comment_count` directly
    /// - Returns the `newTotalCount`
    @discardableResult
    func insertComment(postID: UUID, text: String) async throws -> Int {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }
        
        // 1. Insert the comment
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

        // 2. Count the real total comments for this post
        let countURL = mgr.restURL(table: "community_comments",
                                   query: "post_id=eq.\(postID.uuidString)&select=id")
        var countReq = URLRequest(url: countURL)
        countReq.allHTTPHeaderFields = mgr.userHeaders
        let (countData, _) = try await URLSession.shared.data(for: countReq)
        let allComments = (try? JSONSerialization.jsonObject(with: countData) as? [[String: Any]]) ?? []
        let newCount = allComments.count

        // 3. PATCH comment_count on community_posts
        let patchURL = mgr.restURL(table: "community_posts",
                                   query: "id=eq.\(postID.uuidString)")
        var patchReq = URLRequest(url: patchURL)
        patchReq.httpMethod = "PATCH"
        patchReq.allHTTPHeaderFields = mgr.userHeaders
        patchReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchReq.httpBody = try JSONSerialization.data(withJSONObject: ["comment_count": newCount])
        let (_, patchResp) = try await URLSession.shared.data(for: patchReq)
        try checkHTTP(patchResp, data: Data())

        return newCount
    }

    /// Deletes a specific comment and updates the post's comment count.
    func deleteComment(commentID: UUID, postID: UUID) async throws -> Int {
        try await SessionManager.shared.validateSession()
        
        // 1. Delete the comment
        let url = mgr.restURL(table: "community_comments", query: "id=eq.\(commentID.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = mgr.userHeaders
        let (_, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: Data())

        // 2. Count the real total comments for this post
        let countURL = mgr.restURL(table: "community_comments",
                                   query: "post_id=eq.\(postID.uuidString)&select=id")
        var countReq = URLRequest(url: countURL)
        countReq.allHTTPHeaderFields = mgr.userHeaders
        let (countData, _) = try await URLSession.shared.data(for: countReq)
        let allComments = (try? JSONSerialization.jsonObject(with: countData) as? [[String: Any]]) ?? []
        let newCount = allComments.count

        // 3. Update the post's comment_count field
        let patchURL = mgr.restURL(table: "community_posts", query: "id=eq.\(postID.uuidString)")
        var patchReq = URLRequest(url: patchURL)
        patchReq.httpMethod = "PATCH"
        patchReq.allHTTPHeaderFields = mgr.userHeaders
        patchReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchReq.httpBody = try JSONSerialization.data(withJSONObject: ["comment_count": newCount])
        let (_, patchResp) = try await URLSession.shared.data(for: patchReq)
        try checkHTTP(patchResp, data: Data())

        return newCount
    }

    // MARK: - Shares

    @discardableResult
    func recordShare(postID: UUID, destination: String? = nil) async throws -> Int {
        try await SessionManager.shared.validateSession()
        guard let uid = SessionManager.shared.userID else { throw CommunityError.notLoggedIn }
        
        // 1. Record the share event
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

        // 2. Count the real total shares for this post
        let countURL = mgr.restURL(table: "community_shares",
                                   query: "post_id=eq.\(postID.uuidString)&select=id")
        var countReq = URLRequest(url: countURL)
        countReq.allHTTPHeaderFields = mgr.userHeaders
        let (countData, _) = try await URLSession.shared.data(for: countReq)
        let allShares = (try? JSONSerialization.jsonObject(with: countData) as? [[String: Any]]) ?? []
        let newCount = allShares.count

        // 3. PATCH share_count on community_posts
        let patchURL = mgr.restURL(table: "community_posts",
                                   query: "id=eq.\(postID.uuidString)")
        var patchReq = URLRequest(url: patchURL)
        patchReq.httpMethod = "PATCH"
        patchReq.allHTTPHeaderFields = mgr.userHeaders
        patchReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchReq.httpBody = try JSONSerialization.data(withJSONObject: ["share_count": newCount])
        let (_, patchResp) = try await URLSession.shared.data(for: patchReq)
        try checkHTTP(patchResp, data: Data())

        return newCount
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

    /// Fetches the live like_count and comment_count for a single post.
    /// Use this after a toggle-like or insert-comment to get the trigger-updated values.
    func fetchPostCounts(postID: UUID) async throws -> (likeCount: Int, commentCount: Int) {
        try await SessionManager.shared.validateSession()
        let likes = await fetchCountMap(table: "community_likes", idColumn: "post_id", ids: [postID])[postID] ?? 0
        let comments = await fetchCountMap(table: "community_comments", idColumn: "post_id", ids: [postID])[postID] ?? 0
        return (likes, comments)
    }

    private func postFromRow(_ row: [String: Any]) -> CommunityPost? {
        guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr),
              let authStr = row["author_user_id"] as? String, let auth = UUID(uuidString: authStr) else { return nil }
        
        let text = row["text"] as? String ?? ""
        let imgUrl = row["image_url"] as? String
        let likes = row["like_count"] as? Int ?? 0
        let shares = row["share_count"] as? Int ?? 0
        let comments = row["comment_count"] as? Int ?? 0
        
        let createdStr = row["created_at"] as? String ?? ""
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let created = iso.date(from: createdStr) ?? Date()
        
        var post = CommunityPost(
            id: id, authorUserID: auth, text: text,
            imageURL: imgUrl.flatMap(URL.init(string:)),
            likeCount: likes, shareCount: shares,
            commentCount: comments, reportCount: 0, createdAt: created
        )
        
        // Robust Profile Join Handling:
        if let profArray = row["profiles"] as? [[String: Any]], let firstProf = profArray.first {
            post.authorProfile = UserProfile(row: firstProf)
        } else if let profObj = row["profiles"] as? [String: Any] {
            post.authorProfile = UserProfile(row: profObj)
        }
        
        return post
    }

    private func commentFromRow(_ row: [String: Any], postID: UUID) -> CommunityComment? {
        guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr),
              let authStr = row["author_user_id"] as? String, let auth = UUID(uuidString: authStr) else { return nil }
        
        let text = row["text"] as? String ?? ""
        let createdStr = row["created_at"] as? String ?? ""
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var comment = CommunityComment(
            id: id, postID: postID, authorUserID: auth, text: text,
            createdAt: iso.date(from: createdStr) ?? Date()
        )
        
        if let profArray = row["profiles"] as? [[String: Any]], let firstProf = profArray.first {
            comment.authorProfile = UserProfile(row: firstProf)
        } else if let profObj = row["profiles"] as? [String: Any] {
            comment.authorProfile = UserProfile(row: profObj)
        }
        
        return comment
    }

    private func fetchCountMap(table: String, idColumn: String, ids: [UUID]) async -> [UUID: Int] {
        guard !ids.isEmpty else { return [:] }
        do {
            let joinedIDs = ids.map(\.uuidString).joined(separator: ",")
            let query = "\(idColumn)=in.(\(joinedIDs))&select=\(idColumn)"
            let url = mgr.restURL(table: table, query: query)
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = mgr.userHeaders
            let (data, response) = try await URLSession.shared.data(for: req)
            try checkHTTP(response, data: data)
            let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
            var counts: [UUID: Int] = [:]
            for row in rows {
                if let idStr = row[idColumn] as? String, let id = UUID(uuidString: idStr) {
                    counts[id, default: 0] += 1
                }
            }
            return counts
        } catch {
            return [:]
        }
    }

    func fetchReportCounts(contentIDs: [UUID], contentType: SafetyService.ContentType) async -> [UUID: Int] {
        guard !contentIDs.isEmpty else { return [:] }
        do {
            let joinedIDs = contentIDs.map(\.uuidString).joined(separator: ",")
            let query = "content_type=eq.\(contentType.rawValue)&content_id=in.(\(joinedIDs))&select=content_id"
            let url = mgr.restURL(table: "reports", query: query)
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = mgr.userHeaders
            let (data, response) = try await URLSession.shared.data(for: req)
            try checkHTTP(response, data: data)
            let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
            var counts: [UUID: Int] = [:]
            for row in rows {
                if let idStr = row["content_id"] as? String, let id = UUID(uuidString: idStr) {
                    counts[id, default: 0] += 1
                }
            }
            return counts
        } catch {
            return [:]
        }
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
