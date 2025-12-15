//
//  AvailableRideViewController.swift
//  UniRide
//
//  Created by Jagpreet Singh on 26/11/25.
//

import UIKit
import MapKit


class AvailableRideViewController: UIViewController,
                                   UITableViewDataSource,
                                   UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    // Coming from JoinRideViewController
    var fromCoordinate: CLLocationCoordinate2D?
       var toCoordinate: CLLocationCoordinate2D?
       var date: Date?
       var time: Date?

       var rides: [Ride] = []

//       //  Add this inside the class (but outside functions)
//       private static var didSeedMockData = false

       override func viewDidLoad() {
           super.viewDidLoad()
           title = "Available Rides"

           tableView.delegate = self
           tableView.dataSource = self

           let nib = UINib(nibName: "RideTableViewCell", bundle: nil)
           tableView.register(nib, forCellReuseIdentifier: "RideTableViewCell")

           tableView.separatorStyle = .none
           tableView.rowHeight = UITableView.automaticDimension
           tableView.estimatedRowHeight = 200

           loadDummyRidesForNow()
       }

    private func loadDummyRidesForNow() {
        guard let fromCoord = fromCoordinate else {
            print("No fromCoordinate passed in")
            rides = []
            tableView.reloadData()
            return
        }

        let fromPoint = LocationPoint(
            lat: fromCoord.latitude,
            lon: fromCoord.longitude,
            address: nil
        )

        // Only rides within 2.5 km of pickup
        let nearby = RideDataModel.shared.ridesNear(fromPoint, maxMeters: 1500)

        print("Nearby rides found:", nearby.count)

        self.rides = nearby
        tableView.reloadData()
    }

    @objc private func joinButtonTapped(_ sender: UIButton) {
        let index = sender.tag
          guard index >= 0 && index < rides.count else { return }
          let ride = rides[index]

          guard let user = UserDataModel.shared.getCurrentUser() else {
              let a = UIAlertController(title: "Sign in", message: "Please sign in to join a ride.", preferredStyle: .alert)
              a.addAction(UIAlertAction(title: "OK", style: .default))
              present(a, animated: true)
              return
          }

          let pickup = ride.source
          let seatsRequested = 1

          let req = RideRequest(
              rideID: ride.id,
              passengerUserID: user.id,
              pickupPoint: pickup,
              seats: seatsRequested
          )

          let createdReq = RideDataModel.shared.createJoinRequest(req)
          print("Created request:", createdReq.id)

          // debug: print model counts
          print("DEBUG: total requests now =", RideDataModel.shared.listRequests(for: ride.id).count)
          print("DEBUG: all requests total =", RideDataModel.shared.listRequests(for: ride.id).count)

          // post notification so MyRides can reload
          NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil, userInfo: ["requestID": createdReq.id.uuidString])

          // switch app to My Rides tab (works whether MyRides is inside a nav controller or not)
          if let tbc = self.tabBarController, let vcs = tbc.viewControllers {
              for (i, vc) in vcs.enumerated() {
                  if let nav = vc as? UINavigationController, let top = nav.viewControllers.first, top is MyRidesViewController {
                      tbc.selectedIndex = i
                      nav.popToRootViewController(animated: false)
                      break
                  } else if vc is MyRidesViewController {
                      tbc.selectedIndex = i
                      break
                  }
              }
          }

          let alert = UIAlertController(title: "Requested", message: "Request sent. Check My Rides → Upcoming.", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          present(alert, animated: true)
      }
   }

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
        let driverName = MockData.driverNames[indexPath.row % MockData.driverNames.count]

        cell.configure(with: ride, driverName: driverName)


        // hook join button
        cell.joinButton.tag = indexPath.row
        cell.joinButton.addTarget(self, action: #selector(joinButtonTapped(_:)), for: .touchUpInside)

        return cell
    }
}
