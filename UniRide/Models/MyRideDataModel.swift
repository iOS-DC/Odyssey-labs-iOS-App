//
//  ride.swift
//  UniRide
//
//  Created by Air on 11/11/25.
//
extension Notification.Name {
    static let rideRequestsUpdated = Notification.Name("rideRequestsUpdated")
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
    }

    
    @discardableResult  //prevents unnecessary warnings like function is unused
    func createRide(_ ride: Ride) -> Ride {
        rides.append(ride); saveRides(); return ride
    }
    func getAllRides() -> [Ride] {
        return rides
    }

    func getRide(_ id: UUID) -> Ride? {
        rides.first { $0.id == id }
    }

    func updateRide(_ updated: Ride) {
        guard let i = rides.firstIndex(where: { $0.id == updated.id }) else { return }
        rides[i] = updated; saveRides()
    }

    func publishRide(id: UUID) {
        guard var r = getRide(id) else { return }
        guard r.status == .draft || r.status == .cancelled else { return }
        r.status = .published; updateRide(r)
    }

    func cancelRide(id: UUID) {
        guard var r = getRide(id) else { return }
        r.status = .cancelled; updateRide(r)
    }

    func deleteRide(id: UUID) {
        rides.removeAll { $0.id == id }
        requests.removeAll { $0.rideID == id }
        bookings.removeAll { $0.rideID == id }
        saveRides(); saveRequests(); saveBookings()
    }

    @discardableResult   //prevents unnecessary warnings like function is unused
    func createJoinRequest(_ req: RideRequest) -> RideRequest {
        requests.append(req); saveRequests(); return req
    }

    /// Host approves: moves seats, creates booking
    func approveRequest(requestID: UUID, hostUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]
        guard var ride = getRide(rq.rideID) else { return }
        guard ride.driverUserID == hostUserID else { return }
        guard ride.status == .published else { return }
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
        saveRequests(); saveBookings()
    }

    func denyRequest(requestID: UUID, hostUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]
        guard let ride = getRide(rq.rideID), ride.driverUserID == hostUserID else { return }
        rq.status = .denied
        rq.reviewedAt = Date()
        requests[rqIdx] = rq
        saveRequests()
    }

    func cancelMyRequest(requestID: UUID, passengerUserID: UUID) {
        guard let rqIdx = requests.firstIndex(where: { $0.id == requestID }) else { return }
        var rq = requests[rqIdx]
        guard rq.passengerUserID == passengerUserID else { return }
        guard rq.status == .pending else { return }
        rq.status = .cancelled
        rq.reviewedAt = Date()
        requests[rqIdx] = rq
        saveRequests()
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
        ride.seatsAvailable = min(ride.seatsTotal, ride.seatsAvailable + bk.seats)
        updateRide(ride)
        saveBookings()
    }

    func ridesNear(_ point: LocationPoint, maxMeters: Double = 1200) -> [Ride] {
        // simple proximity using a naive flat-earth approximation (good enough for campus)
        func distM(_ a: LocationPoint, _ b: LocationPoint) -> Double {
            let dx = (a.lon - b.lon) * 111_320 * cos((a.lat + b.lat) * 0.5 * .pi / 180)
            let dy = (a.lat - b.lat) * 110_540
            return sqrt(dx*dx + dy*dy)
        }
        return rides
            .filter { $0.status == .published }
            .filter { r in
                let c = [r.source] + r.waypoints + [r.destination]
                return c.contains { distM($0, point) <= maxMeters }
            }
            .sorted { $0.departureTime < $1.departureTime }
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
        var out: [MyTrip] = []

           // Hosting
           out += rides
               .filter { $0.driverUserID == userID && $0.status != .completed && $0.status != .cancelled && $0.departureTime >= now }
               .map { MyTrip(role: .hosting, ride: $0, requestID: nil, requestStatus: nil)
               }

           // From confirmed bookings
           let myBookings = bookings.filter { $0.passengerUserID == userID && $0.status == .confirmed }
           let passengerFromBookings: [MyTrip] = myBookings.compactMap { b in
               guard let ride = rides.first(where: { $0.id == b.rideID }) else { return nil }
               guard ride.status != .completed && ride.status != .cancelled && ride.departureTime >= now else { return nil }
               return MyTrip(role: .passenger, ride: ride, requestID: nil, requestStatus: .approved)
           }
           out += passengerFromBookings

           let bookingRideIDs = Set(passengerFromBookings.map { $0.ride.id })

           // From requests (pending/denied/etc.) — include if user requested it
           let myReqs = requests.filter { $0.passengerUserID == userID }
           let passengerFromRequests: [MyTrip] = myReqs.compactMap { req in
               guard let ride = rides.first(where: { $0.id == req.rideID }) else { return nil }
               if bookingRideIDs.contains(ride.id) { return nil } // already added via booking
               guard ride.status != .completed && ride.status != .cancelled && ride.departureTime >= now else { return nil }
               return MyTrip(role: .passenger, ride: ride, requestID: req.id, requestStatus: req.status)
           }
           out += passengerFromRequests

           return out.sorted { $0.ride.departureTime < $1.ride.departureTime }
       }
    
    
    func myPast(userID: UUID, now: Date = Date()) -> [MyTrip] {
        var out: [MyTrip] = []

        out += rides
            .filter { $0.driverUserID == userID && ($0.status == .completed || $0.departureTime < now) }
            .map { MyTrip(role: .hosting, ride: $0) }

        let myB = bookings.filter { $0.passengerUserID == userID }
        out += myB.compactMap { b in rides.first { $0.id == b.rideID } }
            .filter { $0.departureTime < now || $0.status == .completed || $0.status == .cancelled }
            .map { MyTrip(role: .passenger, ride: $0) }

        return out.sorted { $0.ride.departureTime > $1.ride.departureTime }
    }

    func listRidesHosted(by userID: UUID) -> [Ride] { rides.filter { $0.driverUserID == userID } }
    func listRequests(for rideID: UUID) -> [RideRequest] { requests.filter { $0.rideID == rideID } }
    func listBookings(for rideID: UUID) -> [Booking] { bookings.filter { $0.rideID == rideID } }
    func listMyBookings(userID: UUID) -> [Booking] { bookings.filter { $0.passengerUserID == userID } }

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
}


