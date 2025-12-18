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

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        // Cell base
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

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
        profileImageView.tintColor = .systemTeal

        // Vehicle icon
        vehicleIconImageView.tintColor = .systemTeal
        vehicleIconImageView.contentMode = .scaleAspectFit

        // Labels styling (safe defaults)
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        yearLabel.font = .systemFont(ofSize: 13)
        yearLabel.textColor = .secondaryLabel

        fromLabel.font = .systemFont(ofSize: 15, weight: .medium)
        toLabel.font = .systemFont(ofSize: 15, weight: .medium)

        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .secondaryLabel

        priceLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        priceLabel.textColor = .systemGreen

        seatsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        seatsLabel.textColor = .systemTeal

        // Join button
        joinButton.layer.cornerRadius = 18
        joinButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        joinButton.backgroundColor = .systemTeal
        joinButton.setTitleColor(.white, for: .normal)
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
        driverName: String,
        driverYear: String? = nil,
        driverImage: UIImage? = nil
    ) {

        // MARK: Driver Info
        nameLabel.text = driverName
        yearLabel.text = driverYear ?? "Student"

        if let img = driverImage {
            profileImageView.image = img
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        // MARK: Route
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text = ride.destination.address ?? "To"

        // MARK: Time
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        timeLabel.text = formatter.string(from: ride.departureTime)

        // MARK: Vehicle + Seats
        configureVehicle(
//            vehicleType: ride.vehicleType,
            vehicleType: "car",
            seats: ride.seatsTotal
        )

        // MARK: Price
        let price = Int(ride.farePerSeat)
        priceLabel.text = "₹\(price)"

        // MARK: Join Button
        joinButton.setTitle("+ Join Ride", for: .normal)
        joinButton.isEnabled = ride.seatsTotal > 0
        joinButton.alpha = ride.seatsTotal > 0 ? 1.0 : 0.5
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
    }
}
