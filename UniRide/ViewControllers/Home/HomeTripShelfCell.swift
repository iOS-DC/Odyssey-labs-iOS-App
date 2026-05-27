import UIKit

/// A table-view row that horizontally scrolls up to 3 trip mini-cards.
/// Static shell (scroll view + horizontal stack) lives in `HomeTripShelfCell.xib`.
/// The mini cards themselves are built in code because they're data-driven.
final class HomeTripShelfCell: UITableViewCell {

    static let reuseID = "HomeTripShelfCell"

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    var onTripTapped: ((Trip) -> Void)?

    private var trips: [Trip] = []

    // MARK: - Configure

    func configure(with trips: [Trip]) {
        self.trips = trips
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for trip in trips {
            let card = makeMiniCard(trip: trip)
            stackView.addArrangedSubview(card)
        }

        scrollView.setContentOffset(.zero, animated: false)
    }

    // MARK: - Mini Card

    /// Loads a `TripMiniCardView` from its XIB and wires up the tap gesture.
    private func makeMiniCard(trip: Trip) -> UIView {
        let card = TripMiniCardView.loadFromNib()
        card.configure(with: trip)

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.tag = trips.firstIndex(where: { $0.id == trip.id }) ?? 0

        return card
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag, trips.indices.contains(tag) else { return }
        onTripTapped?(trips[tag])
    }
}
