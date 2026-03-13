import Foundation

extension Notification.Name {
    static let reviewsUpdated = Notification.Name("reviewsUpdated")
}

/// Singleton that persists ride reviews locally AND syncs with Supabase
/// so that driver/passenger ratings are visible across all devices.
final class ReviewDataModel {

    static let shared = ReviewDataModel()
    private init() { load() }

    private(set) var reviews: [Review] = []

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("reviews.json")
    }

    // MARK: - Local Persistence

    private func load() {
        guard
            let data    = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([Review].self, from: data)
        else { return }
        reviews = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(reviews) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Write (local + Supabase)

    func submit(review: Review) {
        // Prevent duplicate reviews locally
        guard !hasReviewed(rideID: review.rideID,
                           reviewerID: review.reviewerID,
                           revieweeID: review.revieweeID) else { return }
        reviews.append(review)
        save()
        NotificationCenter.default.post(name: .reviewsUpdated, object: nil)

        // Persist to Supabase in the background — failures are silent
        // (the review is still stored locally, and will sync on next fetch)
        Task {
            try? await ReviewRepository.shared.insertReview(review)
        }
    }

    // MARK: - Remote sync

    /// Fetches all remote reviews for `userID` (as reviewee) from Supabase,
    /// merges them into the local cache (deduped by review.id), and triggers
    /// a .reviewsUpdated notification so any listening UI refreshes.
    ///
    /// Call this whenever you need an accurate cross-device rating, e.g.:
    ///   • ProfileViewController.viewWillAppear
    ///   • RideDetailViewController.viewDidLoad (for the driver's rating)
    func fetchAndMerge(for userID: UUID) {
        Task { @MainActor in
            guard let remote = try? await ReviewRepository.shared.fetchReviews(revieweeID: userID),
                  !remote.isEmpty else { return }

            // Merge: add any review not already in the local cache (matched by id)
            let existingIDs = Set(reviews.map { $0.id })
            let newOnes = remote.filter { !existingIDs.contains($0.id) }
            guard !newOnes.isEmpty else { return }

            reviews.append(contentsOf: newOnes)
            save()
            NotificationCenter.default.post(name: .reviewsUpdated, object: nil)
        }
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
            $0.rideID     == rideID     &&
            $0.reviewerID == reviewerID &&
            $0.revieweeID == revieweeID
        }
    }

    /// All people this user still needs to rate for a given ride.
    func pendingReviewees(rideID: UUID, reviewerID: UUID, allRevieweeIDs: [UUID]) -> [UUID] {
        allRevieweeIDs.filter { !hasReviewed(rideID: rideID, reviewerID: reviewerID, revieweeID: $0) }
    }
}
