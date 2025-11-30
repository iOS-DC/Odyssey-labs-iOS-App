//
//  MyRidesViewController.swift
//  UniRide
//

import UIKit

class MyRidesViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    private var upcomingTrips: [RideDataModel.MyTrip] = []
    private var pastTrips: [RideDataModel.MyTrip] = []
    private var currentTrips: [RideDataModel.MyTrip] = []
    
    // local testing flag
    private let seedForTesting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.selectedSegmentIndex = 0
        
        tableView.register(
            UINib(nibName: "UpcomingTableViewCell", bundle: nil),
            forCellReuseIdentifier: "UpcomingRideCell"
        )
        
        tableView.register(
            UINib(nibName: "UpcomingPassengerTableViewCell", bundle: nil),
            forCellReuseIdentifier: "UpcomingPassengerTableViewCell"
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 180
        tableView.estimatedRowHeight = 180
        
        // observe requests/booking changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRequestsUpdated(_:)),
                                               name: .rideRequestsUpdated,
                                               object: nil)
//        
        if seedForTesting {
            seedMockIfEmpty()
        }
        
        reloadTripsFromModel()
        updateForSelectedSegment()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .rideRequestsUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTripsFromModel()
        updateForSelectedSegment()
    }
    
    private func seedMockIfEmpty() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        let src = LocationPoint(lat: 30.516, lon: 76.659, address: "Chitkara University")
        let dst = LocationPoint(lat: 30.35, lon: 76.92, address: "Sector 43, Chandigarh")
        let r = Ride(
            driverUserID: user.id,
            source: src,
            destination: dst,
            departureTime: Date().addingTimeInterval(3600),
            seatsTotal: 3,
            farePerSeat: 60
        )
        let created = RideDataModel.shared.createRide(r)
        RideDataModel.shared.publishRide(id: created.id)
    }
    
    private func reloadTripsFromModel() {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            upcomingTrips = []
            pastTrips = []
            currentTrips = []
            DispatchQueue.main.async { self.tableView.reloadData() }
            return
        }
        
        let userID = currentUser.id
        let model = RideDataModel.shared
        
        upcomingTrips = model.myUpcoming(userID: userID)
        pastTrips = model.myPast(userID: userID)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateForSelectedSegment()
        }
    }
    
    func updateForSelectedSegment() {
        if segmentedControl.selectedSegmentIndex == 0 {
            currentTrips = upcomingTrips
        } else {
            currentTrips = pastTrips
        }
        tableView.reloadData()
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateForSelectedSegment()
    }
    
    @objc private func cancelRideTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        guard trip.role == .hosting else { return }
        RideDataModel.shared.cancelRide(id: trip.ride.id)
        reloadTripsFromModel()
    }
    
    @objc private func cancelRequestTapped(_ sender: UIButton) {
        print("Cancel request tapped at row:", sender.tag)
    }
    
    // called when AvailableRideVC posts .rideRequestsUpdated
    @objc private func handleRequestsUpdated(_ note: Notification) {
        reloadTripsFromModel()
        updateForSelectedSegment()
    }
}

extension MyRidesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return currentTrips.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let trip = currentTrips[indexPath.row]
        
        switch trip.role {
        case .hosting:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "UpcomingRideCell",
                for: indexPath
            ) as? UpcomingTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: trip)
            cell.cancelRideButton.tag = indexPath.row
            cell.cancelRideButton.addTarget(self,
                                            action: #selector(cancelRideTapped(_:)),
                                            for: .touchUpInside)
            return cell
            
        case .passenger:
            guard let cell = tableView.dequeueReusableCell(
              withIdentifier: "UpcomingPassengerTableViewCell",
              for: indexPath
            ) as? UpcomingPassengerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: trip)
            cell.cancelRequestButton.tag = indexPath.row
            cell.cancelRequestButton.addTarget(self,
                                              action: #selector(cancelRequestTapped(_:)),
                                              for: .touchUpInside)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
