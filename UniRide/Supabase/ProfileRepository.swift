// ProfileRepository.swift
// UniRide
// CRUD for the `profiles` and `user_vehicles` tables in Supabase via REST API.

import Foundation

final class ProfileRepository {
    static let shared = ProfileRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Fetch profile by user ID

    func fetchProfile(userID: UUID) async throws -> [String: Any]? {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        // Use array format (no Accept: object header) to avoid 406 when row missing
        let url = mgr.restURL(table: "profiles", query: "id=eq.\(userID.uuidString)&limit=1")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.first
    }

    // MARK: - Upsert profile

    func upsertProfile(_ profile: [String: Any]) async throws {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "profiles")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: profile)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Update specific fields

    func updateProfile(userID: UUID, fields: [String: Any]) async throws {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "profiles", query: "id=eq.\(userID.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: fields)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Vehicle (user_vehicles table, PK = user_id)

    func upsertVehicle(userID: UUID, vehicle: Vehicle) async throws {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "user_vehicles")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        let payload: [String: Any] = [
            "user_id":             userID.uuidString,
            "alias":               vehicle.alias ?? "",
            "type":                vehicle.type.rawValue,
            "model":               vehicle.model,
            "registration_number": vehicle.registrationNumber,
            "seats":               vehicle.seats
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func fetchVehicles(userID: UUID) async throws -> [Vehicle] {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "user_vehicles", query: "user_id=eq.\(userID.uuidString)")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        
        return rows.compactMap { row in
            guard let typeRaw = row["type"] as? String,
                  let vType   = VehicleType(rawValue: typeRaw),
                  let model   = row["model"] as? String,
                  let regNum  = row["registration_number"] as? String,
                  let seats   = row["seats"] as? Int
            else { return nil }
            let alias = row["alias"] as? String
            return Vehicle(alias: alias, type: vType, model: model, registrationNumber: regNum, seats: seats)
        }
    }

    // MARK: - Home locations (home_locations table)

    func upsertHomeLocation(userID: UUID, location: LocationPoint, isPrimary: Bool = true) async throws {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "home_locations")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        var payload: [String: Any] = [
            "user_id":    userID.uuidString,
            "lat":        location.lat,
            "lon":        location.lon,
            "is_primary": isPrimary
        ]
        if let a = location.address { payload["address"] = a }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func fetchHomeLocations(userID: UUID) async throws -> [LocationPoint] {
        try await SessionManager.shared.validateSession()
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "home_locations",
                              query: "user_id=eq.\(userID.uuidString)&order=is_primary.desc,created_at.desc")
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { row -> LocationPoint? in
            guard let lat = row["lat"] as? Double, let lon = row["lon"] as? Double else { return nil }
            return LocationPoint(lat: lat, lon: lon, address: row["address"] as? String)
        }
    }

    // MARK: - Upload avatar

    func uploadAvatar(userID: UUID, imageData: Data, mimeType: String = "image/jpeg") async throws -> String {
        try await SessionManager.shared.validateSession()
        guard let token = SessionManager.shared.accessToken else { throw RepositoryError.notLoggedIn }
        let path = "\(userID.uuidString)/avatar.jpg"
        let url  = SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/avatars/\(path)")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseManager.shared.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)",              forHTTPHeaderField: "Authorization")
        req.setValue(mimeType,                       forHTTPHeaderField: "Content-Type")
        req.setValue("true",                         forHTTPHeaderField: "x-upsert")
        req.httpBody = imageData
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        return SupabaseManager.shared.projectURL
            .appendingPathComponent("storage/v1/object/public/avatars/\(path)")
            .absoluteString
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? "HTTP \(http.statusCode)"
        throw RepositoryError.serverError(msg)
    }

    enum RepositoryError: LocalizedError {
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
