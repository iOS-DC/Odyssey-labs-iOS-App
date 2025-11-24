//
//  UpcommingTableViewCell.swift
//  UniRide
//
//  Created by Jagpreet Singh on 23/11/25.
//

import UIKit

class UpcommingTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var passengersLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        messageButton.layer.cornerRadius = 12
        callButton.layer.cornerRadius = 12

        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.backgroundColor = UIColor.systemBackground  // or a light grey: UIColor.systemGray6

        // subtle shadow
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        
        statusLabel.layer.cornerRadius = 8
            statusLabel.clipsToBounds = true
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            statusLabel.textColor = .systemGreen

    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
        // Configure the view for the selected state
    }
    
    
    func configure(with trip: RideDataModel.MyTrip) {
            let ride = trip.ride

            // Status / role
            statusLabel.text = trip.role == .hosting ? "Hosting" : "Passenger"

            // Date
            let df = DateFormatter()
            df.dateFormat = "EEE, MMM d"
            dateLabel.text = df.string(from: ride.departureTime)

            // Seats
            seatsLabel.text = "\(ride.seatsAvailable)/\(ride.seatsTotal) seats"

            // Route
            fromLabel.text = ride.source.address ?? "Source"
            toLabel.text = ride.destination.address ?? "Destination"

            // Times
            let tf = DateFormatter()
            tf.dateFormat = "HH:mm"
            startTimeLabel.text = tf.string(from: ride.departureTime)
            // You can compute end time if you have duration; for now leave as "--"
            endTimeLabel.text = "--"

            durationLabel.text = "2h"    // temp value or computed

            passengersLabel.text = "Passengers >"
        }
    }
    
