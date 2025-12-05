//
//  MockData.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 20/11/25.
//


import Foundation

struct MockData {
    
    static let driverNames = [
        "Arjun Sharma", "Krish Bahukhandi", "Rohan Verma", "Aarav Malhotra",
        "Kabir Singh", "Harshdeep Gill", "Samar Kapoor", "Jatin Chawla",
        "Tanishq Vohra", "Raghav Bansal", "Dev Mehra", "Ayaan Gupta",
        "Daksh Kohli", "Viraj Anand", "Sahil Katyal", "Ayush Thakur",
        "Pranav Sood", "Kavish Rawat", "Rehaan Kapoor", "Lakshdeep Singh"
    ]

    static let sampleRides: [Ride] = {

        let userIDs = (0..<20).map { _ in UUID() }

        // 20 realistic Ride objects
        let rides: [Ride] = [
            Ride(driverUserID: userIDs[0],
                 source: LocationPoint(lat: 30.5163, lon: 76.6598, address: "Chitkara University Gate"),
                 destination: LocationPoint(lat: 30.7046, lon: 76.7179, address: "Sector 17, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(1800),
                 seatsTotal: 3, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[1],
                 source: LocationPoint(lat: 30.5151, lon: 76.6595, address: "Chitkara Hostel Road"),
                 destination: LocationPoint(lat: 30.7410, lon: 76.7565, address: "Elante Mall, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(2400),
                 seatsTotal: 2, farePerSeat: 60, status: .published, notes: nil),

            Ride(driverUserID: userIDs[2],
                 source: LocationPoint(lat: 30.5132, lon: 76.6569, address: "Chitkara CSE Block"),
                 destination: LocationPoint(lat: 30.7294, lon: 76.7845, address: "IT Park, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(4000),
                 seatsTotal: 4, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[3],
                 source: LocationPoint(lat: 30.5167, lon: 76.6610, address: "Chitkara Admin Block"),
                 destination: LocationPoint(lat: 30.6520, lon: 76.8227, address: "Sector 82, Mohali"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(6000),
                 seatsTotal: 3, farePerSeat: 35, status: .published, notes: nil),

            Ride(driverUserID: userIDs[4],
                 source: LocationPoint(lat: 30.5180, lon: 76.6615, address: "CV Raman Block"),
                 destination: LocationPoint(lat: 30.6900, lon: 76.7770, address: "Sector 22, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(7200),
                 seatsTotal: 4, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[5],
                 source: LocationPoint(lat: 30.5150, lon: 76.6591, address: "Chitkara Hostel"),
                 destination: LocationPoint(lat: 30.9000, lon: 75.8573, address: "Ludhiana Bus Stand"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(8200),
                 seatsTotal: 1, farePerSeat: 150, status: .published, notes: nil),

            Ride(driverUserID: userIDs[6],
                 source: LocationPoint(lat: 30.5170, lon: 76.6600, address: "Mechanical Block"),
                 destination: LocationPoint(lat: 30.7350, lon: 76.8010, address: "Phase 5, Mohali"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(3000),
                 seatsTotal: 3, farePerSeat: 45, status: .published, notes: nil),

            Ride(driverUserID: userIDs[7],
                 source: LocationPoint(lat: 30.5168, lon: 76.6599, address: "Chitkara Parking Area"),
                 destination: LocationPoint(lat: 30.7050, lon: 76.7100, address: "PGI Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(4500),
                 seatsTotal: 2, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[8],
                 source: LocationPoint(lat: 30.5173, lon: 76.6578, address: "Chitkara Grounds"),
                 destination: LocationPoint(lat: 30.6637, lon: 76.8371, address: "Zirakpur"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(5400),
                 seatsTotal: 4, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[9],
                 source: LocationPoint(lat: 30.5181, lon: 76.6604, address: "Pharmacy Block"),
                 destination: LocationPoint(lat: 30.7932, lon: 76.7808, address: "Kharar"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(9000),
                 seatsTotal: 3, farePerSeat: 70, status: .published, notes: nil),

            Ride(driverUserID: userIDs[10],
                 source: LocationPoint(lat: 30.5144, lon: 76.6602, address: "ECE Block"),
                 destination: LocationPoint(lat: 30.7786, lon: 76.7870, address: "Landran"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(3600 * 5),
                 seatsTotal: 4, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[11],
                 source: LocationPoint(lat: 30.5176, lon: 76.6610, address: "Chitkara Cafe"),
                 destination: LocationPoint(lat: 30.4445, lon: 76.8439, address: "Rajpura"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(3600 * 3),
                 seatsTotal: 2, farePerSeat: 30, status: .published, notes: nil),

            Ride(driverUserID: userIDs[12],
                 source: LocationPoint(lat: 30.5159, lon: 76.6622, address: "Library Block"),
                 destination: LocationPoint(lat: 30.7114, lon: 76.8531, address: "Sector 20 Panchkula"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(3600 * 2),
                 seatsTotal: 3, farePerSeat: 65, status: .published, notes: nil),

            Ride(driverUserID: userIDs[13],
                 source: LocationPoint(lat: 30.5147, lon: 76.6605, address: "Nursing Block"),
                 destination: LocationPoint(lat: 30.6943, lon: 76.8606, address: "Sector 12 Panchkula"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(4000),
                 seatsTotal: 1, farePerSeat: 80, status: .published, notes: nil),

            Ride(driverUserID: userIDs[14],
                 source: LocationPoint(lat: 30.5160, lon: 76.6613, address: "SBS Block"),
                 destination: LocationPoint(lat: 30.7477, lon: 76.7590, address: "Chandigarh Airport"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(4200),
                 seatsTotal: 3, farePerSeat: 90, status: .published, notes: nil),

            Ride(driverUserID: userIDs[15],
                 source: LocationPoint(lat: 30.5189, lon: 76.6599, address: "D Block"),
                 destination: LocationPoint(lat: 30.7662, lon: 76.7755, address: "ISBT 43 Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(1800),
                 seatsTotal: 4, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[16],
                 source: LocationPoint(lat: 30.5153, lon: 76.6629, address: "Sports Ground"),
                 destination: LocationPoint(lat: 30.7320, lon: 76.7076, address: "Sector 11 Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(2600),
                 seatsTotal: 3, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[17],
                 source: LocationPoint(lat: 30.5161, lon: 76.6601, address: "Block F"),
                 destination: LocationPoint(lat: 30.7543, lon: 76.7869, address: "Mohali Railway Station"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(3800),
                 seatsTotal: 2, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[18],
                 source: LocationPoint(lat: 30.5166, lon: 76.6618, address: "MBA Block"),
                 destination: LocationPoint(lat: 30.8389, lon: 76.9589, address: "Pinjore"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(4600),
                 seatsTotal: 3, farePerSeat: 75, status: .published, notes: nil),

            Ride(driverUserID: userIDs[19],
                 source: LocationPoint(lat: 30.5158, lon: 76.6600, address: "Entrance Road"),
                 destination: LocationPoint(lat: 30.6700, lon: 76.7400, address: "New Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: Date().addingTimeInterval(5200),
                 seatsTotal: 4, farePerSeat: 60, status: .published, notes: nil)
        ]

        return rides
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
