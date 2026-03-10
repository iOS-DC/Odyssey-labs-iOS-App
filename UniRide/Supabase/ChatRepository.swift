// ChatRepository.swift
// UniRide
// CRUD for `messages` table in Supabase via REST API.

import Foundation

final class ChatRepository {
    static let shared = ChatRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Fetch messages for a ride

    func fetchMessages(rideID: UUID) async throws -> [[String: Any]] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "messages",
                              query: "ride_id=eq.\(rideID.uuidString)&order=created_at.asc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    // MARK: - Send message

    func sendMessage(rideID: UUID, senderID: UUID, body: String) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "messages")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        let payload: [String: Any] = [
            "ride_id":   rideID.uuidString,
            "sender_id": senderID.uuidString,
            "body":      body,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Delete message

    func deleteMessage(id: UUID) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "messages", query: "id=eq.\(id.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? "HTTP \(http.statusCode)"
        throw ChatError.serverError(msg)
    }

    enum ChatError: LocalizedError {
        case serverError(String)
        var errorDescription: String? {
            if case .serverError(let m) = self { return m }
            return nil
        }
    }
}
