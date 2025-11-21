//
//  MockData.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 20/11/25.
//


import Foundation

struct MockData {

    static let sampleRides: [Ride] = {

        let src1 = LocationPoint(lat: 30.516, lon: 76.659, address: "Chitkara University")
        let dst1 = LocationPoint(lat: 30.350, lon: 76.920, address: "Sector 43, Chandigarh")

        let src2 = LocationPoint(lat: 30.516, lon: 76.659, address: "Chitkara University")
        let dst2 = LocationPoint(lat: 30.704, lon: 76.717, address: "Elante Mall")

        let r1 = Ride(
            driverUserID: UUID(), // temporary for mock
            source: src1,
            destination: dst1,
            departureTime: Date().addingTimeInterval(3600),
            seatsTotal: 3,
            farePerSeat: 80
        )

        let r2 = Ride(
            driverUserID: UUID(),
            source: src2,
            destination: dst2,
            departureTime: Date().addingTimeInterval(7200),
            seatsTotal: 2,
            farePerSeat: 120
        )

        return [r1, r2]
    }()
}
extension MockData {

    static let sampleEvents: [EventItem] = {

        let e1 = EventItem(
            createdByUserID: UUID(),
            title: "Rangrez 2025",
            details: "Cultural festival",
            location: EventLocation(name: "Main Ground"),
            startsAt: Date().addingTimeInterval(86400)
        )

        let e2 = EventItem(
            createdByUserID: UUID(),
            title: "TechNova 2025",
            details: "Annual tech fest",
            location: EventLocation(name: "B-Block Auditorium"),
            startsAt: Date().addingTimeInterval(172800)
        )

        return [e1, e2]
    }()
}
