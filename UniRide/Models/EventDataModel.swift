//
//  EventDataModel.swift
//  UniRide
//
//  Created by Air on 11/11/25.
//

import Foundation

// MARK: - Event Location
struct EventLocation: Codable, Equatable {
    var name: String
    var lat: Double?
    var lon: Double?
}

// MARK: - Event
struct EventItem: Codable, Equatable {
    let id: UUID
    let createdByUserID: UUID
    var title: String
    var details: String?
    var location: EventLocation?
    var startsAt: Date
    var endsAt: Date?

    // UI counters
    var attendeeCount: Int
    var dayScholarCount: Int

    // NEW for UI
    var imageName: String?       // event poster
    var shareCount: Int          // count of shares in community feed

    init(createdByUserID: UUID,
         title: String,
        details: String? = nil,
         location: EventLocation? = nil,
         startsAt: Date,
         endsAt: Date? = nil,
         imageName: String? = nil) {

        self.id = UUID()
        self.createdByUserID = createdByUserID
        self.title = title
        self.details = details
        self.location = location
        self.startsAt = startsAt
        self.endsAt = endsAt

        // UI counters
        self.attendeeCount = 0
        self.dayScholarCount = 0
        self.imageName = imageName
        self.shareCount = 0
    }

    init(id: UUID,
         createdByUserID: UUID,
         title: String,
         details: String? = nil,
         location: EventLocation? = nil,
         startsAt: Date,
         endsAt: Date? = nil,
         attendeeCount: Int = 0,
         dayScholarCount: Int = 0,
         imageName: String? = nil,
         shareCount: Int = 0) {
        self.id = id
        self.createdByUserID = createdByUserID
        self.title = title
        self.details = details
        self.location = location
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.attendeeCount = attendeeCount
        self.dayScholarCount = dayScholarCount
        self.imageName = imageName
        self.shareCount = shareCount
    }

    static func ==(lhs: EventItem, rhs: EventItem) -> Bool { lhs.id == rhs.id }
}


// MARK: - Attendance
struct EventAttendance: Codable, Equatable {
    let id: UUID
    let eventID: UUID
    let userID: UUID
    let createdAt: Date
    var isDayScholar: Bool

    init(eventID: UUID, userID: UUID, isDayScholar: Bool) {
        self.id = UUID()
        self.eventID = eventID
        self.userID = userID
        self.createdAt = Date()
        self.isDayScholar = isDayScholar
    }

    static func ==(lhs: EventAttendance, rhs: EventAttendance) -> Bool { lhs.id == rhs.id }
}


// MARK: - Main Data Model (JSON persistence)
final class EventDataModel {

    static let shared = EventDataModel()

    // Storage
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let eventsURL: URL
    private let attendanceURL: URL

    // In-memory storage
    private var events: [EventItem] = []
    private var attendance: [EventAttendance] = []

    private init() {
        eventsURL = documentsDirectory.appendingPathComponent("community_events.json")
        attendanceURL = documentsDirectory.appendingPathComponent("community_event_attendance.json")

        loadAll()
    }

    // MARK: - PUBLIC ACCESS
    func eventList() -> [EventItem] {
        return events
    }

    @discardableResult
    func addEvent(_ event: EventItem) -> EventItem {
        events.insert(event, at: 0)
        events.sort { $0.startsAt < $1.startsAt }
        saveEvents()
        return event
    }

    func updateEvent(_ event: EventItem) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
            events.sort { $0.startsAt < $1.startsAt }
            saveEvents()
        }
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        attendance.removeAll { $0.eventID == id }
        saveEvents()
        saveAttendance()
    }

    /// Replaces event feed from backend payload.
    func replaceEventsFromBackend(_ incoming: [EventItem]) {
        guard !incoming.isEmpty else { return }
        events = incoming.sorted { $0.startsAt < $1.startsAt }
        saveEvents()
    }

    // MARK: - Attendance
    func attend(eventID: UUID, userID: UUID, isDayScholar: Bool) {
        guard !attendance.contains(where: { $0.eventID == eventID && $0.userID == userID }),
              let i = events.firstIndex(where: { $0.id == eventID }) else { return }

        attendance.append(EventAttendance(eventID: eventID, userID: userID, isDayScholar: isDayScholar))

        var e = events[i]
        e.attendeeCount += 1
        if isDayScholar { e.dayScholarCount += 1 }
        events[i] = e

        saveAttendance()
        saveEvents()
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

        saveAttendance()
        saveEvents()
    }

    // MARK: - Persistence
    private func loadAll() {
        events = load([EventItem].self, from: eventsURL) ?? []
        attendance = load([EventAttendance].self, from: attendanceURL) ?? []
    }

    private func saveEvents()     { save(events, to: eventsURL) }
    private func saveAttendance() { save(attendance, to: attendanceURL) }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to load JSON:", error)
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save JSON:", error)
        }
    }
}
