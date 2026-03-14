import Foundation

private struct RemoteRide: Decodable {
    let id: String
    let driverUserID: String
    let sourceLat: Double
    let sourceLon: Double
    let sourceAddress: String?
    let destinationLat: Double
    let destinationLon: Double
    let destinationAddress: String?
    let departureTime: String
    let seatsTotal: Int
    let seatsAvailable: Int
    let farePerSeat: Double
    let status: String
    let notes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case driverUserID = "driver_user_id"
        case sourceLat = "source_lat"
        case sourceLon = "source_lon"
        case sourceAddress = "source_address"
        case destinationLat = "destination_lat"
        case destinationLon = "destination_lon"
        case destinationAddress = "destination_address"
        case departureTime = "departure_time"
        case seatsTotal = "seats_total"
        case seatsAvailable = "seats_available"
        case farePerSeat = "fare_per_seat"
        case status
        case notes
        case createdAt = "created_at"
    }
}

private struct CreateRideRequest: Encodable {
    let id: String
    let driverUserID: String
    let sourceLat: Double
    let sourceLon: Double
    let sourceAddress: String?
    let destinationLat: Double
    let destinationLon: Double
    let destinationAddress: String?
    let departureTime: String
    let seatsTotal: Int
    let seatsAvailable: Int
    let farePerSeat: Double
    let status: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case driverUserID = "driver_user_id"
        case sourceLat = "source_lat"
        case sourceLon = "source_lon"
        case sourceAddress = "source_address"
        case destinationLat = "destination_lat"
        case destinationLon = "destination_lon"
        case destinationAddress = "destination_address"
        case departureTime = "departure_time"
        case seatsTotal = "seats_total"
        case seatsAvailable = "seats_available"
        case farePerSeat = "fare_per_seat"
        case status
        case notes
    }
}

private struct RideStatusPatch: Encodable {
    let status: String
}

private struct JoinRequestPayload: Encodable {
    let id: String
    let rideID: String
    let passengerUserID: String
    let pickupLat: Double
    let pickupLon: Double
    let pickupAddress: String?
    let seats: Int
    let minAcceptableFare: Double?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case rideID = "ride_id"
        case passengerUserID = "passenger_user_id"
        case pickupLat = "pickup_lat"
        case pickupLon = "pickup_lon"
        case pickupAddress = "pickup_address"
        case seats
        case minAcceptableFare = "min_acceptable_fare"
        case status
    }
}

private struct RideRequestStatusPatch: Encodable {
    let status: String
    let reviewedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case reviewedAt = "reviewed_at"
    }
}

private struct BookingStatusPatch: Encodable {
    let status: String
}

final class RidesAPI {
    static let shared = RidesAPI()

    private let client: APIClient
    private let iso = ISO8601DateFormatter()

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchPublishedRides() async throws -> [Ride] {
        let endpoint = APIEndpoint(
            path: "/rest/v1/rides?select=id,driver_user_id,source_lat,source_lon,source_address,destination_lat,destination_lon,destination_address,departure_time,seats_total,seats_available,fare_per_seat,status,notes,created_at&status=in.(published,ongoing)&order=departure_time.asc",
            method: "GET"
        )
        let payload: [RemoteRide] = try await client.send(endpoint, as: [RemoteRide].self)

        return payload.compactMap { remote in
            guard let rideID = UUID(uuidString: remote.id),
                  let driverID = UUID(uuidString: remote.driverUserID),
                  let departureTime = iso.date(from: remote.departureTime),
                  let status = RideStatus(rawValue: remote.status) else {
                return nil
            }

            let source = LocationPoint(lat: remote.sourceLat, lon: remote.sourceLon, address: remote.sourceAddress)
            let destination = LocationPoint(lat: remote.destinationLat, lon: remote.destinationLon, address: remote.destinationAddress)

            return Ride(
                id: rideID,
                driverUserID: driverID,
                source: source,
                destination: destination,
                waypoints: [],
                selectedRoute: nil,
                departureTime: departureTime,
                seatsTotal: remote.seatsTotal,
                seatsAvailable: remote.seatsAvailable,
                farePerSeat: remote.farePerSeat,
                status: status,
                notes: remote.notes,
                createdAt: remote.createdAt.flatMap { iso.date(from: $0) } ?? Date()
            )
        }
    }

