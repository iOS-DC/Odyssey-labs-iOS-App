//
//  RideTableViewCell.swift
//  UniRide
//

import UIKit

class RideTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var vehicleLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var cardContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardContainerView.backgroundColor = UIColor.systemBackground
        cardContainerView.layer.cornerRadius = 20
        cardContainerView.layer.masksToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.masksToBounds = false
        selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowRect = cardContainerView.frame
        layer.shadowPath = UIBezierPath(
            roundedRect: shadowRect,
            cornerRadius: cardContainerView.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Configure Function
    func configure(with ride: Ride, driverName: String) {

        // DRIVER NAME
        nameLabel.text = driverName
        yearLabel.text = "3rd Year CSE"

        // Route
        fromLabel.text = ride.source.address
        toLabel.text = ride.destination.address

        // Time
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        timeLabel.text = formatter.string(from: ride.departureTime)

        // Vehicle info (static for now)
        vehicleLabel.text = "Bike"

        // Seats
        seatsLabel.text = "\(ride.seatsTotal) seats"

        // Price
        priceLabel.text = "₹\(ride.farePerSeat) / seat"

        // Button
        joinButton.setTitle("Join Ride", for: .normal)

        // Default profile image
        profileImageView.image = UIImage(named: "defaultProfile")
    }
}
