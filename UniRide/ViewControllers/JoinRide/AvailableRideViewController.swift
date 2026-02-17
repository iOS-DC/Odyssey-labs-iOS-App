//
//  AvailableRideViewController.swift
//  UniRide
//
//  Created by Jagpreet Singh on 26/11/25.
//

import UIKit
import MapKit

final class AvailableRideViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    // Coming from JoinRideViewController
    var fromCoordinate: CLLocationCoordinate2D?
    var toCoordinate: CLLocationCoordinate2D?
    var date: Date?
    var time: Date?

    var rides: [Ride] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Available Rides"

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UINib(nibName: "RideTableViewCell", bundle: nil),
            forCellReuseIdentifier: "RideTableViewCell"
        )

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 280
        

        loadAvailableRides()
    }

    // MARK: - Load Rides
    private func loadAvailableRides() {
        guard let fromCoord = fromCoordinate else {
            print("❌ No pickup coordinate received")
            rides = []
            tableView.reloadData()
            return
        }

        let fromPoint = LocationPoint(
            lat: fromCoord.latitude,
            lon: fromCoord.longitude,
            address: nil
        )

        // 🔥 REAL DATA (NO MOCK)
        let nearbyRides = RideDataModel.shared.ridesNear(fromPoint, maxMeters: 1500)

        print("✅ Nearby rides found:", nearbyRides.count)

        self.rides = nearbyRides
        tableView.reloadData()
    }

    // MARK: - Join Ride
    private func joinRide(_ ride: Ride) {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            let alert = UIAlertController(
                title: "Sign in",
                message: "Please sign in to join a ride.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let pickup = ride.source
        let seatsRequested = 1

        let request = RideRequest(
            rideID: ride.id,
            passengerUserID: user.id,
            pickupPoint: pickup,
            seats: seatsRequested
        )

        let createdRequest = RideDataModel.shared.createJoinRequest(request)

        print("✅ Join request created:", createdRequest.id)
        print("📊 Total requests for ride:",
              RideDataModel.shared.listRequests(for: ride.id).count)

        NotificationCenter.default.post(
            name: .rideRequestsUpdated,
            object: nil,
            userInfo: ["requestID": createdRequest.id.uuidString]
        )

        // Switch to My Rides tab
        if let tbc = tabBarController, let vcs = tbc.viewControllers {
            for (i, vc) in vcs.enumerated() {
                if let nav = vc as? UINavigationController,
                   nav.viewControllers.first is MyRidesViewController {
                    tbc.selectedIndex = i
                    nav.popToRootViewController(animated: false)
                    break
                } else if vc is MyRidesViewController {
                    tbc.selectedIndex = i
                    break
                }
            }
        }

        let alert = UIAlertController(
            title: "Requested",
            message: "Request sent. Check My Rides → Upcoming.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension AvailableRideViewController {

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

        // 🔥 REAL DRIVER NAME (NO MOCK, NO CACHE GUESS)
        let driverName = UserDataModel.shared.getUser(by: ride.driverUserID)?.fullName ?? ride.driverUserID.uuidString

        print("🚗 Ride:", ride.id, "Driver:", driverName)

        cell.configure(with: ride, driverName: driverName)

        cell.onJoinTapped = { [weak self] in
            self?.joinRide(ride)
        }

        return cell
    }
}
