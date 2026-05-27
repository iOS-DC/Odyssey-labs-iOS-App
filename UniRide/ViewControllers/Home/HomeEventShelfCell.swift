import UIKit

/// A table-view row that horizontally scrolls event mini-cards.
/// Mirrors `HomeTripShelfCell`. Static shell (scroll view + horizontal stack)
/// lives in `HomeEventShelfCell.xib`; mini cards come from
/// `EventMiniCardView.xib`.
final class HomeEventShelfCell: UITableViewCell {

    static let reuseID = "HomeEventShelfCell"

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    var onEventTapped: ((EventItem) -> Void)?

    private var events: [EventItem] = []

    // MARK: - Configure

    func configure(with events: [EventItem]) {
        self.events = events
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for event in events {
            let card = makeMiniCard(event: event)
            stackView.addArrangedSubview(card)
        }

        scrollView.setContentOffset(.zero, animated: false)
    }

    // MARK: - Mini Card

    private func makeMiniCard(event: EventItem) -> UIView {
        let card = EventMiniCardView.loadFromNib()
        card.configure(with: event)

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.tag = events.firstIndex(where: { $0.id == event.id }) ?? 0

        return card
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag, events.indices.contains(tag) else { return }
        onEventTapped?(events[tag])
    }
}
