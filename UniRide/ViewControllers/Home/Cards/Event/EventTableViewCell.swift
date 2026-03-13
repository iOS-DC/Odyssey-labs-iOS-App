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
        cardContainerView.backgroundColor = AppDesign.Color.surface
        cardContainerView.layer.cornerRadius = AppDesign.Radius.lg
        cardContainerView.layer.masksToBounds = true

        // Shadow on the cell layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        layer.masksToBounds = false

        eventImageView.layer.cornerRadius = AppDesign.Radius.sm
        eventImageView.clipsToBounds = true

        titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        titleLabel.lineBreakMode = .byWordWrapping
        dateLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        locationLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        badgeLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: AppDesign.Color.primary)
        badgeLabel.isHidden = true // User requested removal of Today/Tomorrow/Soon labels

        attendButton.setTitle("View Details ›", for: .normal)
        attendButton.applyTextActionStyle(font: AppDesign.Typography.caption)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Better spacing between cells
        let inset: CGFloat = AppDesign.Spacing.sm
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
