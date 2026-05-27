import UIKit

/// Compact card shown inside the Top Trips horizontal shelf.
/// Static layout (hero image + 3 labels inside a rounded clip) lives in
/// `TripMiniCardView.xib`. The shadow is a runtime concern and stays in code.
final class TripMiniCardView: UIView {

    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    /// Loads a fresh instance from the XIB.
    static func loadFromNib() -> TripMiniCardView {
        let nib = UINib(nibName: "TripMiniCardView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? TripMiniCardView else {
            fatalError("Could not load TripMiniCardView from XIB")
        }
        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Drop shadow on the card itself; the inner clip view (in the XIB)
        // handles corner-radius clipping of the image + content.
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 8
        clipsToBounds = false

        priceLabel.textColor = AppDesign.Color.primary
    }

    func configure(with trip: Trip) {
        heroImageView.loadImage(from: trip.imageName)
        titleLabel.text = trip.title
        locationLabel.text = trip.location
        priceLabel.text = trip.priceFormatted
    }
}
