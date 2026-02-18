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
    var onTap: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        cardContainerView.addGestureRecognizer(tap)
        cardContainerView.isUserInteractionEnabled = true

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardContainerView.layer.cornerRadius = 20
        cardContainerView.backgroundColor = .systemBackground

        fromLabel.numberOfLines = 1
        toLabel.numberOfLines = 1
        fromLabel.lineBreakMode = .byTruncatingTail
        toLabel.lineBreakMode = .byTruncatingTail

        // Layout priorities to prevent truncation on small devices
        fromLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fromLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        viewDetailsButton.setContentHuggingPriority(.required, for: .horizontal)
        viewDetailsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
        @objc private func handleTap() {
            onTap?()
        }

        func configure(with trip: RideDataModel.MyTrip) {

            let ride = trip.ride   // 👈 extract the Ride

            let fromText = formatLocation(ride.source.address)
            let toText = formatLocation(ride.destination.address)
            fromLabel.text = fromText
            toLabel.text = (fromText == toText) ? "Nearby" : toText

            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            timeLabel.text = formatter.string(from: ride.departureTime)

            viewDetailsButton.setTitle("View More Details", for: .normal)
        }

        private func formatLocation(_ address: String?) -> String {
            guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !address.isEmpty else { return "Campus" }
            // Return only the first word — e.g. "Chitkara University Road" → "Chitkara"
            return address
                .components(separatedBy: CharacterSet(charactersIn: " ,"))
                .first(where: { !$0.isEmpty }) ?? address
        }

}
