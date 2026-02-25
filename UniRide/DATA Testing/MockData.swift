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

    static let driverProfiles: [UserProfile] = {
        let ids: [UUID] = [
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!,
            UUID(uuidString: "12121212-1212-1212-1212-121212121212")!,
            UUID(uuidString: "23232323-2323-2323-2323-232323232323")!,
            UUID(uuidString: "34343434-3434-3434-3434-343434343434")!,
            UUID(uuidString: "45454545-4545-4545-4545-454545454545")!,
            UUID(uuidString: "56565656-5656-5656-5656-565656565656")!
        ]

        return zip(ids, driverNames).enumerated().map { index, pair in
            let (id, name) = pair
            return UserProfile(
                id: id,
                email: "driver\(index + 1)@chitkara.edu.in",
                isEmailVerified: true,
                fullName: name,
                role: index < 15 ? .student : .faculty,
                courseName: "CSE",
                year: index < 15 ? (index % 4) + 1 : nil
            )
        }
    }()

    static let sampleRides: [Ride] = {

        let userIDs = driverProfiles.map { $0.id }

        func randomCommuteTime(daysAhead: Int = 0) -> Date {
            let calendar = Calendar.current
            let now = Date()
            let date = calendar.startOfDay(for: now).addingTimeInterval(Double(daysAhead) * 86400)
            let currentHour = calendar.component(.hour, from: now)
            let forceEvening = (daysAhead == 0) && (currentHour >= 9)
            let useEvening = forceEvening || Bool.random()
            let hour = useEvening ? Int.random(in: 16...20) : Int.random(in: 7...9)
            let minute = [0, 10, 15, 20, 30, 45].randomElement()!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? Date()
        }

        // ── Locations ────────────────────────────────────────
        let chitkara  = LocationPoint(lat: 30.5163, lon: 76.6598, address: "Chitkara University")

        // Panchkula sectors
        let pnk19 = LocationPoint(lat: 30.6956, lon: 76.8495, address: "Sector 19, Panchkula")
        let pnk14 = LocationPoint(lat: 30.7102, lon: 76.8481, address: "Sector 14, Panchkula")
        let pnk11 = LocationPoint(lat: 30.7131, lon: 76.8344, address: "Sector 11, Panchkula")
        let pnk20 = LocationPoint(lat: 30.6892, lon: 76.8568, address: "Sector 20, Panchkula")
        let pnk21 = LocationPoint(lat: 30.6830, lon: 76.8620, address: "Sector 21, Panchkula")

        // Other cities
        let ambala    = LocationPoint(lat: 30.3752, lon: 76.7821, address: "Ambala City")
        let ambalaC   = LocationPoint(lat: 30.3784, lon: 76.8268, address: "Ambala Cantonment")
        let deba      = LocationPoint(lat: 30.5933, lon: 76.8404, address: "Derabassi")
        let rajpura   = LocationPoint(lat: 30.4837, lon: 76.5978, address: "Rajpura")
        let patiala   = LocationPoint(lat: 30.3398, lon: 76.3869, address: "Patiala")
        let patialaB  = LocationPoint(lat: 30.3317, lon: 76.4027, address: "Bus Stand, Patiala")

        // Chandigarh
        let chd17     = LocationPoint(lat: 30.7046, lon: 76.7179, address: "Sector 17, Chandigarh")
        let chd22     = LocationPoint(lat: 30.6992, lon: 76.7551, address: "Sector 22, Chandigarh")
        let chd34     = LocationPoint(lat: 30.7097, lon: 76.7897, address: "Sector 34, Chandigarh")
        let chd43     = LocationPoint(lat: 30.7162, lon: 76.7562, address: "Sector 43, Chandigarh")
        let chdIsbt   = LocationPoint(lat: 30.7662, lon: 76.7755, address: "ISBT 43, Chandigarh")
        let elante    = LocationPoint(lat: 30.7410, lon: 76.7565, address: "Elante Mall, Chandigarh")
        let itPark    = LocationPoint(lat: 30.7294, lon: 76.7845, address: "IT Park, Chandigarh")
        let pgi       = LocationPoint(lat: 30.7050, lon: 76.7100, address: "PGI, Chandigarh")
        let chdApt    = LocationPoint(lat: 30.6735, lon: 76.7885, address: "Chandigarh Airport")

        // Mohali
        let zirakpur  = LocationPoint(lat: 30.6637, lon: 76.8371, address: "Zirakpur")
        let phase5    = LocationPoint(lat: 30.7350, lon: 76.8010, address: "Phase 5, Mohali")
        let sec82     = LocationPoint(lat: 30.6520, lon: 76.8227, address: "Sector 82, Mohali")
        let kharar    = LocationPoint(lat: 30.7932, lon: 76.7808, address: "Kharar")
        let newChd    = LocationPoint(lat: 30.6700, lon: 76.7400, address: "New Chandigarh, Mullanpur")

        // ── Rides ────────────────────────────────────────────
        // d=0 → today, d=1 → tomorrow, some spread across next 3 days
        let rides: [Ride] = [

            // ── FROM Chitkara → popular destinations ──

            Ride(driverUserID: userIDs[0],  source: chitkara, destination: chd17,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 50,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[1],  source: chitkara, destination: pnk19,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 2, farePerSeat: 70,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[2],  source: chitkara, destination: pnk14,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 65,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[3],  source: chitkara, destination: pnk11,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 60,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[4],  source: chitkara, destination: pnk20,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 2, farePerSeat: 75,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[5],  source: chitkara, destination: pnk21,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 80,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[6],  source: chitkara, destination: ambala,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 120, status: .published, notes: nil),
            Ride(driverUserID: userIDs[7],  source: chitkara, destination: ambalaC, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 2, farePerSeat: 130, status: .published, notes: nil),
            Ride(driverUserID: userIDs[8],  source: chitkara, destination: deba,    waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[9],  source: chitkara, destination: rajpura, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 40,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[10], source: chitkara, destination: patiala, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 90,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[11], source: chitkara, destination: patialaB,waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 2, farePerSeat: 95,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[12], source: chitkara, destination: elante,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 60,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[13], source: chitkara, destination: itPark,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[14], source: chitkara, destination: zirakpur,waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 45,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[15], source: chitkara, destination: phase5,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 2, farePerSeat: 50,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[16], source: chitkara, destination: chd22,   waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[17], source: chitkara, destination: chdIsbt, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 50,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[18], source: chitkara, destination: newChd,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 4, farePerSeat: 35,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[19], source: chitkara, destination: kharar,  waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 0), seatsTotal: 3, farePerSeat: 70,  status: .published, notes: nil),

            // ── FROM popular destinations → Chitkara (morning rides) ──

            Ride(driverUserID: userIDs[0],  source: pnk19,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 70,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[1],  source: pnk14,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 65,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[2],  source: pnk11,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 60,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[3],  source: pnk20,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 75,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[4],  source: pnk21,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 80,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[5],  source: ambala,   destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 120, status: .published, notes: nil),
            Ride(driverUserID: userIDs[6],  source: deba,     destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[7],  source: rajpura,  destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 40,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[8],  source: patiala,  destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 90,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[9],  source: chd17,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 50,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[10], source: chd22,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[11], source: chd34,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 60,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[12], source: chd43,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 55,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[13], source: elante,   destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 60,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[14], source: zirakpur, destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 45,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[15], source: pgi,      destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 50,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[16], source: chdApt,   destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 90,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[17], source: sec82,    destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 2, farePerSeat: 45,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[18], source: kharar,   destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 4, farePerSeat: 70,  status: .published, notes: nil),
            Ride(driverUserID: userIDs[19], source: ambalaC,  destination: chitkara, waypoints: [], selectedRoute: nil, departureTime: randomCommuteTime(daysAhead: 1), seatsTotal: 3, farePerSeat: 130, status: .published, notes: nil),
        ]

        return rides
    }()

}

extension MockData {

    static func mockRidesForEvent(_ event: EventItem) -> [Ride] {
        let userIDs = driverProfiles.map { $0.id }
        
        // Generate 5-8 random rides ending at the event location
        var rides: [Ride] = []
        let count = Int.random(in: 5...8)
        
        for _ in 0..<count {
            let driverIdx = Int.random(in: 0..<driverProfiles.count)
            let driverID = userIDs[driverIdx]
            
            // Random source locations around Chandigarh/Mohali
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
            
            // Time: Arrive 30-60 mins before event starts
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
