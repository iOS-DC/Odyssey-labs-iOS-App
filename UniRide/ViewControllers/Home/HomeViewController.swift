//
//  HomeViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var ridesStackView: UIStackView!
    @IBOutlet weak var eventsStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "User"
        greetingLabel.text = "Hey, \(name)"

        loadRides()
        loadEvents()
    }
    func loadRides() {
        // Remove the placeholder card
        ridesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for ride in MockData.sampleRides {

            let card: RideCardView = RideCardView.loadFromNib()

            card.nameLabel.text = "Driver"
            card.yearLabel.text = "3rd Year"
            card.fromLabel.text = ride.source.address
            card.toLabel.text = ride.destination.address

            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            card.timeLabel.text = formatter.string(from: ride.departureTime)

            card.vehicleTypeLabel.text = "Car"
            card.seatsLabel.text = "Seats: \(ride.seatsTotal)"
            card.priceLabel.text = "₹\(ride.farePerSeat)"

            card.joinButton.setTitle("Join", for: .normal)

            ridesStackView.addArrangedSubview(card)
        }
    }
    
    
    func loadEvents() {
        eventsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, yyyy"

        for event in MockData.sampleEvents {

            let card: EventCardView = EventCardView.loadFromNib()

            card.titleLabel.text = event.title
            card.locationLabel.text = event.location?.name ?? "Unknown"
            card.dateLabel.text = formatter.string(from: event.startsAt)

            card.attendButton.setTitle("Attend", for: .normal)

            eventsStackView.addArrangedSubview(card)
        }
    }
}

extension UIView {
    static func loadFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
