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

    private func makeMiniCard(trip: Trip) -> UIView {
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.10
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.layer.shadowRadius = 8
        card.clipsToBounds = false
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: 168).isActive = true

        let clip = UIView()
        clip.layer.cornerRadius = 16
        clip.clipsToBounds = true
        clip.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(clip)

        let hero = UIImageView()
        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        hero.backgroundColor = .systemGray5
        hero.loadImage(from: trip.imageName)
        hero.translatesAutoresizingMaskIntoConstraints = false
        clip.addSubview(hero)

        let titleLabel = UILabel()
        titleLabel.text = trip.title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        clip.addSubview(titleLabel)

        let locationLabel = UILabel()
        locationLabel.text = trip.location
        locationLabel.font = UIFont.systemFont(ofSize: 11)
        locationLabel.textColor = .secondaryLabel
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        clip.addSubview(locationLabel)

        let priceLabel = UILabel()
        priceLabel.text = trip.priceFormatted
        priceLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        priceLabel.textColor = AppDesign.Color.primary
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        clip.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            clip.topAnchor.constraint(equalTo: card.topAnchor),
            clip.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            clip.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            clip.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            hero.topAnchor.constraint(equalTo: clip.topAnchor),
            hero.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            hero.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            hero.heightAnchor.constraint(equalToConstant: 110),

            titleLabel.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: clip.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: clip.trailingAnchor, constant: -10),

            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            locationLabel.leadingAnchor.constraint(equalTo: clip.leadingAnchor, constant: 10),
            locationLabel.trailingAnchor.constraint(equalTo: clip.trailingAnchor, constant: -10),

            priceLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 6),
            priceLabel.leadingAnchor.constraint(equalTo: clip.leadingAnchor, constant: 10),
            priceLabel.bottomAnchor.constraint(equalTo: clip.bottomAnchor, constant: -10),
        ])

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
