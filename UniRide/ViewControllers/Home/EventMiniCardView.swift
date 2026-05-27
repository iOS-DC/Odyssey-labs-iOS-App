import UIKit

/// Compact card shown inside the Top Events horizontal shelf.
/// Mirrors `TripMiniCardView`: hero image + title + location + date.
/// Static layout lives in `EventMiniCardView.xib`. Per-instance shadow
/// is applied at runtime.
final class EventMiniCardView: UIView {

    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()

    /// Loads a fresh instance from the XIB.
    static func loadFromNib() -> EventMiniCardView {
        let nib = UINib(nibName: "EventMiniCardView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? EventMiniCardView else {
            fatalError("Could not load EventMiniCardView from XIB")
        }
        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 8
        clipsToBounds = false

        dateLabel.textColor = AppDesign.Color.primary
    }

    func configure(with event: EventItem) {
        heroImageView.loadImage(from: event.imageName ?? "eventPlaceholder")
        titleLabel.text = event.title
        locationLabel.text = event.location?.name ?? "Location"
        dateLabel.text = EventMiniCardView.dateFormatter.string(from: event.startsAt)
    }
}
