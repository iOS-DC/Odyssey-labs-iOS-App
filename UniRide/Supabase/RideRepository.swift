// RideRepository.swift
// UniRide
// Full Supabase CRUD for rides, ride_requests, and bookings via REST API (no SDK).

import Foundation

final class RideRepository {
    static let shared = RideRepository()
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

    private func encodeJSON<T: Encodable>(_ value: T) -> String? {
        guard let d = try? JSONEncoder().encode(value),
              let s = String(data: d, encoding: .utf8) else { return nil }
        return s
    }

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else { return }
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
               ?? (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
               ?? "HTTP \(http.statusCode)"
        throw RideRepoError.serverError(msg)
    }

    // MARK: - Row -> Model

    private func rideFromRow(_ row: [String: Any]) -> Ride? {
        guard let id       = UUID(uuidString: row["id"]             as? String ?? ""),
              let driverID = UUID(uuidString: row["driver_user_id"] as? String ?? ""),
              let srcLat   = row["source_lat"]          as? Double,
              let srcLon   = row["source_lon"]          as? Double,
              let dstLat   = row["destination_lat"]     as? Double,
              let dstLon   = row["destination_lon"]     as? Double,
              let deptStr  = row["departure_time"]      as? String,
              let seatsTotal  = row["seats_total"]      as? Int,
              let seatsAvail  = row["seats_available"]  as? Int,
              let statusStr   = row["status"]           as? String,
              let status      = RideStatus(rawValue: statusStr)
        else { return nil }

        // fare_per_seat can come back as Int or Double from JSON
        let fare: Double
        if let d = row["fare_per_seat"] as? Double { fare = d }
        else if let i = row["fare_per_seat"] as? Int { fare = Double(i) }
        else { fare = 0 }

        let source = LocationPoint(lat: srcLat, lon: srcLon, address: row["source_address"]      as? String)
        let dest   = LocationPoint(lat: dstLat, lon: dstLon, address: row["destination_address"] as? String)

        var waypoints: [LocationPoint] = []
        if let wpStr = row["waypoints"] as? String,
           let wpData = wpStr.data(using: .utf8) {
            waypoints = (try? JSONDecoder().decode([LocationPoint].self, from: wpData)) ?? []
        }
        var selectedRoute: RideRoute?
        if let rtStr = row["selected_route"] as? String,
           let rtData = rtStr.data(using: .utf8) {
            selectedRoute = try? JSONDecoder().decode(RideRoute.self, from: rtData)
        }
        return Ride(id: id, driverUserID: driverID, source: source, destination: dest,
                    waypoints: waypoints, selectedRoute: selectedRoute,
                    departureTime: parseDate(deptStr), seatsTotal: seatsTotal,
                    seatsAvailable: seatsAvail, farePerSeat: fare, status: status,
                    notes: row["notes"] as? String,
                    createdAt: parseDate(row["created_at"] as? String))
    }

    private func requestFromRow(_ row: [String: Any]) -> RideRequest? {
        guard let id      = UUID(uuidString: row["id"]                as? String ?? ""),
              let rideID  = UUID(uuidString: row["ride_id"]           as? String ?? ""),
              let passID  = UUID(uuidString: row["passenger_user_id"] as? String ?? ""),
              let pickLat = row["pickup_lat"] as? Double,
              let pickLon = row["pickup_lon"] as? Double,
              let seats   = row["seats"]      as? Int,
              let stStr   = row["status"]     as? String,
              let status  = RideRequestStatus(rawValue: stStr)
        else { return nil }

        let pickup = LocationPoint(lat: pickLat, lon: pickLon, address: row["pickup_address"] as? String)
        return RideRequest(id: id, rideID: rideID, passengerUserID: passID, pickupPoint: pickup,
                           seats: seats, minAcceptableFare: row["min_acceptable_fare"] as? Double,
                           status: status, createdAt: parseDate(row["created_at"] as? String),
                           reviewedAt: (row["reviewed_at"] != nil && !(row["reviewed_at"] is NSNull))
                               ? parseDate(row["reviewed_at"] as? String) : nil)
    }

    private func bookingFromRow(_ row: [String: Any]) -> Booking? {
        guard let id      = UUID(uuidString: row["id"]                as? String ?? ""),
              let rideID  = UUID(uuidString: row["ride_id"]           as? String ?? ""),
              let passID  = UUID(uuidString: row["passenger_user_id"] as? String ?? ""),
              let seats   = row["seats"]      as? Int,
              let pickLat = row["pickup_lat"] as? Double,
              let pickLon = row["pickup_lon"] as? Double,
              let stStr   = row["status"]     as? String,
              let status  = BookingStatus(rawValue: stStr)
        else { return nil }

        let pickup = LocationPoint(lat: pickLat, lon: pickLon, address: row["pickup_address"] as? String)
        return Booking(id: id, rideID: rideID, passengerUserID: passID, seats: seats,
                       pickupPoint: pickup, createdAt: parseDate(row["created_at"] as? String),
                       status: status)
    }

    // MARK: - Rides

