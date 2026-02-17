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

        // Match Home page card styling - flat design with 20pt corners
        cardView.layer.cornerRadius = 20
        cardView.backgroundColor = .systemBackground

        // Image view
        hostImageView.clipsToBounds = true
        hostImageView.contentMode = .scaleAspectFill
        hostImageView.image = UIImage(systemName: "person.crop.circle.fill")
        hostImageView.tintColor = .systemGray3
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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

        // Ride status badge
        rideStatusLabel.text = "  \(ride.status.rawValue.capitalized)  "
        let (rideBgColor, rideTextColor): (UIColor, UIColor)
        switch ride.status {
        case .published:
            rideBgColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15)
            rideTextColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        case .ongoing:
            rideBgColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.15)
            rideTextColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        case .completed:
            rideBgColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 0.10)
            rideTextColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0)
        case .cancelled:
            rideBgColor = UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 0.15)
            rideTextColor = UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0)
        case .draft:
            rideBgColor = UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 0.15)
            rideTextColor = UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0)
        }
        applyBadgeStyle(to: rideStatusLabel, backgroundColor: rideBgColor, textColor: rideTextColor)

        // Role label with badge style
        let roleText = trip.role == .passenger ? "  Passenger  " : "  Hosting  "
        roleLabel.text = roleText
        applyBadgeStyle(to: roleLabel, backgroundColor: .systemGray6, textColor: .darkGray)

        // Request / booking status badge
        if let status = trip.requestStatus {
            if status == .approved {
                requestStatusLabel.text = "  Confirmed  "
                applyBadgeStyle(
                    to: requestStatusLabel,
                    backgroundColor: UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15),
                    textColor: UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                )
            } else {
                requestStatusLabel.text = "  \(status.rawValue.capitalized)  "
                applyBadgeStyle(
                    to: requestStatusLabel,
                    backgroundColor: UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 0.15),
                    textColor: UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0)
                )
            }
        } else {
            // Defensive: if there's a confirmed booking for the current user, show Confirmed
            if let me = UserDataModel.shared.getCurrentUser() {
                let bookings = RideDataModel.shared.listBookings(for: ride.id)
                if bookings.contains(where: { $0.passengerUserID == me.id && $0.status == .confirmed }) {
                    requestStatusLabel.text = "  Confirmed  "
                    applyBadgeStyle(
                        to: requestStatusLabel,
                        backgroundColor: UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15),
                        textColor: UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                    )
                } else {
                    requestStatusLabel.text = "-"
                    requestStatusLabel.backgroundColor = .clear
                }
            } else {
                requestStatusLabel.text = "-"
                requestStatusLabel.backgroundColor = .clear
            }
        }

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

            if let imgName = avatarName, let image = UIImage(named: imgName) {
                hostImageView.image = image
            } else {
                hostImageView.image = UIImage(systemName: "person.crop.circle.fill")
                hostImageView.tintColor = .systemGray3
            }
        } else {
            hostNameLabel.text = "Host (\(driverID.uuidString.prefix(6)))"
            hostImageView.image = UIImage(systemName: "person.crop.circle.fill")
            hostImageView.tintColor = .systemGray3
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
