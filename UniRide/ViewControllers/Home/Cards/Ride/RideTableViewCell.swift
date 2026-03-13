//
//  RideTableViewCell.swift
//  UniRide
//

import UIKit

final class RideTableViewCell: UITableViewCell {

    // MARK: - IBOutlets (Header)
    @IBOutlet weak var cardContainerView: UIView!

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!

    // Seats (top-right)
    @IBOutlet weak var vehicleIconImageView: UIImageView!
    @IBOutlet weak var seatsLabel: UILabel!

    // MARK: - Route
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!

    // MARK: - Footer
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!

    var onJoinTapped: (() -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        // Cell base
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        yearLabel.text = "3rd"
        // Card
        cardContainerView.backgroundColor = AppDesign.Color.surface
        cardContainerView.layer.cornerRadius = AppDesign.Radius.lg
        cardContainerView.layer.masksToBounds = true

        // Shadow (on cell, not card)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        layer.masksToBounds = false

        // Profile image
        profileImageView.layer.cornerRadius = AppDesign.Radius.lg
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = .secondaryLabel
        
        vehicleIconImageView.tintColor = .secondaryLabel
        seatsLabel.textColor = .secondaryLabel
        vehicleIconImageView.contentMode = .scaleAspectFit

        // Labels styling (safe defaults)
        nameLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        yearLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        fromLabel.applyTextStyle(AppDesign.Typography.subheadline)
        toLabel.applyTextStyle(AppDesign.Typography.subheadline)
        timeLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        // Never let the time label be squeezed by the button
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.8

        priceLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        seatsLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        

        // Join/View Details button (text-only action for cleaner card)
        joinButton.applyTextActionStyle(font: AppDesign.Typography.caption)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)

        fromLabel.numberOfLines = 2
        toLabel.numberOfLines = 2
        fromLabel.lineBreakMode = .byWordWrapping
        toLabel.lineBreakMode = .byWordWrapping
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = AppDesign.Spacing.sm
        contentView.frame = contentView.frame.insetBy(dx: 0, dy: inset)
        layer.shadowPath = UIBezierPath(
            roundedRect: cardContainerView.frame,
            cornerRadius: cardContainerView.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Configure (FULLY DYNAMIC)
    func configure(
        with ride: Ride,
        driver: UserProfile?
    ) {
        let driverName = driver?.fullName ?? "Unknown Driver"
        let photoURL = driver?.photoURL

        // MARK: Driver Info
        nameLabel.text = driverName
        
        if let role = driver?.role {
            if role == .student {
                var yearText = "Student"
                if let y = driver?.year {
                   switch y {
                   case 1: yearText = "1st Year"
                   case 2: yearText = "2nd Year"
                   case 3: yearText = "3rd Year"
                   default: yearText = "\(y)th Year"
                   }
                }
                let dept = driver?.courseName ?? ""
                // e.g. "3rd Year CSE Student"
                yearLabel.text = "\(yearText) \(dept) Student"
            } else {
                let dept = driver?.courseName ?? ""
                yearLabel.text = "Faculty of \(dept)"
            }
        } else {
             // Fallback if role is nil but year is present
            if let y = driver?.year {
                 switch y {
                   case 1: yearLabel.text = "1st Year Student"
                   case 2: yearLabel.text = "2nd Year Student"
                   case 3: yearLabel.text = "3rd Year Student"
                   default: yearLabel.text = "\(y)th Year Student"
                 }
            } else {
                yearLabel.text = "Student"
            }
        }

        profileImageView.loadAndFallback(from: photoURL, name: driverName)

        // MARK: Route
        let fromText = formatLocation(ride.source.address)
        let toText = formatLocation(ride.destination.address)
        fromLabel.text = fromText
        toLabel.text = toText

        // MARK: Time
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        timeLabel.text = formatter.string(from: ride.departureTime)

        // MARK: Vehicle + Seats
        configureVehicle(
            vehicleType: "car",
            seats: ride.seatsAvailable
        )

        // MARK: Price
        let price = Int(ride.farePerSeat)
        priceLabel.text = "₹\(price)"

        // MARK: Join / View Details Button
        joinButton.setTitle("View Details ›", for: .normal)
        joinButton.isEnabled = ride.seatsAvailable > 0
        joinButton.alpha = ride.seatsAvailable > 0 ? 1.0 : 0.5
    }

    @objc private func joinTapped() {
        onJoinTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onJoinTapped = nil
        nameLabel.text = nil
        yearLabel.text = nil
        fromLabel.text = nil
        toLabel.text = nil
        timeLabel.text = nil
        priceLabel.text = nil
        seatsLabel.text = nil
        seatsLabel.textColor = .secondaryLabel
        profileImageView.image = nil
        joinButton.alpha = 1.0
        joinButton.isEnabled = true
    }

    // MARK: - Vehicle Helper
    private func configureVehicle(vehicleType: String?, seats: Int) {

        let type = vehicleType?.lowercased()

        switch type {
        case "car":
            vehicleIconImageView.image = UIImage(systemName: "car.fill")
            seatsLabel.text = "\(seats) seats"

        case "bike", "two wheeler", "two-wheeler":
            vehicleIconImageView.image = UIImage(systemName: "bicycle")
            seatsLabel.text = "\(seats) seat"

        default:
            vehicleIconImageView.image = UIImage(systemName: "car.fill")
            seatsLabel.text = "\(seats) seats"
        }

        if seats > 0 {
            seatsLabel.textColor = AppDesign.Color.success
        } else {
            seatsLabel.textColor = AppDesign.Color.destructive
        }
    }

    private func formatLocation(_ address: String?) -> String {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            return ""
        }

        let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if parts.count >= 2 {
            return "\(parts[0]), \(parts[1])"
        }
        return address
    }
}
