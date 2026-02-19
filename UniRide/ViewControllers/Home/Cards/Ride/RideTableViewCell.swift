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
        cardContainerView.backgroundColor = .systemBackground
        cardContainerView.layer.cornerRadius = 18
        cardContainerView.layer.masksToBounds = true

        // Shadow (on cell, not card)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        // Profile image
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = .secondaryLabel
        
        vehicleIconImageView.tintColor = .secondaryLabel
        seatsLabel.textColor = .secondaryLabel
        vehicleIconImageView.contentMode = .scaleAspectFit

        // Labels styling (safe defaults)
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        yearLabel.font = .systemFont(ofSize: 13)
        yearLabel.textColor = .secondaryLabel

        fromLabel.font = .systemFont(ofSize: 15, weight: .medium)
        toLabel.font = .systemFont(ofSize: 15, weight: .medium)

        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .secondaryLabel

        priceLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        priceLabel.textColor = .label

        seatsLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        

        // Join button
        joinButton.layer.cornerRadius = 18
        joinButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        joinButton.backgroundColor = .systemBlue
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)

        fromLabel.numberOfLines = 2
        toLabel.numberOfLines = 2
        fromLabel.lineBreakMode = .byWordWrapping
        toLabel.lineBreakMode = .byWordWrapping
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 10
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
                let year = driver?.year != nil ? "\(driver!.year!) Year" : "Student"
                let dept = driver?.courseName ?? ""
                yearLabel.text = "\(year) \(dept) Student"
            } else {
                let dept = driver?.courseName ?? ""
                yearLabel.text = "Faculty of \(dept)"
            }
        } else {
            yearLabel.text = driver?.year != nil ? "\(driver!.year!) Year" : ""
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

        // MARK: Join Button
        joinButton.setTitle("Join Ride", for: .normal)
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
            seatsLabel.textColor = UIColor.systemGreen
        } else {
            seatsLabel.textColor = UIColor.systemRed
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

