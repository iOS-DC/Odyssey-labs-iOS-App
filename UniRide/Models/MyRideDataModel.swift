//  ride.swift
//  UniRide
//
//  Created by Air on 11/11/25.
//
extension Notification.Name {
    static let rideRequestsUpdated = Notification.Name("rideRequestsUpdated")
    static let ridesUpdated = Notification.Name("ridesUpdated")   // new

}



import Foundation

// MARK: - Enums used for ride status and ride request and booking status
enum RideStatus: String, Codable { case draft, published, ongoing, completed, cancelled }
enum RideRequestStatus: String, Codable { case pending, approved, denied, cancelled }
enum BookingStatus: String, Codable { case confirmed, cancelled }

// location point variable
struct LocationPoint: Codable, Equatable {
    var lat: Double
    var lon: Double
    var address: String?
}

struct RideRoute: Codable, Equatable {
    var coordinates: [LocationPoint]   // ordered coordinates along the polyline
    var distanceMeters: Double
    var expectedTravelTime: Double
}

struct Ride: Codable, Equatable {
    let id: UUID
    let driverUserID: UUID
    var source: LocationPoint
    var destination: LocationPoint
    var waypoints: [LocationPoint]

    // NEW: store chosen route (optional)
    var selectedRoute: RideRoute?

    var departureTime: Date
    var seatsTotal: Int
    var seatsAvailable: Int
    var farePerSeat: Double
    var status: RideStatus
    var notes: String?
    let createdAt: Date

    init(driverUserID: UUID,
         source: LocationPoint,
         destination: LocationPoint,
         waypoints: [LocationPoint] = [],
         selectedRoute: RideRoute? = nil,    // NEW param (default nil)
         departureTime: Date,
         seatsTotal: Int,
         farePerSeat: Double,
         status: RideStatus = .draft,
         notes: String? = nil) {
        self.id = UUID()
        self.driverUserID = driverUserID
        self.source = source
        self.destination = destination
        self.waypoints = waypoints
        self.selectedRoute = selectedRoute      // store
        self.departureTime = departureTime
        self.seatsTotal = seatsTotal
        self.seatsAvailable = seatsTotal
        self.farePerSeat = farePerSeat
        self.status = status
        self.notes = notes
        self.createdAt = Date()
    }

    init(id: UUID,
         driverUserID: UUID,
         source: LocationPoint,
         destination: LocationPoint,
         waypoints: [LocationPoint] = [],
         selectedRoute: RideRoute? = nil,
         departureTime: Date,
         seatsTotal: Int,
         seatsAvailable: Int,
         farePerSeat: Double,
         status: RideStatus,
         notes: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.driverUserID = driverUserID
        self.source = source
        self.destination = destination
        self.waypoints = waypoints
        self.selectedRoute = selectedRoute
        self.departureTime = departureTime
        self.seatsTotal = seatsTotal
        self.seatsAvailable = seatsAvailable
        self.farePerSeat = farePerSeat
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
    }

    static func ==(lhs: Ride, rhs: Ride) -> Bool { lhs.id == rhs.id }
}

struct RideRequest: Codable, Equatable {
    let id: UUID
    let rideID: UUID
    let passengerUserID: UUID
    var pickupPoint: LocationPoint
    var seats: Int
    var minAcceptableFare: Double?
    var status: RideRequestStatus
    let createdAt: Date
    var reviewedAt: Date?

    init(rideID: UUID,
         passengerUserID: UUID,
         pickupPoint: LocationPoint,
         seats: Int,
         minAcceptableFare: Double? = nil) {
        self.id = UUID()
        self.rideID = rideID
        self.passengerUserID = passengerUserID
        self.pickupPoint = pickupPoint
        self.seats = seats
        self.minAcceptableFare = minAcceptableFare
        self.status = .pending
        self.createdAt = Date()
        self.reviewedAt = nil
    }

    init(id: UUID,
         rideID: UUID,
         passengerUserID: UUID,
         pickupPoint: LocationPoint,
         seats: Int,
         minAcceptableFare: Double? = nil,
         status: RideRequestStatus,
         createdAt: Date,
         reviewedAt: Date? = nil) {
        self.id = id
        self.rideID = rideID
        self.passengerUserID = passengerUserID
        self.pickupPoint = pickupPoint
        self.seats = seats
        self.minAcceptableFare = minAcceptableFare
        self.status = status
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
    }