    func createRide(_ ride: Ride) async throws {
        let payload = CreateRideRequest(
            id: ride.id.uuidString.lowercased(),
            driverUserID: ride.driverUserID.uuidString.lowercased(),
            sourceLat: ride.source.lat,
            sourceLon: ride.source.lon,
            sourceAddress: ride.source.address,
            destinationLat: ride.destination.lat,
            destinationLon: ride.destination.lon,
            destinationAddress: ride.destination.address,
            departureTime: iso.string(from: ride.departureTime),
            seatsTotal: ride.seatsTotal,
            seatsAvailable: ride.seatsAvailable,
            farePerSeat: ride.farePerSeat,
            status: ride.status.rawValue,
            notes: ride.notes
        )
        let body = try client.encodeBody(payload)
        let endpoint = APIEndpoint(
            path: "/rest/v1/rides",
            method: "POST",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func publishRide(id: UUID) async throws {
        try await updateRideStatus(rideID: id, status: .published)
    }

    func createJoinRequest(_ request: RideRequest) async throws {
        let payload = JoinRequestPayload(
            id: request.id.uuidString.lowercased(),
            rideID: request.rideID.uuidString.lowercased(),
            passengerUserID: request.passengerUserID.uuidString.lowercased(),
            pickupLat: request.pickupPoint.lat,
            pickupLon: request.pickupPoint.lon,
            pickupAddress: request.pickupPoint.address,
            seats: request.seats,
            minAcceptableFare: request.minAcceptableFare,
            status: request.status.rawValue
        )
        let body = try client.encodeBody(payload)
        let endpoint = APIEndpoint(
            path: "/rest/v1/ride_requests",
            method: "POST",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func approveRequest(requestID: UUID, rideID: UUID) async throws {
        _ = rideID
        try await updateRideRequestStatus(requestID: requestID, status: .approved)
    }

    func denyRequest(requestID: UUID, rideID: UUID) async throws {
        _ = rideID
        try await updateRideRequestStatus(requestID: requestID, status: .denied)
    }

    func cancelRide(rideID: UUID) async throws {
        try await updateRideStatus(rideID: rideID, status: .cancelled)
    }

    func startRide(rideID: UUID) async throws {
        try await updateRideStatus(rideID: rideID, status: .ongoing)
    }

    func endRide(rideID: UUID) async throws {
        try await updateRideStatus(rideID: rideID, status: .completed)
    }

    func cancelBooking(bookingID: UUID, rideID: UUID) async throws {
        _ = rideID
        let body = try client.encodeBody(BookingStatusPatch(status: BookingStatus.cancelled.rawValue))
        let endpoint = APIEndpoint(
            path: "/rest/v1/ride_bookings?id=eq.\(bookingID.uuidString.lowercased())",
            method: "PATCH",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func cancelRequest(requestID: UUID, rideID: UUID) async throws {
        _ = rideID
        try await updateRideRequestStatus(requestID: requestID, status: .cancelled)
    }

    private func updateRideStatus(rideID: UUID, status: RideStatus) async throws {
        let body = try client.encodeBody(RideStatusPatch(status: status.rawValue))
        let endpoint = APIEndpoint(
            path: "/rest/v1/rides?id=eq.\(rideID.uuidString.lowercased())",
            method: "PATCH",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    private func updateRideRequestStatus(requestID: UUID, status: RideRequestStatus) async throws {
        let payload = RideRequestStatusPatch(status: status.rawValue, reviewedAt: iso.string(from: Date()))
        let body = try client.encodeBody(payload)
        let endpoint = APIEndpoint(
            path: "/rest/v1/ride_requests?id=eq.\(requestID.uuidString.lowercased())",
            method: "PATCH",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }
}
