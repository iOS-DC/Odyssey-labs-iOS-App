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

    // MARK: - Data Sources
    var upcomingRide: RideDataModel.MyTrip?
    var nearbyRides: [Ride] = []

    // Events stay hardcoded — MockData
    var events: [EventItem] = MockData.sampleEvents

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "User"
        greetingsLabel.text = "Hey, \(name)"

        homeTableView.layer.backgroundColor = UIColor(named: "#F6FAFB")?.cgColor

        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchRideData()
        homeTableView.reloadData()
    }

    // MARK: - Load REAL DATA

    func fetchRideData() {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            upcomingRide = nil
            nearbyRides = []
            return
        }

        let model = RideDataModel.shared

        // UPCOMING RIDE (JSON backed)
        let upcoming = model.myUpcoming(userID: user.id)
        upcomingRide = upcoming.first

        // NEARBY RIDES (JSON backed)
        //
        // 🔥 Since UserProfile has NO homeLocation,
        // we simply show all rides except user's own.
        //
        if let homeLoc = user.savedHomeLocation {
            nearbyRides = model.ridesNear(homeLoc, maxMeters: 15000)
                .filter { $0.driverUserID != user.id }
        } else {
            nearbyRides = model.getAllRides()
                .filter { $0.status == .published }
                .filter { $0.driverUserID != user.id }
        }


    }

    // MARK: - Table Setup

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

    // MARK: - Buttons

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

// MARK: - TableView Delegate + DataSource

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

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {

        if upcomingRide != nil {
            if section == 0 { return 1 }
            if section == 1 { return nearbyRides.count }
            return events.count
        } else {
            if section == 0 { return nearbyRides.count }
            return events.count
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 🔹 CASE: user HAS upcoming ride
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
                cell.configure(with: nearbyRides[indexPath.row])
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

        // 🔹 CASE: NO upcoming ride
        switch indexPath.section {

        case 0: // NEARBY RIDES
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "RideCell",
                for: indexPath
            ) as! RideTableViewCell
            cell.configure(with: nearbyRides[indexPath.row])
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
            if indexPath.section == 0 { return 180 }
            if indexPath.section == 1 { return 200 }
            return 180
        }

        if indexPath.section == 0 { return 200 }
        return 180
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .black
        label.text = self.tableView(tableView, titleForHeaderInSection: section)
        return label
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
