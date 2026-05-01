import Foundation
import UIKit

// MARK: - Trip Models

struct ItineraryDay {
    let title: String
    let activities: [String]
}

struct Trip {
    let id: UUID
    let title: String
    let location: String
    let dateRange: String
    let startDate: Date
    let price: Int
    let spotsLeft: Int
    let organizer: String
    let imageName: String
    let about: String
    let itinerary: [ItineraryDay]
    let inclusions: [String]
    let exclusions: [String]
    var isLiked: Bool = false
    let isPast: Bool

    var priceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "₹\(formatted)"
    }
}

// MARK: - Data Store

final class TripDataModel {
    static let shared = TripDataModel()
    private init() {}

    private(set) var trips: [Trip] = []

    func upcomingTrips() -> [Trip] {
        trips.filter { !$0.isPast }
    }

    func pastTrips() -> [Trip] {
        trips.filter { $0.isPast }
    }

    func toggleLike(id: UUID) {
        guard let i = trips.firstIndex(where: { $0.id == id }) else { return }
        trips[i].isLiked.toggle()
    }

    @discardableResult
    func addTrip(_ trip: Trip) -> Trip {
        trips.insert(trip, at: 0)
        trips.sort { $0.startDate < $1.startDate }
        return trip
    }

    func updateTrip(_ trip: Trip) {
        guard let i = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[i] = trip
        trips.sort { $0.startDate < $1.startDate }
    }

    func deleteTrip(id: UUID) {
        trips.removeAll { $0.id == id }
    }

    func replaceTripsFromBackend(_ incoming: [Trip]) {
        guard !incoming.isEmpty else { return }
        trips = incoming.sorted { $0.startDate < $1.startDate }
    }

}
