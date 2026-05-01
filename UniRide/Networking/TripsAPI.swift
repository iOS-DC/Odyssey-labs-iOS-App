import Foundation

// MARK: - Wire types

private struct RemoteItineraryDay: Codable {
    let title: String
    let activities: [String]
}

private struct RemoteTrip: Decodable {
    let id: String
    let createdByUserID: String
    let title: String
    let location: String
    let dateRange: String
    let startDate: String
    let endDate: String?
    let price: Int
    let spotsTotal: Int
    let spotsLeft: Int
    let organizer: String
    let imageName: String?
    let about: String?
    let itineraryJson: [RemoteItineraryDay]?
    let inclusions: String?
    let exclusions: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case createdByUserID = "created_by_user_id"
        case title
        case location
        case dateRange = "date_range"
        case startDate = "start_date"
        case endDate = "end_date"
        case price
        case spotsTotal = "spots_total"
        case spotsLeft = "spots_left"
        case organizer
        case imageName = "image_name"
        case about
        case itineraryJson = "itinerary_json"
        case inclusions
        case exclusions
        case isActive = "is_active"
    }
}

private struct TripPayload: Encodable {
    let id: String?
    let createdByUserID: String
    let title: String
    let location: String
    let dateRange: String
    let startDate: String
    let endDate: String?
    let price: Int
    let spotsTotal: Int
    let spotsLeft: Int
    let organizer: String
    let imageName: String?
    let about: String?
    let itineraryJson: [RemoteItineraryDay]?
    let inclusions: String?
    let exclusions: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case createdByUserID = "created_by_user_id"
        case title
        case location
        case dateRange = "date_range"
        case startDate = "start_date"
        case endDate = "end_date"
        case price
        case spotsTotal = "spots_total"
        case spotsLeft = "spots_left"
        case organizer
        case imageName = "image_name"
        case about
        case itineraryJson = "itinerary_json"
        case inclusions
        case exclusions
        case isActive = "is_active"
    }
}

// MARK: - API

final class TripsAPI {
    static let shared = TripsAPI()

    private let client: APIClient
    private let iso = ISO8601DateFormatter()

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchTrips() async throws -> [Trip] {
        let endpoint = APIEndpoint(
            path: "/rest/v1/trips?select=*&is_active=eq.true&order=start_date.asc",
            method: "GET"
        )
        let payload: [RemoteTrip] = try await client.send(endpoint, as: [RemoteTrip].self)
        return payload.compactMap { map($0) }
    }

    func createTrip(_ trip: Trip) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/trips",
            method: "POST",
            headers: ["Prefer": "return=minimal"],
            body: try client.encodeBody(payload(for: trip, includeID: true))
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func updateTrip(_ trip: Trip) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/trips?id=eq.\(trip.id.uuidString)",
            method: "PATCH",
            headers: ["Prefer": "return=minimal"],
            body: try client.encodeBody(payload(for: trip, includeID: false))
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func deleteTrip(tripID: UUID) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/trips?id=eq.\(tripID.uuidString)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    // MARK: - Mapping

    private func map(_ remote: RemoteTrip) -> Trip? {
        guard let tripID = UUID(uuidString: remote.id),
              let startDate = iso.date(from: remote.startDate) else { return nil }

        let itinerary: [ItineraryDay] = remote.itineraryJson?.map {
            ItineraryDay(title: $0.title, activities: $0.activities)
        } ?? []

        let inclusions = remote.inclusions.map { parseLines($0) } ?? []
        let exclusions = remote.exclusions.map { parseLines($0) } ?? []

        return Trip(
            id: tripID,
            title: remote.title,
            location: remote.location,
            dateRange: remote.dateRange,
            startDate: startDate,
            price: remote.price,
            spotsLeft: remote.spotsLeft,
            organizer: remote.organizer,
            imageName: remote.imageName ?? "eventImage",
            about: remote.about ?? "",
            itinerary: itinerary,
            inclusions: inclusions,
            exclusions: exclusions,
            isPast: startDate < Date()
        )
    }

    private func payload(for trip: Trip, includeID: Bool) -> TripPayload {
        let itineraryDays = trip.itinerary.map {
            RemoteItineraryDay(title: $0.title, activities: $0.activities)
        }
        return TripPayload(
            id: includeID ? trip.id.uuidString : nil,
            createdByUserID: "00000000-0000-0000-0000-000000000001",
            title: trip.title,
            location: trip.location,
            dateRange: trip.dateRange,
            startDate: iso.string(from: trip.startDate),
            endDate: nil,
            price: trip.price,
            spotsTotal: trip.spotsLeft,
            spotsLeft: trip.spotsLeft,
            organizer: trip.organizer,
            imageName: trip.imageName,
            about: trip.about,
            itineraryJson: itineraryDays.isEmpty ? nil : itineraryDays,
            inclusions: trip.inclusions.isEmpty ? nil : trip.inclusions.joined(separator: "\n"),
            exclusions: trip.exclusions.isEmpty ? nil : trip.exclusions.joined(separator: "\n"),
            isActive: true
        )
    }

    private func parseLines(_ text: String) -> [String] {
        text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