    func fetchPublishedRides() async throws -> [Ride] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides", query: "status=eq.published&order=departure_time.asc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { rideFromRow($0) }
    }

    func fetchRides(driverID: UUID) async throws -> [Ride] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides",
                              query: "driver_user_id=eq.\(driverID.uuidString)&order=departure_time.desc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { rideFromRow($0) }
    }

    func fetchRide(id: UUID) async throws -> Ride? {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides", query: "id=eq.\(id.uuidString)&limit=1")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.first.flatMap { rideFromRow($0) }
    }

    func insertRide(_ ride: Ride) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides")
        var req = URLRequest(url: url); req.httpMethod = "POST"; req.allHTTPHeaderFields = headers
        var p: [String: Any] = [
            "id": ride.id.uuidString, "driver_user_id": ride.driverUserID.uuidString,
            "source_lat": ride.source.lat, "source_lon": ride.source.lon,
            "destination_lat": ride.destination.lat, "destination_lon": ride.destination.lon,
            "departure_time": iso.string(from: ride.departureTime),
            "seats_total": ride.seatsTotal, "seats_available": ride.seatsAvailable,
            "fare_per_seat": ride.farePerSeat, "status": ride.status.rawValue,
            "created_at": iso.string(from: ride.createdAt)
        ]
        if let v = ride.source.address      { p["source_address"]      = v }
        if let v = ride.destination.address { p["destination_address"] = v }
        if let v = ride.notes                { p["notes"]          = v }
        if !ride.waypoints.isEmpty, let v = encodeJSON(ride.waypoints) { p["waypoints"] = v }
        if let rt = ride.selectedRoute, let v = encodeJSON(rt) { p["selected_route"] = v }
        req.httpBody = try JSONSerialization.data(withJSONObject: p)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func updateRideStatus(id: UUID, status: RideStatus) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides", query: "id=eq.\(id.uuidString)")
        var req = URLRequest(url: url); req.httpMethod = "PATCH"; req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["status": status.rawValue])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func updateSeatsAvailable(rideID: UUID, seats: Int) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "rides", query: "id=eq.\(rideID.uuidString)")
        var req = URLRequest(url: url); req.httpMethod = "PATCH"; req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["seats_available": seats])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Requests

    func fetchRequests(rideID: UUID) async throws -> [RideRequest] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_requests",
                              query: "ride_id=eq.\(rideID.uuidString)&order=created_at.asc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { requestFromRow($0) }
    }

    func fetchMyRequests(passengerID: UUID) async throws -> [RideRequest] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_requests",
                              query: "passenger_user_id=eq.\(passengerID.uuidString)&order=created_at.desc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { requestFromRow($0) }
    }

    func insertRequest(_ request: RideRequest) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_requests")
        var req = URLRequest(url: url); req.httpMethod = "POST"; req.allHTTPHeaderFields = headers
        var p: [String: Any] = [
            "id": request.id.uuidString, "ride_id": request.rideID.uuidString,
            "passenger_user_id": request.passengerUserID.uuidString,
            "pickup_lat": request.pickupPoint.lat, "pickup_lon": request.pickupPoint.lon,
            "seats": request.seats, "status": request.status.rawValue,
            "created_at": iso.string(from: request.createdAt)
        ]
        if let v = request.pickupPoint.address { p["pickup_address"]      = v }
        if let v = request.minAcceptableFare   { p["min_acceptable_fare"] = v }
        req.httpBody = try JSONSerialization.data(withJSONObject: p)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func updateRequestStatus(id: UUID, status: RideRequestStatus) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_requests", query: "id=eq.\(id.uuidString)")
        var req = URLRequest(url: url); req.httpMethod = "PATCH"; req.allHTTPHeaderFields = headers
        var p: [String: Any] = ["status": status.rawValue]
        if status != .pending { p["reviewed_at"] = iso.string(from: Date()) }
        req.httpBody = try JSONSerialization.data(withJSONObject: p)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Bookings

    func fetchBookings(rideID: UUID) async throws -> [Booking] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_bookings",
                              query: "ride_id=eq.\(rideID.uuidString)&order=created_at.asc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { bookingFromRow($0) }
    }

    func fetchMyBookings(passengerID: UUID) async throws -> [Booking] {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_bookings",
                              query: "passenger_user_id=eq.\(passengerID.uuidString)&order=created_at.desc")
        var req = URLRequest(url: url); req.allHTTPHeaderFields = headers
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return rows.compactMap { bookingFromRow($0) }
    }

    func insertBooking(_ booking: Booking) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_bookings")
        var req = URLRequest(url: url); req.httpMethod = "POST"; req.allHTTPHeaderFields = headers
        var p: [String: Any] = [
            "id": booking.id.uuidString, "ride_id": booking.rideID.uuidString,
            "passenger_user_id": booking.passengerUserID.uuidString,
            "seats": booking.seats,
            "pickup_lat": booking.pickupPoint.lat, "pickup_lon": booking.pickupPoint.lon,
            "status": booking.status.rawValue,
            "created_at": iso.string(from: booking.createdAt)
        ]
        if let v = booking.pickupPoint.address { p["pickup_address"] = v }
        req.httpBody = try JSONSerialization.data(withJSONObject: p)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    func updateBookingStatus(id: UUID, status: BookingStatus) async throws {
        let headers = mgr.userHeaders
        let url = mgr.restURL(table: "ride_bookings", query: "id=eq.\(id.uuidString)")
        var req = URLRequest(url: url); req.httpMethod = "PATCH"; req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["status": status.rawValue])
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - Error

    enum RideRepoError: LocalizedError {
        case serverError(String)
        var errorDescription: String? {
            if case .serverError(let m) = self { return m }
            return nil
        }
    }
}
