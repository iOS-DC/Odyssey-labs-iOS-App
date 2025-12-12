//
//  HomeViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController {

    @IBOutlet weak var greetingsLabel: UILabel!
    @IBOutlet weak var homeTableView: UITableView!
   
    var upcomingRide: RideDataModel.MyTrip?
    var nearbyRides: [Ride] = []

    var events: [EventItem] = MockData.sampleEvents

    override func viewDidLoad() {
            super.viewDidLoad()

            let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "User"
            greetingsLabel.text = "Hey, \(name)"

            homeTableView.backgroundColor = UIColor(named: "Color")
            
            setupTable()

            // Listener for live location updates
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleLiveLocationUpdate(_:)),
                name: .LocationServiceDidUpdate,
                object: nil
            )
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchRideData()
            homeTableView.reloadData()
        }

        // ADDED — Called automatically whenever user moves
        @objc func handleLiveLocationUpdate(_ note: Notification) {
            guard let loc = note.userInfo?["location"] as? CLLocation else { return }

            let point = LocationPoint(
                lat: loc.coordinate.latitude,
                lon: loc.coordinate.longitude,
                address: nil
            )

            // Save location to user profile
            UserDataModel.shared.updateUserLocation(point)

            // Refresh nearby rides
            fetchRideData()

            // Reload UI
            homeTableView.reloadData()
        }


    func fetchRideData() {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            upcomingRide = nil
            nearbyRides = []
            return
        }

        let model = RideDataModel.shared

        let upcoming = model.myUpcoming(userID: user.id)
        upcomingRide = upcoming.first

        // user has a saved location
        if let homeLoc = user.savedHomeLocation {
            
            nearbyRides = model.ridesNear(homeLoc, maxMeters: 300).filter {
                $0.driverUserID != user.id
            }
            
            nearbyRides = Array(nearbyRides.prefix(3))

        } else {
            
            print("⚠️ No user location → showing limited fallback rides")
            let all = model.getAllRides()
                .filter { $0.status == .published && $0.driverUserID != user.id }

            nearbyRides = Array(all.prefix(5))
        }
    }


        func setupTable() {
            homeTableView.delegate = self
            homeTableView.dataSource = self
            homeTableView.separatorStyle = .none

            homeTableView.register(
                UINib(nibName: "RideTableViewCell", bundle: nil),
                forCellReuseIdentifier: "RideCell"
            )

            homeTableView.register(
                UINib(nibName: "EventTableViewCell", bundle: nil),
                forCellReuseIdentifier: "EventCell"
            )

            homeTableView.register(
                UINib(nibName: "UpcomingTableViewCell", bundle: nil),
                forCellReuseIdentifier: "UpcomingRideCell"
            )
        }

        @IBAction func offerRideTapped(_ sender: UIButton) {
            let sb = UIStoryboard(name: "OfferRide", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OfferRideViewController") as! OfferRideViewController
            navigationController?.pushViewController(vc, animated: true)
        }

        @IBAction func joinRide(_ sender: UIButton) {
            let sb = UIStoryboard(name: "JoinRide", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "JoinRideViewController") as! JoinRideViewController
            navigationController?.pushViewController(vc, animated: true)
        }
    }



extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if upcomingRide != nil {
            return 3   // Upcoming + Nearby + Events
        }
        return 2       // Nearby + Events
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if upcomingRide != nil {
            if section == 0 { return "Upcoming Ride" }
            if section == 1 { return "Nearby Rides" }
            return "Top Events"
        } else {
            if section == 0 { return "Nearby Rides" }
            return "Top Events"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if upcomingRide != nil {
            if section == 0 { return 1 }
            if section == 1 { return nearbyRides.count }
            return events.count
        } else {
            if section == 0 { return nearbyRides.count }
            return events.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // CASE: user HAS upcoming ride
        if upcomingRide != nil {

            switch indexPath.section {

            case 0:  // UPCOMING RIDE
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "UpcomingRideCell",
                    for: indexPath
                ) as! UpcomingTableViewCell
                if let trip = upcomingRide {
                    cell.configure(with: trip)
                }
                return cell

            case 1: // NEARBY RIDES
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RideCell",
                    for: indexPath
                ) as! RideTableViewCell
                let ride = nearbyRides[indexPath.row]
                let driverName = MockData.driverNames[indexPath.row % MockData.driverNames.count]
                cell.configure(with: ride, driverName: driverName)

                return cell

            case 2: // EVENTS
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "EventCell",
                    for: indexPath
                ) as! EventTableViewCell
                cell.configure(with: events[indexPath.row])
                return cell

            default:
                fatalError("Invalid section")
            }
        }

        // CASE: NO upcoming ride
        switch indexPath.section {

        case 0: // NEARBY RIDES
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "RideCell",
                for: indexPath
            ) as! RideTableViewCell
            let ride = nearbyRides[indexPath.row]
            let driverName = MockData.driverNames[indexPath.row % MockData.driverNames.count]
            cell.configure(with: ride, driverName: driverName)
            return cell

        case 1: // EVENTS
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "EventCell",
                for: indexPath
            ) as! EventTableViewCell
            cell.configure(with: events[indexPath.row])
            return cell

        default:
            fatalError("Invalid section")
        }
    }


    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {

        if upcomingRide != nil {

            if indexPath.section == 0 {
                return 170
            }   // Upcoming Ride
            if indexPath.section == 1 {
                return 230
            }   // Nearby Rides
            return 155                                  // Events
        }

        // No upcoming ride
        if indexPath.section == 0 { return 230 }       // Nearby rides only
        return 155                                     // Events
    }


    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        // Add top & bottom padding
        let inset: CGFloat = 12
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: 0, dy: inset / 2)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .black
        label.text = self.tableView(tableView, titleForHeaderInSection: section)
        return label
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
