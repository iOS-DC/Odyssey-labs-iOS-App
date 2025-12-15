import UIKit

class EventTableViewCell: UITableViewCell {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var attendButton: UIButton!
    @IBOutlet weak var cardContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Transparent backgrounds
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card styling (like Ride cell)
        cardContainerView.backgroundColor = .systemBackground
        cardContainerView.layer.cornerRadius = 20
        cardContainerView.layer.masksToBounds = true

        // Shadow on the cell layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        attendButton.layer.cornerRadius = 14
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Better spacing between cells
        let inset: CGFloat = 10
        contentView.frame = contentView.frame.insetBy(dx: 0, dy: inset)

        // Correct shadow path = performance boost
        let shadowRect = cardContainerView.frame
        layer.shadowPath = UIBezierPath(
            roundedRect: shadowRect,
            cornerRadius: cardContainerView.layer.cornerRadius
        ).cgPath
    }

    func configure(with event: EventItem) {
        titleLabel.text = event.title

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a"
        dateLabel.text = formatter.string(from: event.startsAt)

        locationLabel.text = event.location?.name ?? "Location"

        attendButton.setTitle("Attend", for: .normal)

        eventImageView.image = UIImage(named: "eventPlaceholder")
    }
}