    static func ==(lhs: RideRequest, rhs: RideRequest) -> Bool { lhs.id == rhs.id }
}

struct Booking: Codable, Equatable {
    let id: UUID
    let rideID: UUID
    let passengerUserID: UUID
    var seats: Int
    var pickupPoint: LocationPoint
    let createdAt: Date
    var status: BookingStatus

    init(rideID: UUID,
         passengerUserID: UUID,
         seats: Int,
         pickupPoint: LocationPoint) {
        self.id = UUID()
        self.rideID = rideID
        self.passengerUserID = passengerUserID
        self.seats = seats
        self.pickupPoint = pickupPoint
        self.createdAt = Date()
        self.status = .confirmed
    }

    /// Full memberwise init used by RideRepository when decoding from Supabase.
    init(id: UUID,
         rideID: UUID,
         passengerUserID: UUID,
         seats: Int,
         pickupPoint: LocationPoint,
         createdAt: Date,
         status: BookingStatus) {
        self.id = id
        self.rideID = rideID
        self.passengerUserID = passengerUserID
        self.seats = seats
        self.pickupPoint = pickupPoint
        self.createdAt = createdAt
        self.status = status
    }

    static func ==(lhs: Booking, rhs: Booking) -> Bool { lhs.id == rhs.id }
}

final class RideDataModel {

    static let shared = RideDataModel()

    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let ridesURL: URL
    private let requestsURL: URL
    private let bookingsURL: URL

    private var rides: [Ride] = []
    private var requests: [RideRequest] = []
    private var bookings: [Booking] = []

    private init() {
        ridesURL    = documentsDirectory.appendingPathComponent("rides").appendingPathExtension("json")
        requestsURL = documentsDirectory.appendingPathComponent("ride_requests").appendingPathExtension("json")
        bookingsURL = documentsDirectory.appendingPathComponent("ride_bookings").appendingPathExtension("json")
        loadAll()
        // Only seed mock data when no Supabase session exists (dev/demo mode)
        if SessionManager.shared.isLoggedIn {
            removeSeededMockRides()
        } else {
            seedMockRidesIfNeeded()
        }
        UserDataModel.shared.ensureDriverProfiles(for: rides.map { $0.driverUserID })
    }

    
    @discardableResult  //prevents unnecessary warnings like function is unused
  
    func getAllRides() -> [Ride] {
        return rides
    }

    func getRide(_ id: UUID) -> Ride? {
        return rides.first { $0.id == id }
    }

    @discardableResult
    func createRide(_ ride: Ride) -> Ride {
        rides.append(ride)
        saveRides()
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        return ride
    }

    @discardableResult
    func createRideAndPublishAsync(_ ride: Ride) async throws -> Ride {
        // Always persist to Supabase; use the signed-in user's ID as driver
        var outboundRide = ride
        if let authID = SessionManager.shared.userID, authID != ride.driverUserID {
            outboundRide = Ride(
                id: ride.id,
                driverUserID: authID,
                source: ride.source,
                destination: ride.destination,
                waypoints: ride.waypoints,
                selectedRoute: ride.selectedRoute,
                departureTime: ride.departureTime,
                seatsTotal: ride.seatsTotal,
                seatsAvailable: ride.seatsAvailable,
                farePerSeat: ride.farePerSeat,
                status: ride.status,
                notes: ride.notes,
                createdAt: ride.createdAt
            )
        }
        try await RideRepository.shared.insertRide(outboundRide)
        if outboundRide.status != .published {
            try await RideRepository.shared.updateRideStatus(id: outboundRide.id, status: .published)
        }
        // Also keep local cache in sync
        _ = createRide(outboundRide)
        if outboundRide.status != .published { _ = publishRide(id: outboundRide.id) }
        return outboundRide
    }

    @discardableResult
    func updateRide(_ updated: Ride) -> Bool {
        guard let i = rides.firstIndex(where: { $0.id == updated.id }) else { return false }
        rides[i] = updated
        saveRides()
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        return true
    }

