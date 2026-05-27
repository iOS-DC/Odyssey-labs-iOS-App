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
    @IBOutlet weak var greetingSubtitleLabel: UILabel!
    @IBOutlet weak var homeTableView: UITableView!
    @IBOutlet weak var offerButton: UIButton!
    @IBOutlet weak var requestButton: UIButton!

    var upcomingRide: RideDataModel.MyTrip?
    var nearbyRides: [Ride] = []
    var trips: [Trip] = []
    var events: [EventItem] = []

    private var isLoading = false
    private var didAnimateListOnFirstShow = false
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        styleHeaderLabels()
        configureQuickActions()
        setupTable()
        setupRefreshControl()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLiveLocationUpdate(_:)),
            name: .LocationServiceDidUpdate,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Always refresh greeting in case session was just restored
        updateGreeting()
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateListOnFirstShow else { return }
        didAnimateListOnFirstShow = true
        homeTableView.layoutIfNeeded()
        homeTableView.animateVisibleCellsStaggered()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func configureQuickActions() {
        requestButton.applyProminentPrimaryCTA(title: "Find a Ride")
        offerButton.applyProminentPrimaryCTA(title: "Offer a Ride")
    }

    /// Dynamic typography that can't be expressed in the storyboard.
    /// Layout, text, basic colors live in Home.storyboard.
    private func styleHeaderLabels() {
        greetingsLabel.applyGreetingStyle()
        greetingSubtitleLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
    }

    private func setupRefreshControl() {
        refreshControl.tintColor = AppDesign.Color.primary
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        homeTableView.refreshControl = refreshControl
    }

    func setupTable() {
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
        homeTableView.register(
            UINib(nibName: "HomeSkeletonCell", bundle: nil),
            forCellReuseIdentifier: SkeletonCell.reuseID
        )
        homeTableView.register(
            UINib(nibName: "HomeTripShelfCell", bundle: nil),
            forCellReuseIdentifier: HomeTripShelfCell.reuseID
        )
        homeTableView.register(
            UINib(nibName: "HomeEventShelfCell", bundle: nil),
            forCellReuseIdentifier: HomeEventShelfCell.reuseID
        )
        homeTableView.register(
            UINib(nibName: "HomeEmptyStateCell", bundle: nil),
            forCellReuseIdentifier: HomeEmptyStateCell.reuseID
        )
        homeTableView.contentInset = UIEdgeInsets(top: AppDesign.Spacing.xs, left: 0, bottom: AppDesign.Spacing.lg, right: 0)
    }

    // MARK: - Data

    private func updateGreeting() {
        let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "there"
        let first = String(name.split(separator: " ").first ?? "there")
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12:  timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default:      timeGreeting = "Good evening"
        }
        greetingsLabel.text = "\(timeGreeting), \(first)"
    }

    private func loadData(isRefreshing: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        if !isRefreshing {
            // Show skeleton on first load
            homeTableView.reloadData()
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            await BackendSyncCoordinator.shared.refreshHomeFeedIfEnabled()
            self.trips = Array(TripDataModel.shared.upcomingTrips().prefix(3))
            self.events = Array(EventDataModel.shared.eventList().prefix(4))
            self.fetchRideData()
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.homeTableView.reloadData()
            if !self.didAnimateListOnFirstShow {
                self.didAnimateListOnFirstShow = true
                self.homeTableView.animateVisibleCellsStaggered()
            }
        }
    }

    @objc private func handlePullToRefresh() {
        loadData(isRefreshing: true)
    }

    @objc func handleLiveLocationUpdate(_ note: Notification) {
        guard let loc = note.userInfo?["location"] as? CLLocation else { return }
        let point = LocationPoint(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude, address: nil)
        UserDataModel.shared.updateUserLocation(point)
        fetchRideData()
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
        upcomingRide = upcoming.first(where: { $0.ride.status == .published })

        let searchLocation = user.lastKnownLocation
            ?? UserDataModel.shared.preferredHomeLocation()
            ?? UserDataModel.shared.getCampusLocation()
        nearbyRides = model.ridesNear(searchLocation, maxMeters: 5000)
            .filter { $0.driverUserID != user.id }
        nearbyRides = Array(nearbyRides.prefix(5))
    }

    // MARK: - Navigation

    private func openMyRideTab() {
        tabBarController?.selectedIndex = 1
    }

    private func openEventDetailsScreen(event: EventItem) {
        let storyboard = UIStoryboard(name: "Community", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EventDetailsVC") as! EventDetailsViewController
        vc.event = event
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openRideDetail(ride: Ride, driver: UserProfile?) {
        let sb = UIStoryboard(name: "RideDetail", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "RideDetailViewController") as? RideDetailViewController else { return }
        vc.ride = ride
        vc.driver = driver
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func seeAllEventsTapped() {
        tabBarController?.selectedIndex = 2
    }

    @objc private func seeAllTripsTapped() {
        tabBarController?.selectedIndex = 2
        // Switch community tab to Trips segment (index 1)
        if let nav = tabBarController?.viewControllers?[2] as? UINavigationController,
           let community = nav.topViewController as? CommunityViewController {
            community.segmentedControl?.selectedSegmentIndex = 1
            community.segmentChanged(community.segmentedControl as Any)
        }
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

    // MARK: - Helpers

    /// Returns the XIB-backed empty-state cell configured for "no nearby rides".
    private func emptyRidesCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeEmptyStateCell.reuseID, for: indexPath) as! HomeEmptyStateCell
        cell.configure(
            systemImage: "car.fill",
            title: "No rides near you yet",
            body: "Be the first on your route — offer a ride and let classmates find you."
        )
        return cell
    }

    // MARK: - Section index helpers

    private var upcomingSectionIndex: Int? { upcomingRide != nil ? 0 : nil }
    private var ridesSectionIndex: Int { upcomingRide != nil ? 1 : 0 }
    private var tripsSectionIndex: Int { upcomingRide != nil ? 2 : 1 }
    private var eventsSectionIndex: Int { upcomingRide != nil ? 3 : 2 }
}

// MARK: - UITableViewDelegate / DataSource

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if isLoading { return 1 }
        return upcomingRide != nil ? 4 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading { return 4 }

        if section == upcomingSectionIndex { return 1 }
        if section == ridesSectionIndex { return max(nearbyRides.count, 1) }
        if section == tripsSectionIndex { return trips.isEmpty ? 0 : 1 }
        if section == eventsSectionIndex { return 1 } // one shelf row, or one empty-state row
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // ── Skeleton ──
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: SkeletonCell.reuseID, for: indexPath) as! SkeletonCell
            cell.startAnimating()
            return cell
        }

        // ── Upcoming Ride ──
        if let upcomingIdx = upcomingSectionIndex, indexPath.section == upcomingIdx {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingRideCell", for: indexPath) as! UpcomingTableHomeViewCell
            if let trip = upcomingRide { cell.configure(with: trip) }
            cell.selectionStyle = .default
            cell.onTap = { [weak self] in self?.openMyRideTab() }
            return cell
        }

        // ── Nearby Rides ──
        if indexPath.section == ridesSectionIndex {
            if nearbyRides.isEmpty { return emptyRidesCell(for: tableView, at: indexPath) }
            let cell = tableView.dequeueReusableCell(withIdentifier: "RideCell", for: indexPath) as! RideTableViewCell
            let ride = nearbyRides[indexPath.row]
            let driver = ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)
            cell.configure(with: ride, driver: driver)
            cell.onJoinTapped = { [weak self] in self?.openRideDetail(ride: ride, driver: driver) }
            return cell
        }

        // ── Top Trips shelf ──
        if indexPath.section == tripsSectionIndex {
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeTripShelfCell.reuseID, for: indexPath) as! HomeTripShelfCell
            cell.configure(with: trips)
            cell.onTripTapped = { [weak self] trip in
                guard let self else { return }
                let detail = TripDetailViewController(trip: trip)
                self.navigationController?.pushViewController(detail, animated: true)
            }
            return cell
        }

        // ── Top Events shelf ──
        if indexPath.section == eventsSectionIndex {
            if events.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: HomeEmptyStateCell.reuseID, for: indexPath) as! HomeEmptyStateCell
                cell.configure(
                    systemImage: "calendar",
                    title: "Nothing on the calendar yet",
                    body: "Check back soon — events from your campus will appear here.",
                    actionTitle: "Browse Community",
                    onAction: { [weak self] in self?.tabBarController?.selectedIndex = 2 }
                )
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeEventShelfCell.reuseID, for: indexPath) as! HomeEventShelfCell
            cell.configure(with: events)
            cell.onEventTapped = { [weak self] event in
                self?.openEventDetailsScreen(event: event)
            }
            return cell
        }

        // Safe fallback — should never be reached
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isLoading { return 100 }
        if indexPath.section == upcomingSectionIndex { return UITableView.automaticDimension }
        if indexPath.section == ridesSectionIndex { return nearbyRides.isEmpty ? 240 : 220 }
        if indexPath.section == tripsSectionIndex { return 210 }
        if indexPath.section == eventsSectionIndex { return events.isEmpty ? 240 : 210 }
        return 150
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !isLoading else { return }

        // Nearby rides are still per-row, so they get table-level row taps.
        // Trips and events live inside horizontal shelves and handle taps internally.
        if indexPath.section == ridesSectionIndex && !nearbyRides.isEmpty {
            let ride = nearbyRides[indexPath.row]
            let driver = ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)
            openRideDetail(ride: ride, driver: driver)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Skip inset for the empty-state cell so the icon isn't clipped.
        guard !(indexPath.section == ridesSectionIndex && nearbyRides.isEmpty) else { return }
        let inset: CGFloat = 12
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: 0, dy: inset / 2)
    }

    // MARK: - Section Headers

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isLoading else { return nil }

        let header = HomeSectionHeaderView.loadFromNib()
        header.backgroundColor = tableView.backgroundColor ?? view.backgroundColor

        let title: String
        let showSeeAll: Bool
        if section == upcomingSectionIndex {
            title = "Upcoming Ride"
            showSeeAll = false
        } else if section == ridesSectionIndex {
            title = "Rides Near You"
            showSeeAll = false
        } else if section == tripsSectionIndex {
            title = "Top Trips"
            showSeeAll = true
            header.onSeeAllTapped = { [weak self] in self?.seeAllTripsTapped() }
        } else if section == eventsSectionIndex {
            title = "Top Events"
            showSeeAll = true
            header.onSeeAllTapped = { [weak self] in self?.seeAllEventsTapped() }
        } else {
            title = ""
            showSeeAll = false
        }

        header.configure(title: title, showSeeAll: showSeeAll)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isLoading ? 0 : 36
    }
}
