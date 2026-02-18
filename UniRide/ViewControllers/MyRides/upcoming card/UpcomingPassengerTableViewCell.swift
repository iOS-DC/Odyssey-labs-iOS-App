//
//  UpcomingPassengerTableViewCell.swift
//  UniRide
//
//  Created by Jagpreet Singh on 23/11/25.
//  Modified to fix host lookup + timing
//

import UIKit

final class UpcomingPassengerTableViewCell: UITableViewCell {

    // MARK: - IBOutlets (connect in XIB)
    @IBOutlet weak var cardView: UIView!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!

    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    @IBOutlet weak var rideStatusLabel: UILabel!

    @IBOutlet weak var hostNameLabel: UILabel!

    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var requestStatusLabel: UILabel!

    @IBOutlet weak var hostImageView: UIImageView!

    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Unified card styling to match Home page
        cardView.layer.cornerRadius = 18
        cardView.backgroundColor = .systemBackground
        cardView.layer.masksToBounds = true

        // Shadow styling
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        // Image view
        hostImageView.clipsToBounds = true
        hostImageView.contentMode = .scaleAspectFill
        hostImageView.tintColor = .systemGray4
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Compute shadow path based on cardView frame
        layer.shadowPath = UIBezierPath(
            roundedRect: cardView.frame,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
        
        // ensure circular image after layout
        hostImageView.layer.cornerRadius = hostImageView.bounds.height / 2
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {
        let ride = trip.ride

        print("[DEBUG] all users:", UserDataModel.shared.allUsersForDebugging())

        // Debug: show ride & driver ids in console to help diagnose host lookup issues
        print("[DEBUG] UpcomingPassengerCell configure — rideID:", ride.id.uuidString, "driverID:", ride.driverUserID.uuidString)

        // Date label
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        dateLabel.text = df.string(from: ride.departureTime)

        // Times — use selectedRoute.expectedTravelTime if available (seconds), else fallback 2h
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)

        let travelSeconds = ride.selectedRoute?.expectedTravelTime ?? (2 * 3600)
        let endDate = ride.departureTime.addingTimeInterval(travelSeconds)
        endTimeLabel.text = tf.string(from: endDate)
        durationLabel.text = formatDuration(travelSeconds)

        // Route
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text = ride.destination.address ?? "To"

        // Seats
        let booked = ride.seatsTotal - ride.seatsAvailable
        seatsLabel.text = "\(booked)/\(ride.seatsTotal) seats"

        // Hide the old ride status badge — we show request status instead
        rideStatusLabel.isHidden = true

        // Role label
        roleLabel.text = "  Passenger  "
        roleLabel.backgroundColor = UIColor.systemGray6
        roleLabel.textColor = .secondaryLabel
        roleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        roleLabel.layer.cornerRadius = 13
        roleLabel.layer.masksToBounds = true

        // Request / booking status badge — solid filled pill like hosting card
        let isConfirmed: Bool
        if let status = trip.requestStatus {
            isConfirmed = (status == .approved)
        } else {
            // Fallback: check bookings directly
            let me = UserDataModel.shared.getCurrentUser()
            let bookings = RideDataModel.shared.listBookings(for: ride.id)
            isConfirmed = me != nil && bookings.contains(where: { $0.passengerUserID == me!.id && $0.status == .confirmed })
        }

        if isConfirmed {
            requestStatusLabel.text = "  ✓ Confirmed  "
            requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
            requestStatusLabel.textColor = .white
            // Update cancel button title for confirmed booking
            var config = cancelRequestButton.configuration ?? UIButton.Configuration.filled()
            config.title = "Cancel Booking"
            cancelRequestButton.configuration = config
        } else {
            let statusText: String
            let bgColor: UIColor
            if let status = trip.requestStatus {
                switch status {
                case .pending:
                    statusText = "  Pending  "
                    bgColor = UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0)
                case .denied:
                    statusText = "  Denied  "
                    bgColor = UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0)
                case .cancelled:
                    statusText = "  Cancelled  "
                    bgColor = UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0)
                default:
                    statusText = "  \(status.rawValue.capitalized)  "
                    bgColor = UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0)
                }
            } else {
                statusText = "  Pending  "
                bgColor = UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0)
            }
            requestStatusLabel.text = statusText
            requestStatusLabel.backgroundColor = bgColor
            requestStatusLabel.textColor = .white
            var config = cancelRequestButton.configuration ?? UIButton.Configuration.filled()
            config.title = "Cancel Request"
            cancelRequestButton.configuration = config
        }
        requestStatusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        requestStatusLabel.layer.cornerRadius = 13
        requestStatusLabel.layer.masksToBounds = true
        requestStatusLabel.textAlignment = .center

        // Host info — look up user by driverUserID
        // Host info — look up user by driverUserID (KVC-free)
        let driverID = ride.driverUserID
        if let host = UserDataModel.shared.getUser(by: driverID) {
            // Prefer fullName when available
            let name = host.fullName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Mirror-based safe read for `email` and `avatarName` (works for structs/classes)
            var email = ""
            var avatarName: String? = nil
            let mirror = Mirror(reflecting: host)
            if let child = mirror.children.first(where: { $0.label == "email" }), let e = child.value as? String {
                email = e.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let child = mirror.children.first(where: { $0.label == "avatarName" }), let a = child.value as? String {
                avatarName = a
            }

            let display: String
            if !name.isEmpty {
                display = name
            } else if !email.isEmpty {
                display = email
            } else {
                display = "Host"
            }
            hostNameLabel.text = display

            hostImageView.loadAndFallback(from: host.photoURL, name: display)
        } else {
            let fallbackName = "Host"
            hostNameLabel.text = fallbackName
            hostImageView.loadAndFallback(from: nil, name: fallbackName)
            print("[DEBUG] UpcomingPassengerCell: host not found for driverUserID =", driverID.uuidString)
        }



        // Buttons are configured by the view controller (tags/targets)
    }

    // MARK: - Helpers
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(round(seconds / 60.0))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        else if h > 0 { return "\(h)h" }
        else { return "\(m)m" }
    }
    
    // MARK: - Badge Styling
    private func applyBadgeStyle(to label: UILabel, backgroundColor: UIColor, textColor: UIColor) {
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.font = .systemFont(ofSize: 10, weight: .bold) // Slightly smaller font
        label.layer.cornerRadius = 8 // Better pill look
        label.layer.masksToBounds = true
        label.textAlignment = .center
        
        // Horizontal padding is achieved by adding spaces to the text in configure()
    }
}