    /// Publish a ride (from draft or cancelled). Returns true if published.
    @discardableResult
    func publishRide(id: UUID) -> Bool {
        guard var r = getRide(id) else { return false }
        // allow publishing from draft; allow republishing a cancelled ride if app policy permits
        guard r.status == .draft || r.status == .cancelled else { return false }
        r.status = .published
        return updateRide(r)
    }

    /// Cancel a ride. Returns true if succeeded.
    @discardableResult
    func cancelRide(id: UUID) -> Bool {
        guard var r = getRide(id) else { return false }
        // idempotent: if already cancelled, treat as success
        guard r.status != .cancelled else { return true }
        r.status = .cancelled
        return updateRide(r)
    }

    @discardableResult
    func cancelRideAsync(id: UUID) async throws -> Bool {
        try await RideRepository.shared.updateRideStatus(id: id, status: .cancelled)
        return cancelRide(id: id)
    }

    /// Manually start a published ride. Returns true if succeeded.
    @discardableResult
    func startRide(id: UUID) -> Bool {
        guard var r = getRide(id) else { return false }
        guard r.status == .published else { return false }
        r.status = .ongoing
        return updateRide(r)
    }

    @discardableResult
    func startRideAsync(id: UUID) async throws -> Bool {
        try await RideRepository.shared.updateRideStatus(id: id, status: .ongoing)
        return startRide(id: id)
    }

    /// Manually end an ongoing ride (mark completed). Returns true if succeeded.
    @discardableResult
    func endRide(id: UUID) -> Bool {
        guard var r = getRide(id) else { return false }
        guard r.status == .ongoing else { return false }
        r.status = .completed
        return updateRide(r)
    }

    @discardableResult
    func endRideAsync(id: UUID) async throws -> Bool {
        try await RideRepository.shared.updateRideStatus(id: id, status: .completed)
        return endRide(id: id)
    }

    @discardableResult
    func deleteRide(id: UUID) -> Bool {
        let initialCount = rides.count
        rides.removeAll { $0.id == id }
        requests.removeAll { $0.rideID == id }
        bookings.removeAll { $0.rideID == id }
        saveRides(); saveRequests(); saveBookings()
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        return rides.count < initialCount
    }

    func createJoinRequest(_ req: RideRequest) -> RideRequest {
        requests.append(req)
        saveRequests()
        // Notify both requests and rides so UI that watches rides or requests will update.
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        return req
    }

    func createJoinRequestAsync(_ req: RideRequest) async throws -> RideRequest {
        var outbound = req
        // Use the signed-in user's Supabase ID as the passenger
        if let authID = SessionManager.shared.userID, authID != req.passengerUserID {
            outbound = RideRequest(
                id: req.id,
                rideID: req.rideID,
                passengerUserID: authID,
                pickupPoint: req.pickupPoint,
                seats: req.seats,
                status: req.status,
                createdAt: req.createdAt,
                reviewedAt: req.reviewedAt
            )
        }
        try await RideRepository.shared.insertRequest(outbound)
        return createJoinRequest(outbound)
    }


    /// Host approves: moves seats, creates booking
    func approveRequest(requestID: UUID, hostUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]

        // Only pending requests may be approved
        guard rq.status == .pending else { return }

        guard var ride = getRide(rq.rideID) else { return }
        guard ride.driverUserID == hostUserID else { return }

        // Do not approve requests for cancelled or already completed rides
        guard ride.status != .cancelled && ride.status != .completed else { return }

        // Allow approving while published or ongoing
        guard ride.status == .published || ride.status == .ongoing else { return }

        // Ensure seats available
        guard ride.seatsAvailable >= rq.seats else { return }

        // mark approved
        rq.status = .approved
        rq.reviewedAt = Date()
        requests[rqIdx] = rq

        // reduce seats
        ride.seatsAvailable -= rq.seats
        updateRide(ride)

        // booking
        let booking = Booking(rideID: rq.rideID,
                              passengerUserID: rq.passengerUserID,
                              seats: rq.seats,
                              pickupPoint: rq.pickupPoint)
        bookings.append(booking)

        saveRequests()
        saveBookings()

