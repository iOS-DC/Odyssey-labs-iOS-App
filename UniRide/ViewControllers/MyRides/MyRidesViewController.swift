//
//  MyRidesViewController.swift
//  UniRide
//
//  Created by Jagpreet Singh on 23/11/25.
//  (Full VC — automaticDimension + delegate wiring + requests handling)
//

import UIKit
import MapKit

class MyRidesViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    private var upcomingTrips: [RideDataModel.MyTrip] = []
    private var pastTrips: [RideDataModel.MyTrip] = []
    private var currentTrips: [RideDataModel.MyTrip] = []

    // Nib / reuse identifiers (ensure XIB identifiers match these)
    private let hostingCellNibName = "UpcomingTableViewCell"
    private let hostingCellReuseId =  "UpcomingRideCell"
    private let passengerCellNibName = "UpcomingPassengerTableViewCell"
    private let passengerCellReuseId = "UpcomingPassengerTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = 0

        // Register nibs - ensure these nib files exist in your project
        tableView.register(UINib(nibName: hostingCellNibName, bundle: nil),
                           forCellReuseIdentifier: hostingCellReuseId)
        tableView.register(UINib(nibName: passengerCellNibName, bundle: nil),
                           forCellReuseIdentifier: passengerCellReuseId)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none

        // Automatic sizing so the cell grows when requests area is expanded
        tableView.rowHeight =  480 // UITableView.automaticDimension
        tableView.estimatedRowHeight = 260
        tableView.tableFooterView = UIView()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRequestsUpdated(_:)),
                                               name: .rideRequestsUpdated,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRequestsUpdated(_:)),
                                               name: .ridesUpdated,    // NEW
                                               object: nil)

        // initial load
        reloadTripsFromModel()
        updateForSelectedSegment()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTripsFromModel()
        updateForSelectedSegment()
    }

    // MARK: - Model loading
    private func reloadTripsFromModel() {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            upcomingTrips = []
            pastTrips = []
            currentTrips = []
            DispatchQueue.main.async { [weak self] in self?.tableView.reloadData() }
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
        currentTrips = (segmentedControl.selectedSegmentIndex == 0) ? upcomingTrips : pastTrips
        tableView.reloadData()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateForSelectedSegment()
    }

    // MARK: - Actions from cells
    @objc private func cancelRideTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        guard trip.role == .hosting else { return }
        RideDataModel.shared.cancelRide(id: trip.ride.id)
        reloadTripsFromModel()
        updateForSelectedSegment()
    }

    @objc private func cancelRequestTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        guard trip.role == .passenger else { return }
        guard let me = UserDataModel.shared.getCurrentUser() else { return }

        if let requestID = trip.requestID {
            RideDataModel.shared.cancelMyRequest(requestID: requestID, passengerUserID: me.id)
            NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
            reloadTripsFromModel()
            updateForSelectedSegment()
            return
        }

        let reqs = RideDataModel.shared.listRequests(for: trip.ride.id)
        if let myReq = reqs.first(where: { $0.passengerUserID == me.id && $0.status == .pending }) {
            RideDataModel.shared.cancelMyRequest(requestID: myReq.id, passengerUserID: me.id)
            NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
            reloadTripsFromModel()
            updateForSelectedSegment()
        }
    }

    // MARK: - Notification handlers
    @objc private func handleRequestsUpdated(_ note: Notification) {
        reloadTripsFromModel()
        updateForSelectedSegment()
    }
}

// MARK: - Table DataSource / Delegate
extension MyRidesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTrips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let trip = currentTrips[indexPath.row]

        switch trip.role {
        case .hosting:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: hostingCellReuseId, for: indexPath) as? UpcomingTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: trip)
            cell.delegate = self

            // wire cancel button tag -> index
            cell.cancelRideButton.tag = indexPath.row
            cell.cancelRideButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.cancelRideButton.addTarget(self, action: #selector(cancelRideTapped(_:)), for: .touchUpInside)
            return cell

        case .passenger:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: passengerCellReuseId, for: indexPath) as? UpcomingPassengerTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: trip)
            cell.cancelRequestButton.tag = indexPath.row
            cell.cancelRequestButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.cancelRequestButton.addTarget(self, action: #selector(cancelRequestTapped(_:)), for: .touchUpInside)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UpcomingTableViewCellDelegate
extension MyRidesViewController: UpcomingTableViewCellDelegate {
    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()

        // scroll to middle so expanded content is visible
        if let idx = tableView.indexPath(for: cell) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                self.tableView.scrollToRow(at: idx, at: .middle, animated: true)
            }
        }
    }

    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell) {
        // implement your chat/message flow
    }

    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell) {
        // implement call flow
    }

    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell) {
        // map cell -> index path
        guard let idx = tableView.indexPath(for: cell) else { return }
        let tempButton = UIButton()
        tempButton.tag = idx.row
        cancelRideTapped(tempButton)
        // above line is a compact helper; if you don't have thenSet, simply call cancelRideTapped with a temporary button
    }

    func upcomingCellDidTapViewRequests(_ cell: UpcomingTableViewCell) {
        // optionally handle when user explicitly requests to view requests
        upcomingCellRequestsToggled(cell)
    }
}
