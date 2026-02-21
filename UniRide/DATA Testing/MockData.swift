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
        
        // Helper to get a random time:
        // - If current time > 9 AM, show rides after 4 PM (16:00).
        // - Otherwise, mix of morning (7-9 AM) and evening (4-7 PM).
        func randomCommuteTime() -> Date {
             let calendar = Calendar.current
             let now = Date()
             // Use TODAY as the base date
             let date = calendar.startOfDay(for: now)
             
             let currentHour = calendar.component(.hour, from: now)
             
             // Logic: If it's already past 9 AM, don't show morning rides (they're in the past).
             let forceEvening = currentHour >= 9
             
             // If forced evening, use evening slot. Else random.
             let useEvening = forceEvening || Bool.random()
             
             let hour = useEvening ? Int.random(in: 16...19) : Int.random(in: 7...8)
             let minute = Int.random(in: 0...55)
             
             return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? Date()
        }

        // 20 realistic Ride objects
        let rides: [Ride] = [
            Ride(driverUserID: userIDs[0],
                 source: LocationPoint(lat: 30.5163, lon: 76.6598, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7046, lon: 76.7179, address: "Sector 17, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[1],
                 source: LocationPoint(lat: 30.5151, lon: 76.6595, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7410, lon: 76.7565, address: "Elante Mall, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 2, farePerSeat: 60, status: .published, notes: nil),

            Ride(driverUserID: userIDs[2],
                 source: LocationPoint(lat: 30.5132, lon: 76.6569, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7294, lon: 76.7845, address: "IT Park, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[3],
                 source: LocationPoint(lat: 30.5167, lon: 76.6610, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.6520, lon: 76.8227, address: "Sector 82, Mohali"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 35, status: .published, notes: nil),

            Ride(driverUserID: userIDs[4],
                 source: LocationPoint(lat: 30.5180, lon: 76.6615, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.6900, lon: 76.7770, address: "Sector 22, Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[5],
                 source: LocationPoint(lat: 30.5150, lon: 76.6591, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.9000, lon: 75.8573, address: "Ludhiana Bus Stand"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 1, farePerSeat: 150, status: .published, notes: nil),

            Ride(driverUserID: userIDs[6],
                 source: LocationPoint(lat: 30.5170, lon: 76.6600, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7350, lon: 76.8010, address: "Phase 5, Mohali"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 45, status: .published, notes: nil),

            Ride(driverUserID: userIDs[7],
                 source: LocationPoint(lat: 30.5168, lon: 76.6599, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7050, lon: 76.7100, address: "PGI Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 2, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[8],
                 source: LocationPoint(lat: 30.5173, lon: 76.6578, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.6637, lon: 76.8371, address: "Zirakpur"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[9],
                 source: LocationPoint(lat: 30.5181, lon: 76.6604, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7932, lon: 76.7808, address: "Kharar"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 70, status: .published, notes: nil),

            Ride(driverUserID: userIDs[10],
                 source: LocationPoint(lat: 30.5144, lon: 76.6602, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7786, lon: 76.7870, address: "Landran"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[11],
                 source: LocationPoint(lat: 30.5176, lon: 76.6610, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.4445, lon: 76.8439, address: "Rajpura"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 2, farePerSeat: 30, status: .published, notes: nil),

            Ride(driverUserID: userIDs[12],
                 source: LocationPoint(lat: 30.5159, lon: 76.6622, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7114, lon: 76.8531, address: "Sector 20 Panchkula"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 65, status: .published, notes: nil),

            Ride(driverUserID: userIDs[13],
                 source: LocationPoint(lat: 30.5147, lon: 76.6605, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.6943, lon: 76.8606, address: "Sector 12 Panchkula"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 1, farePerSeat: 80, status: .published, notes: nil),

            Ride(driverUserID: userIDs[14],
                 source: LocationPoint(lat: 30.5160, lon: 76.6613, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7477, lon: 76.7590, address: "Chandigarh Airport"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 90, status: .published, notes: nil),

            Ride(driverUserID: userIDs[15],
                 source: LocationPoint(lat: 30.5189, lon: 76.6599, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7662, lon: 76.7755, address: "ISBT 43 Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 50, status: .published, notes: nil),

            Ride(driverUserID: userIDs[16],
                 source: LocationPoint(lat: 30.5153, lon: 76.6629, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7320, lon: 76.7076, address: "Sector 11 Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 40, status: .published, notes: nil),

            Ride(driverUserID: userIDs[17],
                 source: LocationPoint(lat: 30.5161, lon: 76.6601, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.7543, lon: 76.7869, address: "Mohali Railway Station"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 2, farePerSeat: 55, status: .published, notes: nil),

            Ride(driverUserID: userIDs[18],
                 source: LocationPoint(lat: 30.5166, lon: 76.6618, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.8389, lon: 76.9589, address: "Pinjore"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 3, farePerSeat: 75, status: .published, notes: nil),

            Ride(driverUserID: userIDs[19],
                 source: LocationPoint(lat: 30.5158, lon: 76.6600, address: "Chitkara University"),
                 destination: LocationPoint(lat: 30.6700, lon: 76.7400, address: "New Chandigarh"),
                 waypoints: [], selectedRoute: nil,
                 departureTime: randomCommuteTime(),
                 seatsTotal: 4, farePerSeat: 60, status: .published, notes: nil)
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
