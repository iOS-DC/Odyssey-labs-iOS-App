//
//  EventDataModel.swift
//  UniRide
//
//  Created by Air on 11/11/25.
//

import Foundation
// MARK: - Event Location (name + optional coords if you want to use maps later)
struct EventLocation: Codable, Equatable {
    var name: String                 // e.g., "Block A Auditorium"
    var lat: Double?                 // optional (for future: map search / rides)
    var lon: Double?
}

// MARK: - Event
struct EventItem: Codable, Equatable {
    let id: UUID
    let createdByUserID: UUID
    var title: String                // "TEDx Chitkara"
    var details: String?             // description / agenda
    var location: EventLocation?     // where
    var startsAt: Date               // date & time
    var endsAt: Date?                // optional end time

    // Fast UI counters (denormalized)
    var attendeeCount: Int
    var dayScholarCount: Int

    init(createdByUserID: UUID,
         title: String,
         details: String? = nil,
         location: EventLocation? = nil,
         startsAt: Date,
         endsAt: Date? = nil) {
        self.id = UUID()
        self.createdByUserID = createdByUserID
        self.title = title
        self.details = details
        self.location = location
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.attendeeCount = 0
        self.dayScholarCount = 0
    }

    static func ==(lhs: EventItem, rhs: EventItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Attendance
struct EventAttendance: Codable, Equatable {
    let id: UUID
    let eventID: UUID
    let userID: UUID
    let createdAt: Date
    var isDayScholar: Bool           // required for your use-case

    init(eventID: UUID, userID: UUID, isDayScholar: Bool) {
        self.id = UUID()
        self.eventID = eventID
        self.userID = userID
        self.createdAt = Date()
        self.isDayScholar = isDayScholar
    }

    static func ==(lhs: EventAttendance, rhs: EventAttendance) -> Bool { lhs.id == rhs.id }
}

// MARK: - Singleton store (plist-backed)
final class EventDataModel {

    static let shared = EventDataModel()

    // Files
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let eventsURL: URL
    private let attendanceURL: URL

    // In-memory
    private var events: [EventItem] = []
    private var attendance: [EventAttendance] = []

    private init() {
        eventsURL = documentsDirectory.appendingPathComponent("community_events").appendingPathExtension("json")
        attendanceURL = documentsDirectory.appendingPathComponent("community_event_attendance").appendingPathExtension("json")
        loadAll()
    }

    // MARK: - Event CRUD

    @discardableResult
    func createEvent(createdByUserID: UUID,
                     title: String,
                     details: String? = nil,
                     location: EventLocation? = nil,
                     startsAt: Date,
                     endsAt: Date? = nil) -> EventItem {
        let e = EventItem(createdByUserID: createdByUserID,
                          title: title,
                          details: details,
                          location: location,
                          startsAt: startsAt,
                          endsAt: endsAt)
        events.append(e)
        saveEvents()
        return e
    }

    func editEvent(id: UUID,
                   title: String? = nil,
                   details: String? = nil,
                   location: EventLocation? = nil,
                   startsAt: Date? = nil,
                   endsAt: Date? = nil) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        var e = events[i]
        if let v = title     { e.title = v }
        if let v = details   { e.details = v }
        if let v = location  { e.location = v }
        if let v = startsAt  { e.startsAt = v }
        if let v = endsAt    { e.endsAt = v }
        events[i] = e
        saveEvents()
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        attendance.removeAll { $0.eventID == id }
        saveEvents(); saveAttendance()
    }

    func getEvent(id: UUID) -> EventItem? { events.first(where: { $0.id == id }) }

    func listUpcoming(now: Date = Date()) -> [EventItem] {
        events
            .filter { ($0.endsAt ?? $0.startsAt) >= now }
            .sorted { $0.startsAt < $1.startsAt }
    }

    func listPast(now: Date = Date()) -> [EventItem] {
        events
            .filter { ($0.endsAt ?? $0.startsAt) < now }
            .sorted { $0.startsAt > $1.startsAt }
    }

    // MARK: - Attendance (+1 day scholar / hostel)

    func isAttending(eventID: UUID, userID: UUID) -> Bool {
        attendance.contains { $0.eventID == eventID && $0.userID == userID }
    }

    /// Mark attending; pass `isDayScholar` from your UI (toggle or from profile)
    func attend(eventID: UUID, userID: UUID, isDayScholar: Bool) {
        guard !isAttending(eventID: eventID, userID: userID),
              let i = events.firstIndex(where: { $0.id == eventID }) else { return }
        attendance.append(EventAttendance(eventID: eventID, userID: userID, isDayScholar: isDayScholar))
        var e = events[i]
        e.attendeeCount += 1
        if isDayScholar { e.dayScholarCount += 1 }
        events[i] = e
        saveAttendance(); saveEvents()
    }

    func unattend(eventID: UUID, userID: UUID) {
        guard let idx = attendance.firstIndex(where: { $0.eventID == eventID && $0.userID == userID }),
              let i = events.firstIndex(where: { $0.id == eventID }) else { return }
        let wasDayScholar = attendance[idx].isDayScholar
        attendance.remove(at: idx)
        var e = events[i]
        e.attendeeCount = max(0, e.attendeeCount - 1)
        if wasDayScholar { e.dayScholarCount = max(0, e.dayScholarCount - 1) }
        events[i] = e
        saveAttendance(); saveEvents()
    }

    func attendees(for eventID: UUID) -> [EventAttendance] {
        attendance
            .filter { $0.eventID == eventID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func counts(for eventID: UUID) -> (total: Int, dayScholars: Int) {
        guard let e = getEvent(id: eventID) else { return (0,0) }
        return (e.attendeeCount, e.dayScholarCount)
    }

    // MARK: - Persistence

    // MARK: - Persistence

    private func loadAll() {
        events = load([EventItem].self, from: eventsURL) ?? []
        attendance = load([EventAttendance].self, from: attendanceURL) ?? []
    }

    private func saveEvents()     { save(events, to: eventsURL) }
    private func saveAttendance() { save(attendance, to: attendanceURL) }

    // MARK: - JSON load/save
    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to load JSON:", error)
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save JSON:", error)
        }
    }

}
