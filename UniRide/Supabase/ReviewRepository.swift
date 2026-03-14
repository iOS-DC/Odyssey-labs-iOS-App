// ReviewRepository.swift
// UniRide
// Supabase CRUD for the `reviews` table via REST API (no SDK).

import Foundation

final class ReviewRepository {
    static let shared = ReviewRepository()
    private init() {}

    private let mgr = SupabaseManager.shared
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let isoBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Helpers

    private func parseDate(_ str: String?) -> Date {
        guard let s = str else { return Date() }
        return iso.date(from: s) ?? isoBasic.date(from: s) ?? Date()
    }

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"]   as? String
               ?? "HTTP \(http.statusCode)"
        throw ReviewRepoError.serverError(msg)
    }

    private func reviewFromRow(_ row: [String: Any]) -> Review? {
        guard
            let id         = UUID(uuidString: row["id"]          as? String ?? ""),
            let rideID     = UUID(uuidString: row["ride_id"]     as? String ?? ""),
            let reviewerID = UUID(uuidString: row["reviewer_id"] as? String ?? ""),
            let revieweeID = UUID(uuidString: row["reviewee_id"] as? String ?? ""),
            let stars      = row["stars"] as? Int
        else { return nil }

        return Review(
            id:         id,
            rideID:     rideID,
            reviewerID: reviewerID,
            revieweeID: revieweeID,
            stars:      stars,
            comment:    row["comment"] as? String,
            timestamp:  parseDate(row["created_at"] as? String)
        )
    }

    // MARK: - Insert

    /// Persists a single review to Supabase. Duplicate reviews are rejected
    /// via a unique constraint on (ride_id, reviewer_id, reviewee_id).
    func insertReview(_ review: Review) async throws {
        try await SessionManager.shared.validateSession()
        let url = mgr.restURL(table: "reviews")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // resolution=ignore-duplicates → graceful no-op if review already exists
        req.setValue("resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
        var payload: [String: Any] = [
            "id":          review.id.uuidString,
            "ride_id":     review.rideID.uuidString,
            "reviewer_id": review.reviewerID.uuidString,
            "reviewee_id": review.revieweeID.uuidString,
            "stars":       review.stars,
            "created_at":  iso.string(from: review.timestamp)
        ]
        if let c = review.comment { payload["comment"] = c }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Fetch all reviews for a user (as reviewee)

    /// Returns all reviews where the given user was rated.
    /// Used to compute their average rating across all devices.
    func fetchReviews(revieweeID: UUID) async throws -> [Review] {
        try await SessionManager.shared.validateSession()
        let url = mgr.restURL(
            table: "reviews",
            query: "reviewee_id=eq.\(revieweeID.uuidString)&order=created_at.desc"
        )
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { reviewFromRow($0) }
    }

    /// Returns all reviews the current user submitted (as reviewer).
    func fetchMyReviews(reviewerID: UUID) async throws -> [Review] {
        try await SessionManager.shared.validateSession()
        let url = mgr.restURL(
            table: "reviews",
            query: "reviewer_id=eq.\(reviewerID.uuidString)&order=created_at.desc"
        )
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { reviewFromRow($0) }
    }

    // MARK: - Error

    enum ReviewRepoError: LocalizedError {
        case serverError(String)
        var errorDescription: String? {
            if case .serverError(let m) = self { return m }
            return nil
        }
    }
}
