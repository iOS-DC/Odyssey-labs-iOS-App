//
//  UpcomingTableViewCell.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/12/25.
//


//
//  UpcomingTableViewCell.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/12/25.
//

import UIKit

class UpcomingTableHomeViewCell: UITableViewCell {

    @IBOutlet weak var cardContainerView: UIView!

        @IBOutlet weak var fromLabel: UILabel!
        @IBOutlet weak var toLabel: UILabel!
        @IBOutlet weak var timeLabel: UILabel!
        @IBOutlet weak var viewDetailsButton: UIButton!

        override func awakeFromNib() {
            super.awakeFromNib()

            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear

            cardContainerView.layer.cornerRadius = 20
            cardContainerView.backgroundColor = .systemBackground
        }

        func configure(with trip: RideDataModel.MyTrip) {

            let ride = trip.ride   // 👈 extract the Ride

            fromLabel.text = ride.source.address ?? "From"
            toLabel.text = ride.destination.address ?? "To"

            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            timeLabel.text = formatter.string(from: ride.departureTime)

            viewDetailsButton.setTitle("View More Details", for: .normal)
        }

    
}
