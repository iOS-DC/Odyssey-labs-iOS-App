import Foundation

private struct RemoteEvent: Decodable {
    let id: String
    let createdByUserID: String
    let title: String
    let details: String?
    let locationName: String?
    let startsAt: String
    let endsAt: String?
    let attendeeCount: Int?
    let dayScholarCount: Int?
    let imageName: String?
    let shareCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case createdByUserID = "created_by_user_id"
        case title
        case details
        case locationName = "location_name"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case attendeeCount = "attendee_count"
        case dayScholarCount = "day_scholar_count"
        case imageName = "image_name"
        case shareCount = "share_count"
    }
}

private struct EventPayload: Encodable {
    let id: String?
    let createdByUserID: String
    let title: String
    let details: String?
    let locationName: String?
    let startsAt: String
    let endsAt: String?
    let attendeeCount: Int
    let dayScholarCount: Int
    let imageName: String?
    let shareCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdByUserID = "created_by_user_id"
        case title
        case details
        case locationName = "location_name"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case attendeeCount = "attendee_count"
        case dayScholarCount = "day_scholar_count"
        case imageName = "image_name"
        case shareCount = "share_count"
    }
}

final class EventsAPI {
    static let shared = EventsAPI()

    private let client: APIClient
    private let iso = ISO8601DateFormatter()

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchTopEvents(limit: Int = 5) async throws -> [EventItem] {
        let endpoint = APIEndpoint(
            path: "/rest/v1/events?select=id,created_by_user_id,title,details,location_name,starts_at,ends_at,attendee_count,day_scholar_count,image_name,share_count&order=starts_at.asc&limit=\(max(1, limit))",
            method: "GET"
        )
        let payload: [RemoteEvent] = try await client.send(endpoint, as: [RemoteEvent].self)

        return payload.compactMap { remote in
            guard let eventID = UUID(uuidString: remote.id),
                  let createdBy = UUID(uuidString: remote.createdByUserID),
                  let startsAt = iso.date(from: remote.startsAt) else {
                return nil
            }

            return EventItem(
                id: eventID,
                createdByUserID: createdBy,
                title: remote.title,
                details: remote.details,
                location: EventLocation(name: remote.locationName ?? "Campus"),
                startsAt: startsAt,
                endsAt: remote.endsAt.flatMap { iso.date(from: $0) },
                attendeeCount: max(0, remote.attendeeCount ?? 0),
                dayScholarCount: max(0, remote.dayScholarCount ?? 0),
                imageName: remote.imageName,
                shareCount: max(0, remote.shareCount ?? 0)
            )
        }
    }

    func incrementShareCount(eventID: UUID, currentCount: Int) async throws -> Int {
        let newCount = currentCount + 1
        let endpoint = APIEndpoint(
            path: "/rest/v1/events?id=eq.\(eventID.uuidString)",
            method: "PATCH",
            body: try JSONSerialization.data(withJSONObject: ["share_count": newCount])
        )
        
        // Supabase PATCH returns 204 No Content by default unless Prefer: return=representation is set.
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
        return newCount
    }

    func createEvent(_ event: EventItem) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/events",
            method: "POST",
            headers: ["Prefer": "return=minimal"],
            body: try client.encodeBody(payload(for: event, includeID: true))
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func updateEvent(_ event: EventItem) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/events?id=eq.\(event.id.uuidString)",
            method: "PATCH",
            headers: ["Prefer": "return=minimal"],
            body: try client.encodeBody(payload(for: event, includeID: false))
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func deleteEvent(eventID: UUID) async throws {
        let endpoint = APIEndpoint(
            path: "/rest/v1/events?id=eq.\(eventID.uuidString)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    private func payload(for event: EventItem, includeID: Bool) -> EventPayload {
        EventPayload(
            id: includeID ? event.id.uuidString : nil,
            createdByUserID: event.createdByUserID.uuidString,
            title: event.title,
            details: event.details,
            locationName: event.location?.name,
            startsAt: iso.string(from: event.startsAt),
            endsAt: event.endsAt.map { iso.string(from: $0) },
            attendeeCount: event.attendeeCount,
            dayScholarCount: event.dayScholarCount,
            imageName: event.imageName,
            shareCount: event.shareCount
        )
    }
}
