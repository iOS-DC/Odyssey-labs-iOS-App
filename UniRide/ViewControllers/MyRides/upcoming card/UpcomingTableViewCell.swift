//
//  UpcommingTableViewCell.swift
//  UniRide
//
//  Created by Jagpreet Singh on 23/11/25.
//

import UIKit

class UpcomingTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet weak var cardView: UIView!
    
    // pill at top showing ride lifecycle (Published / Ongoing / Completed / etc.)
    @IBOutlet weak var statusLabel: UILabel!
    
    // small text label showing your role (Hosting / Passenger)
    @IBOutlet weak var roleLabel: UILabel!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var cancelRideButton: UIButton!
    
    @IBOutlet weak var passengersLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        messageButton.layer.cornerRadius = 12
        callButton.layer.cornerRadius   = 12
        cancelRideButton.layer.cornerRadius = 12
        
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.backgroundColor = .systemBackground
        
        // subtle shadow
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius  = 6
        
        // default pill style; colors will be adjusted in configure()
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        
        roleLabel.textColor = .secondaryLabel
        
        cardView.backgroundColor = UIColor.systemGray6 // or .systemPink for stronger check
        contentView.backgroundColor = .clear

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // MARK: - Configure
    
    func configure(with trip: RideDataModel.MyTrip) {
        print("configure called for ride:", trip.ride.id)

        let ride = trip.ride
        
        // 🔹 ROLE STATUS (you are hosting / passenger)
        // This cell is mainly used for hosting, but we still respect the role from MyTrip.
        switch trip.role {
        case .hosting:
            roleLabel.text = "Hosting"
        case .passenger:
            roleLabel.text = "Passenger"
        }
        
        // 🔹 RIDE STATUS PILL (Published / Ongoing / Completed / Cancelled / Draft)
        switch ride.status {
        case .published:
            statusLabel.text = "Published"
            statusLabel.textColor = .systemGreen
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            
        case .ongoing:
            statusLabel.text = "Ongoing"
            statusLabel.textColor = .systemBlue
            statusLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            
        case .completed:
            statusLabel.text = "Completed"
            statusLabel.textColor = .systemGray
            statusLabel.backgroundColor = UIColor.systemGray5
            
        case .cancelled:
            statusLabel.text = "Cancelled"
            statusLabel.textColor = .systemRed
            statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            
        case .draft:
            statusLabel.text = "Draft"
            statusLabel.textColor = .systemOrange
            statusLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        }
        
        // 🔹 DATE
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        dateLabel.text = df.string(from: ride.departureTime)
        
        // 🔹 SEATS (booked/total like "2/4 seats")
        let booked = ride.seatsTotal - ride.seatsAvailable
        seatsLabel.text = "\(booked)/\(ride.seatsTotal) seats"
        
        // 🔹 ROUTE
        fromLabel.text = ride.source.address ?? "Source"
        toLabel.text   = ride.destination.address ?? "Destination"
        
        // 🔹 TIMES
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)
        
        // You can compute endTime if you have a duration; for now fake 2h
        let endDate = ride.departureTime.addingTimeInterval(2 * 3600)
        endTimeLabel.text = tf.string(from: endDate)
        durationLabel.text = "2h"  // placeholder
        
        // 🔹 Passengers label
        passengersLabel.text = "Passengers >"
    }
}
