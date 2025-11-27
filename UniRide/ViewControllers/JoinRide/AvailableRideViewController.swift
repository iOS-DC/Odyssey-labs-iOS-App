//
//  AvailableRideViewController.swift
//  UniRide
//
//  Created by Jagpreet Singh on 26/11/25.
//

import UIKit
import MapKit


class AvailableRideViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    // Coming from JoinRideViewController
    var fromCoordinate: CLLocationCoordinate2D?
    var toCoordinate: CLLocationCoordinate2D?
    var date: Date?
    var time: Date?

    // Replace `Ride` with your actual ride model type
    var rides: [Ride] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Available Rides"

        tableView.delegate = self
        tableView.dataSource = self

        // ✅ register your xib cell
        let nib = UINib(nibName: "RideTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "RideTableViewCell")

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140

        loadDummyRidesForNow()
    }

    private func loadDummyRidesForNow() {
        // TODO: replace with real API / Firestore data later.
        // For now, create few dummy `Ride` objects that match
        // the properties used in RideTableViewCell.configure

        // Example ONLY – change to your own model initialiser:
        /*
        let r1 = Ride(
            source: .init(address: "Campus Gate"),
            destination: .init(address: "Mall Road"),
            departureTime: Date(),
            seatsTotal: 2,
            farePerSeat: 50
        )
        let r2 = Ride(
            source: .init(address: "Hostel"),
            destination: .init(address: "City Center"),
            departureTime: Date().addingTimeInterval(3600),
            seatsTotal: 3,
            farePerSeat: 70
        )
        rides = [r1, r2]
        */
        tableView.reloadData()
    }

    @objc private func joinButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let ride = rides[index]
        print("Join tapped for ride:", ride)
        // TODO: push confirmation screen / call API etc.
    }
}


extension AvailableRideViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return rides.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "RideTableViewCell",
            for: indexPath
        ) as? RideTableViewCell else {
            return UITableViewCell()
        }

        let ride = rides[indexPath.row]
        cell.configure(with: ride)

        // hook join button
        cell.joinButton.tag = indexPath.row
        cell.joinButton.addTarget(self,
                                  action: #selector(joinButtonTapped(_:)),
                                  for: .touchUpInside)

        return cell
    }
}