        // Notify UI that requests/bookings/rides changed
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)

        // In-app notification → passenger
        let route = "\(ride.source.address ?? "Origin") → \(ride.destination.address ?? "Destination")"
        AppNotificationModel.shared.send(
            to: rq.passengerUserID,
            title: "Booking Approved ✅",
            body: "Your request for \(route) has been approved. You're all set!",
            type: .requestApproved
        )
    }

    func approveRequestAsync(requestID: UUID, hostUserID: UUID) async throws {
        // BUG FIX: Reordered for safer failure handling.
        // 1. Insert booking first — if this fails, request stays 'pending' (safe to retry)
        // 2. Update seat count
        // 3. Mark request 'approved' last — treat this as the commit step
        guard let req = requests.first(where: { $0.id == requestID }),
              let ride = rides.first(where: { $0.id == req.rideID }) else {
            throw NSError(domain: "Rides", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Request or ride not found locally"])
        }

        let booking = Booking(
            rideID: req.rideID,
            passengerUserID: req.passengerUserID,
            seats: req.seats,
            pickupPoint: req.pickupPoint
        )
        try await RideRepository.shared.insertBooking(booking)

        let newSeats = max(0, ride.seatsAvailable - req.seats)
        try await RideRepository.shared.updateSeatsAvailable(rideID: ride.id, seats: newSeats)

        // Commit: mark the request approved only after booking + seats are persisted
        try await RideRepository.shared.updateRequestStatus(id: requestID, status: .approved)

        // Mirror the changes in the local cache
        approveRequest(requestID: requestID, hostUserID: hostUserID)
    }

    func denyRequest(requestID: UUID, hostUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]

        // only pending requests can be denied
        guard rq.status == .pending else { return }

        guard let ride = getRide(rq.rideID), ride.driverUserID == hostUserID else { return }

        rq.status = .denied
        rq.reviewedAt = Date()
        requests[rqIdx] = rq
        saveRequests()

        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)

        // In-app notification → passenger
        let route = "\(ride.source.address ?? "Origin") → \(ride.destination.address ?? "Destination")"
        AppNotificationModel.shared.send(
            to: rq.passengerUserID,
            title: "Booking Request Declined",
            body: "Your request for \(route) was not approved by the driver. Try another ride!",
            type: .requestDenied
        )
    }

    func denyRequestAsync(requestID: UUID, hostUserID: UUID) async throws {
        try await RideRepository.shared.updateRequestStatus(id: requestID, status: .denied)
        denyRequest(requestID: requestID, hostUserID: hostUserID)
    }

    func cancelMyRequest(requestID: UUID, passengerUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]

        guard rq.passengerUserID == passengerUserID else { return }

        // Only allow cancelling pending requests here. If request was approved, passenger should cancel booking instead.
        guard rq.status == .pending else { return }

        rq.status = .cancelled
        rq.reviewedAt = Date()
        requests[rqIdx] = rq
        saveRequests()

        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
    }

    func cancelMyRequestAsync(requestID: UUID, passengerUserID: UUID) async throws {
        try await RideRepository.shared.updateRequestStatus(id: requestID, status: .cancelled)
        cancelMyRequest(requestID: requestID, passengerUserID: passengerUserID)
    }

    /// Cancel booking (by passenger or host) and return seats
    func cancelBooking(bookingID: UUID, by userID: UUID) {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        var bk = bookings[bIdx]
        guard var ride = getRide(bk.rideID) else { return }
        guard userID == bk.passengerUserID || userID == ride.driverUserID else { return }
        guard bk.status == .confirmed else { return }

        bk.status = .cancelled
        bookings[bIdx] = bk

        // Return seats to the ride (cap at seatsTotal)
        ride.seatsAvailable = min(ride.seatsTotal, ride.seatsAvailable + bk.seats)
        updateRide(ride)

        saveBookings()

        // ── Notify the driver if a passenger cancelled ──
        if userID == bk.passengerUserID {
            let passengerName = UserDataModel.shared.getUser(by: bk.passengerUserID)?.fullName ?? "A passenger"
            let from = ride.source.address ?? "Origin"
            let to   = ride.destination.address ?? "Destination"
            AppNotificationModel.shared.send(
                to: ride.driverUserID,
                title: "Booking Cancelled",
                body: "\(passengerName) cancelled their booking on your ride \(from) → \(to). A seat has been freed.",
                type: .passengerCancelled
            )
        }

        // Notify UI to update lists
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
    }

    func cancelBookingAsync(bookingID: UUID, by userID: UUID) async throws {
        try await RideRepository.shared.updateBookingStatus(id: bookingID, status: .cancelled)
        // Return seats in Supabase too
        if let booking = bookings.first(where: { $0.id == bookingID }),
           let ride = rides.first(where: { $0.id == booking.rideID }) {
            let restored = min(ride.seatsTotal, ride.seatsAvailable + booking.seats)
            try await RideRepository.shared.updateSeatsAvailable(rideID: ride.id, seats: restored)
        }
        cancelBooking(bookingID: bookingID, by: userID)
    }

    func ridesNear(_ point: LocationPoint, maxMeters: Double = 2500) -> [Ride] {
        func distM(_ a: LocationPoint, _ b: LocationPoint) -> Double {
            let dx = (a.lon - b.lon) * 111_320 * cos((a.lat + b.lat) * 0.5 * .pi / 180)
            let dy = (a.lat - b.lat) * 110_540
            return sqrt(dx*dx + dy*dy)
        }

        return rides
            .filter { $0.status == .published }
            .filter { distM($0.source, point) <= maxMeters }
            .sorted { $0.departureTime < $1.departureTime }
    }

    /// All rides driven by a user with a specific status (used by ReviewDataModel for total rides)
    func rides(driverID: UUID, status: RideStatus) -> [Ride] {
        rides.filter { $0.driverUserID == driverID && $0.status == status }
    }

    /// All completed rides where this user was a confirmed passenger
    func completedRides(passengerID: UUID) -> [Ride] {
        let confirmedRideIDs = bookings
            .filter { $0.passengerUserID == passengerID && $0.status == .confirmed }
            .map { $0.rideID }
        return rides.filter { confirmedRideIDs.contains($0.id) && $0.status == .completed }
    }


    // My Rides
    struct MyTrip: Equatable {
        enum Role { case hosting, passenger }
        var role: Role
        var ride: Ride
        
        // For passenger role: optional request id + status (nil for pure hosting role )
            var requestID: UUID?
            var requestStatus: RideRequestStatus?
    }

    func myUpcoming(userID: UUID, now: Date = Date()) -> [MyTrip] {
        reconcileAllRideStatuses(now: now)

        var out: [MyTrip] = []

        // Hosting: include published + ongoing (not completed or cancelled)
        out += rides
            .filter { $0.driverUserID == userID && ($0.status == .published || $0.status == .ongoing) }
            .map { MyTrip(role: .hosting, ride: $0, requestID: nil, requestStatus: nil) }

        // From confirmed bookings (passenger) - include if ride is published or ongoing (not completed/cancelled)
        let myBookings = bookings.filter { $0.passengerUserID == userID && $0.status == .confirmed }
        let passengerFromBookings: [MyTrip] = myBookings.compactMap { b in
            guard let ride = rides.first(where: { $0.id == b.rideID }) else { return nil }
            guard ride.status == .published || ride.status == .ongoing else { return nil }
            return MyTrip(role: .passenger, ride: ride, requestID: nil, requestStatus: .approved)
        }
        out += passengerFromBookings

        let bookingRideIDs = Set(passengerFromBookings.map { $0.ride.id })

        // Also track rides where the passenger has a CANCELLED booking —
        // we must not re-add them via the requests path (the approved request still exists).
        let cancelledBookingRideIDs = Set(
            bookings
                .filter { $0.passengerUserID == userID && $0.status == .cancelled }
                .compactMap { b in rides.first(where: { $0.id == b.rideID })?.id }
        )

        // From requests (pending/denied/etc.) — include if user requested it and request not cancelled,
        // and ride is published or ongoing
        let myReqs = requests.filter { $0.passengerUserID == userID }
        let passengerFromRequests: [MyTrip] = myReqs.compactMap { req in
            guard let ride = rides.first(where: { $0.id == req.rideID }) else { return nil }
            if bookingRideIDs.contains(ride.id) { return nil } // already added via confirmed booking
            if cancelledBookingRideIDs.contains(ride.id) { return nil } // booking was cancelled — show in Past
            // Exclude cancelled requests from Upcoming
            guard req.status != .cancelled else { return nil }
            guard ride.status == .published || ride.status == .ongoing else { return nil }
            return MyTrip(role: .passenger, ride: ride, requestID: req.id, requestStatus: req.status)
        }
        out += passengerFromRequests

        return out.sorted {
            // 1. Ongoing rides first
            if $0.ride.status != $1.ride.status {
                return $0.ride.status == .ongoing
            }
            // 2. Then by departure time
            return $0.ride.departureTime < $1.ride.departureTime
        }
    }

    
    func myPast(userID: UUID, now: Date = Date()) -> [MyTrip] {
        reconcileAllRideStatuses(now: now)

        var out: [MyTrip] = []
        var addedRideIDs = Set<UUID>()

        // Host: rides that are completed or cancelled
        out += rides
            .filter { $0.driverUserID == userID && ($0.status == .completed || $0.status == .cancelled) }
            .map { MyTrip(role: .hosting, ride: $0) }

        let myBookings = bookings.filter { $0.passengerUserID == userID }

        // Passenger: confirmed bookings where the ride itself ended (completed/cancelled)
        for b in myBookings where b.status == .confirmed {
            guard let ride = rides.first(where: { $0.id == b.rideID }) else { continue }
            guard ride.status == .completed || ride.status == .cancelled else { continue }
            guard !addedRideIDs.contains(ride.id) else { continue }
            out.append(MyTrip(role: .passenger, ride: ride, requestID: nil, requestStatus: .approved))
            addedRideIDs.insert(ride.id)
        }

        // Passenger: bookings the passenger themselves cancelled (ride may still be published/ongoing)
        // Show these as past with a cancelled-looking entry
        for b in myBookings where b.status == .cancelled {
            guard let ride = rides.first(where: { $0.id == b.rideID }) else { continue }
            guard !addedRideIDs.contains(ride.id) else { continue }
            // Snapshot the ride with .cancelled status so PastRideCell shows "Cancelled"
            var cancelledRide = ride
            cancelledRide.status = .cancelled
            out.append(MyTrip(role: .passenger, ride: cancelledRide, requestID: nil, requestStatus: .cancelled))
            addedRideIDs.insert(ride.id)
        }

        // Passenger cancelled requests (pending requests the user cancelled)
        let cancelledReqs = requests.filter { $0.passengerUserID == userID && $0.status == .cancelled }
        for req in cancelledReqs {
            guard let ride = rides.first(where: { $0.id == req.rideID }) else { continue }
            guard !addedRideIDs.contains(ride.id) else { continue }
            out.append(MyTrip(role: .passenger, ride: ride, requestID: req.id, requestStatus: req.status))
            addedRideIDs.insert(ride.id)
        }

        return out.sorted { $0.ride.departureTime > $1.ride.departureTime }
    }

    func listRidesHosted(by userID: UUID) -> [Ride] { rides.filter { $0.driverUserID == userID } }
    func listRequests(for rideID: UUID) -> [RideRequest] { requests.filter { $0.rideID == rideID } }
    func listBookings(for rideID: UUID) -> [Booking] { bookings.filter { $0.rideID == rideID } }
    func listMyBookings(userID: UUID) -> [Booking] { bookings.filter { $0.passengerUserID == userID } }

    /// Merges backend rides into local cache without deleting local drafts/request state.
    func mergeRemoteRides(_ incoming: [Ride]) {
        guard !incoming.isEmpty else { return }
        // BUG FIX: Always replace existing rides with the remote version so updated
        // seat counts and statuses from Supabase are never ignored by a stale local copy.
        // Local drafts are preserved because they won't appear in the remote list.
        let localDrafts = rides.filter { $0.status == .draft }
        let remoteIDs = Set(incoming.map { $0.id })
        // Keep only local drafts that haven't been published to Supabase yet
        var merged = localDrafts.filter { !remoteIDs.contains($0.id) }
        merged.append(contentsOf: incoming)
        rides = merged.sorted { $0.departureTime < $1.departureTime }
        saveRides()
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
    }

    private func loadAll() {
        rides = load([Ride].self, from: ridesURL) ?? []
        requests = load([RideRequest].self, from: requestsURL) ?? []
        bookings = load([Booking].self, from: bookingsURL) ?? []
    }
    private func saveRides()     { save(rides,    to: ridesURL) }
    private func saveRequests()  { save(requests, to: requestsURL) }
    private func saveBookings()  { save(bookings, to: bookingsURL) }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
                do {
                    let dec = JSONDecoder()
                    return try dec.decode(T.self, from: data)
                } catch {
                    print("JSON LOAD ERROR:", error)
                    return nil
                }
    }
    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
                    let enc = JSONEncoder()
                    enc.outputFormatting = [.prettyPrinted]
                    let data = try enc.encode(value)
                    try data.write(to: url, options: .atomic)
                } catch {
                    print("JSON SAVE ERROR:", error)
                }
    }
    
    
    private func reconcileAllRideStatuses(now: Date = Date()) {
        var changed = false
        var statusChanges: [(id: UUID, status: RideStatus)] = []

        for idx in rides.indices {
            var r = rides[idx]

            // Never touch draft, cancelled, or completed rides
            if r.status == .draft || r.status == .cancelled || r.status == .completed {
                continue
            }

            // Future rides → keep as published (but never reset a manually-started ongoing ride)
            if r.departureTime > now {
                if r.status == .ongoing { continue } // driver manually started — respect the decision
                if r.status != .published {
                    r.status = .published
                    rides[idx] = r
                    changed = true
                    statusChanges.append((id: r.id, status: .published))
                }
                continue
            }

            // Calculate end time
            let travelSeconds: TimeInterval
            if let route = r.selectedRoute {
                travelSeconds = route.expectedTravelTime
            } else {
                travelSeconds = 60 * 60   // 1-hour fallback
            }

            let endTime = r.departureTime.addingTimeInterval(travelSeconds)

            // After end time → Completed
            if now >= endTime {
                if r.status != .completed {
                    r.status = .completed
                    rides[idx] = r
                    changed = true
                    statusChanges.append((id: r.id, status: .completed))
                }
            } else {
                // Between start and end → Ongoing
                if r.status != .ongoing {
                    r.status = .ongoing
                    rides[idx] = r
                    changed = true
                    statusChanges.append((id: r.id, status: .ongoing))
                }
            }
        }

        if changed {
            saveRides()
            NotificationCenter.default.post(name: .ridesUpdated, object: nil)

            // BUG FIX: Sync the reconciled statuses back to Supabase so other users
            // always see the correct ride state (previously these changes were local-only).
            guard !statusChanges.isEmpty else { return }
            Task {
                for change in statusChanges {
                    try? await RideRepository.shared.updateRideStatus(id: change.id, status: change.status)
                }
            }
        }
    }

    
    

