import Foundation

extension Notification.Name {
    static let reviewsUpdated = Notification.Name("reviewsUpdated")
}

/// Singleton that persists all ride reviews to Documents/reviews.json
final class ReviewDataModel {

    static let shared = ReviewDataModel()
    private init() { load() }

    private(set) var reviews: [Review] = []

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("reviews.json")
    }

    // MARK: - Persistence
    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([Review].self, from: data)
        else { return }
        reviews = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(reviews) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Write
    func submit(review: Review) {
        // Prevent duplicates: one review per reviewer → reviewee per ride
        guard !hasReviewed(rideID: review.rideID,
                           reviewerID: review.reviewerID,
                           revieweeID: review.revieweeID) else { return }
        reviews.append(review)
        save()
        NotificationCenter.default.post(name: .reviewsUpdated, object: nil)
    }

    // MARK: - Read
    func reviews(for userID: UUID) -> [Review] {
        reviews.filter { $0.revieweeID == userID }
    }

    func averageRating(for userID: UUID) -> Double? {
        let r = reviews(for: userID)
        guard !r.isEmpty else { return nil }
        return Double(r.reduce(0) { $0 + $1.stars }) / Double(r.count)
    }

    /// Total completed rides involving this user (as driver or passenger)
    func totalRides(for userID: UUID) -> Int {
        let asDriver    = RideDataModel.shared.rides(driverID: userID, status: .completed).count
        let asPassenger = RideDataModel.shared.completedRides(passengerID: userID).count
        return asDriver + asPassenger
    }

    func hasReviewed(rideID: UUID, reviewerID: UUID, revieweeID: UUID) -> Bool {
        reviews.contains {
            $0.rideID == rideID &&
            $0.reviewerID == reviewerID &&
            $0.revieweeID == revieweeID
        }
    }

    /// All people this user still needs to rate for a given ride.
    /// For a host: unrated passengers. For a passenger: unrated driver.
    func pendingReviewees(rideID: UUID, reviewerID: UUID, allRevieweeIDs: [UUID]) -> [UUID] {
        allRevieweeIDs.filter { !hasReviewed(rideID: rideID, reviewerID: reviewerID, revieweeID: $0) }
    }
}
