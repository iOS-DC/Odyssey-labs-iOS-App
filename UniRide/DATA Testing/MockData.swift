//
//  MockData.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 20/11/25.
//


import Foundation

struct MockData {
}

extension MockData {

    static func mockRidesForEvent(_ event: EventItem) -> [Ride] {
        let mockDriverIDs: [UUID] = [
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        ]
        
        var rides: [Ride] = []
        let count = Int.random(in: 5...8)
        
        for _ in 0..<count {
            let driverID = mockDriverIDs.randomElement()!
            
            let sources = [
                LocationPoint(lat: 30.7046, lon: 76.7179, address: "Sector 17, Chandigarh"),
                LocationPoint(lat: 30.7410, lon: 76.7565, address: "Elante Mall"),
                LocationPoint(lat: 30.6520, lon: 76.8227, address: "Sector 82, Mohali"),
                LocationPoint(lat: 30.7350, lon: 76.8010, address: "Phase 5, Mohali"),
                LocationPoint(lat: 30.6637, lon: 76.8371, address: "Zirakpur"),
                LocationPoint(lat: 30.7932, lon: 76.7808, address: "Kharar"),
                LocationPoint(lat: 30.4445, lon: 76.8439, address: "Rajpura")
            ]
            let source = sources.randomElement()!
            
            let validTime = event.startsAt.addingTimeInterval(-Double.random(in: 1800...3600))
            
            let ride = Ride(
                driverUserID: driverID,
                source: source,
                destination: LocationPoint(lat: 30.5163, lon: 76.6598, address: event.location?.name ?? "Event Location"),
                waypoints: [],
                selectedRoute: nil,
                departureTime: validTime,
                seatsTotal: Int.random(in: 2...4),
                farePerSeat: Double.random(in: 40...100).rounded(),
                status: .published,
                notes: "Going for \(event.title)"
            )
            rides.append(ride)
        }
        
        return rides.sorted(by: { $0.departureTime < $1.departureTime })
    }

    static let sampleEvents: [EventItem] = {

        let e1 = EventItem(
            createdByUserID: UUID(),
            title: "Rangrez 2026",
            details: "Cultural festival",
            location: EventLocation(name: "Main Ground"),
            startsAt: Date().addingTimeInterval(86400)
        )

        let e2 = EventItem(
            createdByUserID: UUID(),
            title: "TechNova 2026",
            details: "Annual tech fest",
            location: EventLocation(name: "B-Block Auditorium"),
            startsAt: Date().addingTimeInterval(172800)
        )

        return [e1, e2]
    }()
}
