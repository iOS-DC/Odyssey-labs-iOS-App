// NotificationAndReviewRepository.swift
// UniRide
// CRUD for `app_notifications` and `reviews` tables via Supabase REST API.

import Foundation

final class NotificationAndReviewRepository {
    static let shared = NotificationAndReviewRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Notifications

    func fetchNotifications(userID: UUID) async throws -> [[String: Any]] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "app_notifications",
                              query: "user_id=eq.\(userID.uuidString)&order=created_at.desc&limit=50")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    func insertNotification(userID: UUID, title: String, body: String, type: String) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "app_notifications")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        let payload: [String: Any] = [
            "user_id":    userID.uuidString,
            "title":      title,
            "body":       body,
            "notif_type": type,          // schema column is notif_type
            "is_read":    false,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func markNotificationRead(id: UUID) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "app_notifications", query: "id=eq.\(id.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["is_read": true])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Reviews

    func fetchReviews(revieweeID: UUID) async throws -> [[String: Any]] {
        let headers = mgr.userHeaders
        // schema: reviewee_user_id (the person being reviewed)
        let url = mgr.restURL(table: "reviews",
                              query: "reviewee_user_id=eq.\(revieweeID.uuidString)&order=created_at.desc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    func insertReview(revieweeID: UUID, reviewerID: UUID, rideID: UUID, rating: Int, comment: String?) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "reviews")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        // schema columns: reviewee_user_id, reviewer_user_id, ride_id, rating, comment
        var payload: [String: Any] = [
            "reviewee_user_id": revieweeID.uuidString,
            "reviewer_user_id": reviewerID.uuidString,
            "ride_id":          rideID.uuidString,
            "rating":           rating,
            "created_at":       ISO8601DateFormatter().string(from: Date())
        ]
        if let c = comment { payload["comment"] = c }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? "HTTP \(http.statusCode)"
        throw RepoError.serverError(msg)
    }

    enum RepoError: LocalizedError {
        case serverError(String)
        var errorDescription: String? {
            if case .serverError(let m) = self { return m }
            return nil
        }
    }
}
