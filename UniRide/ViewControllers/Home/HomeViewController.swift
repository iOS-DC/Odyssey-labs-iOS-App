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
   
    @IBOutlet weak var requestButton: UIButton!
    var upcomingRide: RideDataModel.MyTrip?
    var nearbyRides: [Ride] = []

    var events: [EventItem] = []

    override func viewDidLoad() {
            super.viewDidLoad()

            let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "User"
            greetingsLabel.text = "Hi, \(name.split(separator: " ").first ?? "User")"
            
            homeTableView.backgroundColor = UIColor(named: "Color")
//            requestButton.layer.borderWidth = 2
//            requestButton.layer.borderColor = UIColor.systemBlue.cgColor
            setupTable()

            // Load Top Events from the same source as Community
            events = EventDataModel.shared.eventList()
            events = Array(events.prefix(2))

            // Listener for live location updates
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleLiveLocationUpdate(_:)),
                name: .LocationServiceDidUpdate,
                object: nil
            )
    }
    
    private func openMyRideTab() {
        guard let tabBarController = self.tabBarController else { return }

        // MyRide is at index 1
        tabBarController.selectedIndex = 1
    }

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

        let request = RideRequest(
            rideID: ride.id,
            passengerUserID: user.id,
            pickupPoint: ride.source,
            seats: 1
        )

        let createdRequest = RideDataModel.shared.createJoinRequest(request)

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

    private func openEventDetailsScreen(event: EventItem) {
        let storyboard = UIStoryboard(name: "Community", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EventDetailsVC") as! EventDetailsViewController
        vc.event = event
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func attendEventFromHome(_ sender: UIButton) {
        let index = sender.tag
        guard events.indices.contains(index) else { return }
        let event = events[index]
        openEventDetailsScreen(event: event)
    }
 

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        events = EventDataModel.shared.eventList()
        events = Array(events.prefix(2))
        fetchRideData()
        homeTableView.reloadData()
    }

    // Called automatically whenever user moves
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
            
            print("No user location")
            let all = model.getAllRides().filter { $0.status == .published && $0.driverUserID != user.id }

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
                UINib(nibName: "UpcomingTableHomeViewCell", bundle: nil),
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
            return 3
        }
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if upcomingRide != nil {
            if section == 0 {
                return "Upcoming Ride"
            }
            if section == 1 {
                return "Nearby Rides"
            }
            return "Top Events"
        } else {
            if section == 0 {
                return "Nearby Rides"
            }
            return "Top Events"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if upcomingRide != nil {
            if section == 0 {
                return 1
            }
            if section == 1 {
                return nearbyRides.count
            }
            return events.count
        } else {
            if section == 0 {
                return nearbyRides.count
            }
            return events.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        if upcomingRide != nil {

            switch indexPath.section {

            case 0:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "UpcomingRideCell",
                    for: indexPath
                ) as! UpcomingTableHomeViewCell
                if let trip = upcomingRide {
                    cell.configure(with: trip)
                }
                cell.selectionStyle = .default
                cell.onTap = { [weak self] in
                        self?.openMyRideTab()
                    }
                return cell

            case 1:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RideCell",
                    for: indexPath
                ) as! RideTableViewCell
                let ride = nearbyRides[indexPath.row]
                let driver = UserDataModel.shared.getUser(by: ride.driverUserID)
                let driverName = driver?.fullName ?? ride.driverUserID.uuidString
                let driverYear = driver?.year != nil ? "\(driver!.year!) Year" : nil
                
                cell.configure(
                    with: ride,
                    driverName: driverName,
                    driverYear: driverYear,
                    photoURL: driver?.photoURL
                )
                cell.onJoinTapped = { [weak self] in
                    self?.joinRide(ride)
                }

                return cell

            case 2:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "EventCell",
                    for: indexPath
                ) as! EventTableViewCell
                cell.configure(with: events[indexPath.row])
                cell.attendButton.tag = indexPath.row
                cell.attendButton.removeTarget(nil, action: nil, for: .allEvents)
                cell.attendButton.addTarget(self, action: #selector(attendEventFromHome(_:)), for: .touchUpInside)
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
            let driver = UserDataModel.shared.getUser(by: ride.driverUserID)
            let driverName = driver?.fullName ?? ride.driverUserID.uuidString
            let driverYear = driver?.year != nil ? "\(driver!.year!) Year" : nil
            
            cell.configure(
                with: ride,
                driverName: driverName,
                driverYear: driverYear,
                photoURL: driver?.photoURL
            )
            cell.onJoinTapped = { [weak self] in
                self?.joinRide(ride)
            }
            return cell

        case 1: // EVENTS
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "EventCell",
                for: indexPath
            ) as! EventTableViewCell
            cell.configure(with: events[indexPath.row])
            cell.attendButton.tag = indexPath.row
            cell.attendButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.attendButton.addTarget(self, action: #selector(attendEventFromHome(_:)), for: .touchUpInside)
            return cell

        default:
            fatalError("Invalid section")
        }
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if upcomingRide != nil {

            if indexPath.section == 0 {
                return 90
            }   // Upcoming Ride
            if indexPath.section == 1 {
                return 220
            }   // Nearby Rides
            return 150                                  // Events
        }

        // No upcoming ride
        if indexPath.section == 0 { return 220 }       // Nearby rides only
        return 150                                     // Events
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if upcomingRide != nil {
            if indexPath.section == 2 {
                let event = events[indexPath.row]
                openEventDetailsScreen(event: event)
            }
        } else {
            if indexPath.section == 1 {
                let event = events[indexPath.row]
                openEventDetailsScreen(event: event)
            }
        }
    }


    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

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
