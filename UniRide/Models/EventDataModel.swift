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

        // loadAll()
        
        // Force mock data for demo purposes
        events = EventDataModel.mockEvents()
        saveEvents()
        
        // If app is first time OR JSON was empty → load mock data
        // if events.isEmpty {
        //     events = EventDataModel.mockEvents()
        //     saveEvents()
        // }
    }

    // MARK: - PUBLIC ACCESS
    func eventList() -> [EventItem] {
        return events
    }

    func updateEvent(_ event: EventItem) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
            saveEvents()
        }
    }

    /// Replaces event feed from backend payload.
    func replaceEventsFromBackend(_ incoming: [EventItem]) {
        guard !incoming.isEmpty else { return }
        events = incoming.sorted { $0.startsAt < $1.startsAt }
        saveEvents()
    }

    // MARK: - Mock Events (UI feed)
    static func mockEvents() -> [EventItem] {
        let user = UUID()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let rangrezDate = calendar.date(byAdding: .day, value: 5, to: baseDate) ?? baseDate
        let technoFestDate = calendar.date(byAdding: .day, value: 12, to: baseDate) ?? baseDate
        let sportsMeetDate = calendar.date(byAdding: .day, value: 19, to: baseDate) ?? baseDate
        let hackathonDate = calendar.date(byAdding: .day, value: 26, to: baseDate) ?? baseDate

        return [
            EventItem(
                createdByUserID: user,
                title: "Rangrez 2026",
                details: """
                Get ready for the most awaited cultural fest of the year! Rangrez 2026 is here to mesmerize you with a blend of art, music, and dance. 🎨✨
                
                Experience electrifying performances by top artists! From classical symphonies to rock fusion, we have it all. Don't miss the grand finale night featuring a surprise celebrity guest! 🎸🎤
                
                There will be food stalls offering cuisines from around the world, art exhibitions showcasing student talent, and interactive gaming zones. Come with your friends and make memories that will last a lifetime.
                
                📍 Venue: Chitkara University Main Ground
                🕒 Time: 4:00 PM onwards
                🎟️ Entry: Free for students with ID cards.
                
                This is more than just an event; it's a celebration of creativity and spirit. See you there!
                """,
                location: EventLocation(name: "Chitkara University"),
                startsAt: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: rangrezDate) ?? rangrezDate,
                imageName: "eventImage"
            ),

            EventItem(
                createdByUserID: user,
                title: "Techno Fest 2026",
                details: """
                Step into the future with Techno Fest 2026! 🚀
                
                Join us for a 3-day extravaganza of innovation and technology. Witness cutting-edge robotics, AI demonstrations, and coding marathons. 🤖💻
                
                Workshops on:
                - Blockchain Development
                - Ethical Hacking
                - Drone Racing
                
                The event concludes with an EDM night that will blow your mind! 🎧🔥
                
                Whether you are a tech geek or just curious, there is something for everyone. Network with industry leaders and win exciting prizes in our hackathons.
                """,
                location: EventLocation(name: "Chitkara University"),
                startsAt: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: technoFestDate) ?? technoFestDate,
                imageName: "eventImage2"
            ),
            
            EventItem(
                createdByUserID: user,
                title: "Sports Meet 2026",
                details: """
                Unleash your inner athlete at the Annual Sports Meet! 🏆
                
                Compete in a variety of sports including Cricket, Football, Basketball, Athletics, and Indoor Games. Show your team spirit and fight for glory! 🏏⚽️🏀
                
                Registration is open now at the Sports Complex.
                """,
                location: EventLocation(name: "Sports Complex"),
                startsAt: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: sportsMeetDate) ?? sportsMeetDate,
                imageName: "eventImage3"
            ),
            
            EventItem(
                createdByUserID: user,
                title: "Hackathon 2026",
                details: """
                Code your way to glory in our 24-hour Hackathon! 💻☕️
                
                Build innovative solutions to real-world problems. Mentors from top tech companies will be there to guide you.
                
                Prizes worth ₹50,000 to be won!
                """,
                location: EventLocation(name: "Engineering Block"),
                startsAt: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: hackathonDate) ?? hackathonDate,
                imageName: "eventImage4"
            )
        ]
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
