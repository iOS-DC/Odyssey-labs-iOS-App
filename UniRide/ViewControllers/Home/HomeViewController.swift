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
    @IBOutlet weak var offerButton: UIButton!
    @IBOutlet weak var requestButton: UIButton!

    var upcomingRide: RideDataModel.MyTrip?
    var nearbyRides: [Ride] = []
    var trips: [Trip] = []
    var events: [EventItem] = []

    private var isLoading = false
    private var didAnimateListOnFirstShow = false
    private let refreshControl = UIRefreshControl()
    private let greetingSubtitleLabel = UILabel()
    private var greetingTopConstraint: NSLayoutConstraint?
    private var tableTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppDesign.Color.groupedBackground
        homeTableView.backgroundColor = AppDesign.Color.groupedBackground
        configureSafeAreaLayout()
        configureQuickActions()
        configureScrollingHeader()
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

    private func configureSafeAreaLayout() {
        greetingsLabel.translatesAutoresizingMaskIntoConstraints = false
        homeTableView.translatesAutoresizingMaskIntoConstraints = false
        greetingsLabel.applyGreetingStyle()
        greetingsLabel.numberOfLines = 1
        greetingsLabel.adjustsFontSizeToFitWidth = true
        greetingsLabel.minimumScaleFactor = 0.75

        greetingSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        greetingSubtitleLabel.text = "Where are you heading today?"
        greetingSubtitleLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        view.addSubview(greetingSubtitleLabel)

        view.constraints.forEach { constraint in
            let firstView = constraint.firstItem as? UIView
            let secondView = constraint.secondItem as? UIView
            let touchesGreeting = firstView == greetingsLabel || secondView == greetingsLabel
            let touchesTable = firstView == homeTableView || secondView == homeTableView

            if touchesGreeting && (constraint.firstAttribute == .top || constraint.secondAttribute == .top) {
                constraint.isActive = false
            }

            if touchesTable && (constraint.firstAttribute == .top || constraint.secondAttribute == .top) {
                constraint.isActive = false
            }
        }

        greetingTopConstraint = greetingsLabel.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: AppDesign.Spacing.md
        )
        tableTopConstraint = homeTableView.topAnchor.constraint(
            equalTo: greetingSubtitleLabel.bottomAnchor,
            constant: AppDesign.Spacing.sm
        )

        NSLayoutConstraint.activate([
            greetingTopConstraint,
            greetingSubtitleLabel.topAnchor.constraint(equalTo: greetingsLabel.bottomAnchor, constant: 2),
            greetingSubtitleLabel.leadingAnchor.constraint(equalTo: greetingsLabel.leadingAnchor),
            tableTopConstraint
        ].compactMap { $0 })
    }

    private func configureScrollingHeader() {
        guard let buttonStack = offerButton.superview else { return }
        
        // Remove only the button stack from main view hierarchy
        buttonStack.removeFromSuperview()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the scrolling container just for the buttons
        let headerView = UIView()
        headerView.addSubview(buttonStack)
        
        if let stack = buttonStack as? UIStackView {
            stack.distribution = .fillEqually
            stack.spacing = 12
        }
        
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 4),
            buttonStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            buttonStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
        
        // Pre-calculate the header's auto-layout height
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: size.height)
        
        homeTableView.tableHeaderView = headerView
    }

    private func setupRefreshControl() {
        refreshControl.tintColor = AppDesign.Color.primary
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        homeTableView.refreshControl = refreshControl
    }

    func setupTable() {
        homeTableView.delegate = self
        homeTableView.dataSource = self
        homeTableView.separatorStyle = .none
        homeTableView.sectionHeaderTopPadding = 0

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
            SkeletonCell.self,
            forCellReuseIdentifier: SkeletonCell.reuseID
        )
        homeTableView.register(
            HomeTripShelfCell.self,
            forCellReuseIdentifier: HomeTripShelfCell.reuseID
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

    @objc private func attendEventFromHome(_ sender: UIButton) {
        guard events.indices.contains(sender.tag) else { return }
        openEventDetailsScreen(event: events[sender.tag])
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

    /// Returns a fully configured empty-state cell — single source of truth.
    private func emptyRidesCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        let esv = EmptyStateView(
            systemImage: "car.fill",
            title: "No rides near you yet",
            body: "Be the first on your route — offer a ride and let classmates find you."
        )
        esv.translatesAutoresizingMaskIntoConstraints = false

        let container = UIStackView(arrangedSubviews: [esv])
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
        ])
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
        if section == eventsSectionIndex { return events.isEmpty ? 1 : events.count }
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

        // ── Events ──
        if indexPath.section == eventsSectionIndex {
            if events.isEmpty {
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                let esv = EmptyStateView(
                    systemImage: "calendar",
                    title: "Nothing on the calendar yet",
                    body: "Check back soon — events from your campus will appear here.",
                    actionTitle: "Browse Community",
                    tintColor: AppDesign.Color.primary
                )
                esv.onAction = { [weak self] in self?.tabBarController?.selectedIndex = 2 }
                esv.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(esv)
                NSLayoutConstraint.activate([
                    esv.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                    esv.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
                    esv.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                    esv.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                ])
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
            cell.configure(with: events[indexPath.row])
            cell.attendButton.tag = indexPath.row
            cell.attendButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.attendButton.addTarget(self, action: #selector(attendEventFromHome(_:)), for: .touchUpInside)
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
        return 150
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !isLoading else { return }

        if indexPath.section == ridesSectionIndex && !nearbyRides.isEmpty {
            let ride = nearbyRides[indexPath.row]
            let driver = ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)
            openRideDetail(ride: ride, driver: driver)
        } else if indexPath.section == eventsSectionIndex && !events.isEmpty {
            openEventDetailsScreen(event: events[indexPath.row])
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

        let container = UIView()
        container.backgroundColor = tableView.backgroundColor ?? view.backgroundColor

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.applyTextStyle(AppDesign.Typography.bodyStrong)

        if section == upcomingSectionIndex      { label.text = "Upcoming Ride" }
        else if section == ridesSectionIndex    { label.text = "Rides Near You" }
        else if section == tripsSectionIndex    { label.text = "Top Trips" }
        else if section == eventsSectionIndex   { label.text = "Top Events" }

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppDesign.Spacing.md),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        // "See All" on Trips and Events sections
        if section == tripsSectionIndex || section == eventsSectionIndex {
            let seeAll = UIButton(type: .system)
            seeAll.setTitle("See All", for: .normal)
            seeAll.titleLabel?.font = AppDesign.Typography.captionStrong
            seeAll.tintColor = AppDesign.Color.primary
            seeAll.translatesAutoresizingMaskIntoConstraints = false
            let action = section == tripsSectionIndex ? #selector(seeAllTripsTapped) : #selector(seeAllEventsTapped)
            seeAll.addTarget(self, action: action, for: .touchUpInside)
            container.addSubview(seeAll)
            NSLayoutConstraint.activate([
                seeAll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppDesign.Spacing.md),
                seeAll.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isLoading ? 0 : 36
    }
}

// MARK: - SkeletonCell

/// A shimmer placeholder cell shown while data is loading.
private final class SkeletonCell: UITableViewCell {
    static let reuseID = "SkeletonCell"

    private let cardView    = UIView()
    private let bar1        = UIView()
    private let bar2        = UIView()
    private let bar3        = UIView()
    private var shimmerLayers: [CAGradientLayer] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = AppDesign.Radius.lg
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        cardView.layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        cardView.layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        [bar1, bar2, bar3].forEach {
            $0.backgroundColor = .systemGray5
            $0.layer.cornerRadius = 6
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDesign.Spacing.md),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDesign.Spacing.md),

            bar1.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            bar1.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bar1.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.45),
            bar1.heightAnchor.constraint(equalToConstant: 14),

            bar2.topAnchor.constraint(equalTo: bar1.bottomAnchor, constant: 12),
            bar2.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bar2.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.65),
            bar2.heightAnchor.constraint(equalToConstant: 12),

            bar3.topAnchor.constraint(equalTo: bar2.bottomAnchor, constant: 12),
            bar3.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bar3.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.35),
            bar3.heightAnchor.constraint(equalToConstant: 12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func startAnimating() {
        shimmerLayers.forEach { $0.removeFromSuperlayer() }
        shimmerLayers = []

        [bar1, bar2, bar3].forEach { bar in
            let shimmer = CAGradientLayer()
            shimmer.colors = [
                UIColor.systemGray5.cgColor,
                UIColor.systemGray4.withAlphaComponent(0.8).cgColor,
                UIColor.systemGray5.cgColor,
            ]
            shimmer.startPoint = CGPoint(x: 0, y: 0.5)
            shimmer.endPoint   = CGPoint(x: 1, y: 0.5)
            shimmer.locations  = [-1, -0.5, 0]
            shimmer.frame      = bar.bounds
            shimmer.cornerRadius = 6
            bar.layer.addSublayer(shimmer)
            shimmerLayers.append(shimmer)

            let anim = CABasicAnimation(keyPath: "locations")
            anim.fromValue = [-1, -0.5, 0]
            anim.toValue   = [1, 1.5, 2]
            anim.duration  = 1.3
            anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            shimmer.add(anim, forKey: "shimmer")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep shimmer layers in sync with bar frame after layout
        zip([bar1, bar2, bar3], shimmerLayers).forEach { bar, shimmer in
            shimmer.frame = bar.bounds
        }
    }
}
