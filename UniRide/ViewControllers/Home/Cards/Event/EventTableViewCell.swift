//
//  EventTableViewCell.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 21/11/25.
//

import UIKit


import UIKit

class EventTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var attendButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
    }

    // MARK: - Configure Function
    func configure(with event: EventItem) {

        // Title
        titleLabel.text = event.title

        // Date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a"
        dateLabel.text = formatter.string(from: event.startsAt)

        // Location
        locationLabel.text = event.location?.name

        // Button title
        attendButton.setTitle("Attend", for: .normal)

        // Event image default
        eventImageView.image = UIImage(named: "eventPlaceholder")
    }
}

