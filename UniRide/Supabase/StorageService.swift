// StorageService.swift
// UniRide
// Supabase Storage uploads via REST API (no SDK).

import Foundation

final class StorageService {
    static let shared = StorageService()
    private init() {}

    // MARK: - Upload image to a bucket

    /// Uploads `imageData` to `bucket/path` and returns the public URL.
    func upload(bucket: String, path: String, imageData: Data, mimeType: String = "image/jpeg") async throws -> String {
        guard let token = SessionManager.shared.accessToken else {
            throw StorageError.notLoggedIn
        }
        let url = SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/\(bucket)/\(path)")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseManager.shared.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)",              forHTTPHeaderField: "Authorization")
        req.setValue(mimeType,                       forHTTPHeaderField: "Content-Type")
        req.setValue("upsert",                       forHTTPHeaderField: "x-upsert")
        req.httpBody = imageData
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        return SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
            .absoluteString
    }

    // MARK: - Delete object

    func delete(bucket: String, path: String) async throws {
        guard let token = SessionManager.shared.accessToken else { throw StorageError.notLoggedIn }
        let url = SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/\(bucket)/\(path)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue(SupabaseManager.shared.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Public URL helper

    func publicURL(bucket: String, path: String) -> String {
        SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
            .absoluteString
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? "HTTP \(http.statusCode)"
        throw StorageError.serverError(msg)
    }

    enum StorageError: LocalizedError {
        case notLoggedIn
        case serverError(String)
        var errorDescription: String? {
            switch self {
            case .notLoggedIn:        return "Not logged in."
            case .serverError(let m): return m
            }
        }
    }
}
