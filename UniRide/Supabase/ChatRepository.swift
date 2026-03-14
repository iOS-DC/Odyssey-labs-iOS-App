// ChatRepository.swift
// UniRide
// CRUD for `messages` table in Supabase via REST API.

import Foundation

final class ChatRepository {
    static let shared = ChatRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Fetch messages for a ride

    func fetchMessages(rideID: UUID) async throws -> [ChatMessage] {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "messages",
                              query: "ride_id=eq.\(rideID.uuidString)&order=created_at.asc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { row -> ChatMessage? in
            guard let idStr    = row["id"]         as? String, let id  = UUID(uuidString: idStr),
                  let senderID = row["sender_id"]  as? String,
                  let text     = row["body"]        as? String,
                  let tsStr    = row["created_at"]  as? String else { return nil }
            let name = (row["sender_name"] as? String) ?? ""
            let ts   = ISO8601DateFormatter().date(from: tsStr) ?? Date()
            return ChatMessage(id: id, senderID: senderID, senderName: name, text: text, timestamp: ts)
        }
    }

    // MARK: - Send message

    func sendMessage(rideID: UUID, senderID: UUID, senderName: String, text: String) async throws {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "messages")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "ride_id":     rideID.uuidString,
            "sender_id":   senderID.uuidString,
            "sender_name": senderName,
            "body":        text
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
