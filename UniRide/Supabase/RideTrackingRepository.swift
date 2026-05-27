// RideTrackingRepository.swift
// UniRide
//
// REST layer for the ride_locations table.
//
// ── Supabase setup (run once in SQL Editor) ────────────────────────
//
//   CREATE TABLE IF NOT EXISTS ride_locations (
//       id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//       ride_id     UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
//       lat         DOUBLE PRECISION NOT NULL,
//       lon         DOUBLE PRECISION NOT NULL,
//       heading     DOUBLE PRECISION NOT NULL DEFAULT 0,
//       created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
//   );
//   CREATE INDEX IF NOT EXISTS idx_ride_locations_ride_id
//       ON ride_locations(ride_id);
//   ALTER TABLE ride_locations ENABLE ROW LEVEL SECURITY;
//   CREATE POLICY "auth read"   ON ride_locations FOR SELECT
//       USING (auth.role() = 'authenticated');
//   CREATE POLICY "auth insert" ON ride_locations FOR INSERT
//       WITH CHECK (auth.role() = 'authenticated');
//   ALTER TABLE ride_locations REPLICA IDENTITY FULL;
//
//   Then in Supabase Dashboard → Database → Replication,
//   enable "ride_locations" so Realtime broadcasts inserts.
// ──────────────────────────────────────────────────────────────────

import Foundation

final class RideTrackingRepository {
    static let shared = RideTrackingRepository()
    private init() {}

    private let mgr = SupabaseManager.shared

    // MARK: - Broadcast driver position

    /// Inserts one location snapshot for the active ride.
    /// Called by RideTrackingService every ~4 s while ride is ongoing.
    func insertLocation(rideID: UUID, lat: Double, lon: Double, heading: Double) async throws {
        let url = mgr.restURL(table: "ride_locations")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        let body: [String: Any] = [
            "ride_id": rideID.uuidString,
            "lat":     lat,
            "lon":     lon,
            "heading": heading
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                   ?? "HTTP \(http.statusCode)"
            throw TrackingError.serverError(msg)
        }
    }

    // MARK: - Fetch latest location (initial load + polling fallback)

    /// Returns the most-recent location point for a ride, or nil if none yet.
    func fetchLatestLocation(rideID: UUID) async throws -> LocationPoint? {
        let url = mgr.restURL(
            table: "ride_locations",
            query: "ride_id=eq.\(rideID.uuidString)&order=created_at.desc&limit=1"
        )
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = mgr.userHeaders
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else { return nil }
        let rows = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        guard let row = rows.first,
              let lat = row["lat"] as? Double,
              let lon = row["lon"] as? Double else { return nil }
        return LocationPoint(lat: lat, lon: lon, address: nil)
    }

    // MARK: - Error

    enum TrackingError: LocalizedError {
        case serverError(String)
        var errorDescription: String? {
            if case .serverError(let m) = self { return m }
            return nil
        }
    }
}
