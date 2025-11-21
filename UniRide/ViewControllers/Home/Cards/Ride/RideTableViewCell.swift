//
//  RideTableViewCell.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 21/11/25.
//

import UIKit

class RideTableViewCell: UITableViewCell {

    // MARK: - Outlets
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

    override func awakeFromNib() {
        super.awakeFromNib()

        // Optional styling
        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
    }

    // MARK: - Configure Function
    func configure(with ride: Ride) {

        // Hardcoded driver name for now
        nameLabel.text = "Krish Bahukhandi"
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
        seatsLabel.text = "\(ride.seatsTotal) seat"

        // Price
        priceLabel.text = "₹\(ride.farePerSeat) / seat"

        // Button
        joinButton.setTitle("Join Ride", for: .normal)

        // Optional default image
        profileImageView.image = UIImage(named: "defaultProfile")
    }
}

