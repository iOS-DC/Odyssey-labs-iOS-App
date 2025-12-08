//
//  ReviewRideViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//

//
//  ReviewRideViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//

import UIKit
import MapKit
struct RideSummary {
    let from: LocationPoint
    let to: LocationPoint
    let date: Date
    let time: Date
    let route: RideRoute?
    let vehicleType: String
    let seats: Int
    let farePerSeat: Double

    var totalFare: Double {
        return farePerSeat * Double(seats)
    }
}
struct DateFormatterHelper {

    static let shared = DateFormatterHelper()

    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
    }

    func formattedDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}


class ReviewRideViewController: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var vehicleLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var fareLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var offerButton: UIButton!

    var summary: RideSummary!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillSummary()
    }

    func setupUI() {

        // Summary Card
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        // Notes Box
        notesTextView.layer.cornerRadius = 12
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor

        // Button
        offerButton.layer.cornerRadius = 18
        offerButton.backgroundColor = .systemGreen
        offerButton.setTitleColor(.white, for: .normal)
    }

    func fillSummary() {

        fromLabel.text = "From \(summary.from.address ?? "")"
        toLabel.text = "To \(summary.to.address ?? "")"

        dateLabel.text = DateFormatterHelper.shared.formattedDate(summary.date)
        timeLabel.text = DateFormatterHelper.shared.formattedTime(summary.time)

        vehicleLabel.text = summary.vehicleType
        seatsLabel.text = "\(summary.seats) seats available"

        fareLabel.text = "₹\(Int(summary.farePerSeat)) per person"
        totalLabel.text = "Total: ₹\(Int(summary.totalFare))"
    }

    @IBAction func offerTapped(_ sender: UIButton) {

        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        let finalDeparture = merge(summary.date, summary.time)

        let ride = Ride(
            driverUserID: user.id,
            source: summary.from,
            destination: summary.to,
            waypoints: [],
            selectedRoute: summary.route,
            departureTime: finalDeparture,
            seatsTotal: summary.seats,
            farePerSeat: summary.farePerSeat,
            status: .published,
            notes: notesTextView.text
        )

        RideDataModel.shared.createRide(ride)

        tabBarController?.selectedIndex = 1
    }

    func merge(_ date: Date, _ time: Date) -> Date {
        let c = Calendar.current

        let d = c.dateComponents([.year, .month, .day], from: date)
        let t = c.dateComponents([.hour, .minute], from: time)

        var comp = DateComponents()
        comp.year = d.year
        comp.month = d.month
        comp.day = d.day
        comp.hour = t.hour
        comp.minute = t.minute

        return c.date(from: comp) ?? Date()
    }
}
