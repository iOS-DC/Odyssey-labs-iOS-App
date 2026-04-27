// RideTrackingService.swift
// UniRide
//
// Coordinates live location broadcasting (driver) and
// real-time subscription (passenger) during an active ride.
//
// Driver flow:  startBroadcasting(for:) → inserts to ride_locations every 4 s
// Passenger flow: subscribeToDriverLocation(rideID:) → Realtime INSERT + polling fallback

import Foundation
import CoreLocation
import MapKit

// Notification posted whenever a new driver coordinate arrives.
// userInfo key "coordinate" → CLLocationCoordinate2D boxed in NSValue.
extension Notification.Name {
    static let rideDriverLocationDidUpdate = Notification.Name("rideDriverLocationDidUpdate")
}

final class RideTrackingService {
    static let shared = RideTrackingService()
    private init() {}

    // MARK: - Driver state
    private var broadcastTimer: Timer?
    private(set) var broadcastingRideID: UUID?

    // MARK: - Passenger state
    private var realtimeClient: SupabaseRealtimeClient?
    private var pollingTimer:   Timer?
    private(set) var subscribedRideID: UUID?

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Driver side
    // ─────────────────────────────────────────────────────────────────

    /// Call right after `startRideAsync` succeeds.
    func startBroadcasting(for rideID: UUID) {
        guard broadcastingRideID == nil else { return }
        broadcastingRideID = rideID

        LocationService.shared.startLiveUpdates()
        broadcastCurrentLocation()          // first shot immediately

        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.broadcastCurrentLocation()
        }
    }

    /// Call when ride ends or the tracking screen is dismissed by the driver.
    func stopBroadcasting() {
        broadcastTimer?.invalidate()
        broadcastTimer = nil
        broadcastingRideID = nil
    }

    private func broadcastCurrentLocation() {
        guard let rideID = broadcastingRideID,
              let loc    = LocationService.shared.lastLocation else { return }
        let lat     = loc.coordinate.latitude
        let lon     = loc.coordinate.longitude
        let heading = loc.course >= 0 ? loc.course : 0
        Task {
            try? await RideTrackingRepository.shared.insertLocation(
                rideID: rideID, lat: lat, lon: lon, heading: heading)
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Passenger side
    // ─────────────────────────────────────────────────────────────────

    /// Opens a Realtime WebSocket channel and a polling fallback.
    /// Updates are delivered via `Notification.Name.rideDriverLocationDidUpdate`.
    func subscribeToDriverLocation(rideID: UUID) {
        guard subscribedRideID == nil else { return }
        subscribedRideID = rideID

        // 1. Fetch the latest persisted point straight away so the map
        //    shows something even before the next broadcast arrives.
        Task {
            if let pt = try? await RideTrackingRepository.shared.fetchLatestLocation(rideID: rideID) {
                await MainActor.run {
                    self.postLocationUpdate(CLLocationCoordinate2D(latitude: pt.lat, longitude: pt.lon))
                }
            }
        }

        // 2. Realtime — fires on every INSERT the driver makes.
        realtimeClient = SupabaseRealtimeClient()
        let channel = realtimeClient!.channel(
            "public:ride_locations:ride_id=eq.\(rideID.uuidString)")
        channel.on("INSERT") { [weak self] payload in
            guard let lat = payload["lat"] as? Double,
                  let lon = payload["lon"] as? Double else { return }
            self?.postLocationUpdate(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        realtimeClient!.connect()
        channel.subscribe()

        // 3. Polling fallback every 6 s — catches any missed Realtime events.
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            guard let self, let id = self.subscribedRideID else { return }
            Task {
                if let pt = try? await RideTrackingRepository.shared.fetchLatestLocation(rideID: id) {
                    await MainActor.run {
                        self.postLocationUpdate(CLLocationCoordinate2D(latitude: pt.lat, longitude: pt.lon))
                    }
                }
            }
        }
    }

    /// Stop listening — call when tracking screen is closed.
    func unsubscribeFromDriverLocation() {
        pollingTimer?.invalidate()
        pollingTimer   = nil
        realtimeClient?.disconnect()
        realtimeClient = nil
        subscribedRideID = nil
    }

    // MARK: - Helpers

    private func postLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        let value = NSValue(mkCoordinate: coordinate)
        NotificationCenter.default.post(
            name: .rideDriverLocationDidUpdate,
            object: self,
            userInfo: ["coordinate": value]
        )
    }
}
