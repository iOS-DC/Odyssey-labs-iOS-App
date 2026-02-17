import UIKit

class EventTableViewCell: UITableViewCell {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var attendButton: UIButton!
    @IBOutlet weak var cardContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

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

        eventImageView.layer.cornerRadius = 12
        eventImageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        locationLabel.font = .systemFont(ofSize: 13)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 1

        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = .systemBlue

        attendButton.setTitle("View Details ›", for: .normal)
        attendButton.setTitleColor(.systemBlue, for: .normal)
        attendButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        attendButton.backgroundColor = .clear
        attendButton.layer.cornerRadius = 0
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

        let df = DateFormatter()
        df.dateFormat = "MMM d"
        dateLabel.text = df.string(from: event.startsAt)
        badgeLabel.text = timingBadge(for: event.startsAt)

        locationLabel.text = event.location?.name ?? "Location"

        attendButton.setTitle("View Details ›", for: .normal)

        eventImageView.image = UIImage(named: event.imageName ?? "eventPlaceholder")
    }

    private func timingBadge(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let weekFromNow = cal.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        if date <= weekFromNow { return "This Week" }
        return "Soon"
    }
}