// Seed Mock Rides Once
    private static let mockDataSeedKey = "mock_rides_seeded_v2"

    func seedMockRidesIfNeeded() {
        // Do not seed mock rides if user is logged into Supabase
        guard !SessionManager.shared.isLoggedIn else { return }
        let mockIDs = Set(MockData.driverProfiles.map { $0.id })

        // Re-seed if there are no active (published/ongoing) mock rides left.
        // This ensures Rides Available never goes empty after a day passes.
        let hasActiveMockRides = rides.contains {
            mockIDs.contains($0.driverUserID) &&
            ($0.status == .published || $0.status == .ongoing)
        }
        if hasActiveMockRides { return }

        // Purge all stale mock rides (completed/cancelled from previous seed)
        rides.removeAll { mockIDs.contains($0.driverUserID) }
        saveRides()

        print("🌱 Re-seeding mock rides with fresh departure times...")

        for ride in MockData.sampleRides {
            let created = createRide(ride)
            publishRide(id: created.id)
        }

        UserDefaults.standard.set(true, forKey: RideDataModel.mockDataSeedKey)
        print("✅ Mock rides seeded — \(MockData.sampleRides.count) rides added.")
    }

    private func removeSeededMockRides() {
        let mockIDs = Set(MockData.driverProfiles.map { $0.id })
        let before = rides.count
        rides.removeAll { mockIDs.contains($0.driverUserID) }
        if rides.count != before {
            saveRides()
            NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        }
    }


}
