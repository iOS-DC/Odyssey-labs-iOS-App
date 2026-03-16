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
    var events: [EventItem] = []

    private var isLoading = false
    private var didAnimateListOnFirstShow = false
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        homeTableView.backgroundColor = UIColor(named: "Color")
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
        // Always refresh greeting in case session was just restored
        updateGreeting()
        loadData()
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
        requestButton.applyProminentPrimaryCTA(title: "Request Ride")
        offerButton.applyProminentPrimaryCTA(title: "Offer Ride")
    }

    private func configureScrollingHeader() {
        guard let buttonStack = offerButton.superview else { return }
        
        // Remove only the button stack from main view hierarchy
        buttonStack.removeFromSuperview()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Re-pin the table view to start below the greetings label
        homeTableView.translatesAutoresizingMaskIntoConstraints = false
        homeTableView.topAnchor.constraint(equalTo: greetingsLabel.bottomAnchor, constant: 16).isActive = true
        
        // Create the scrolling container just for the buttons
        let headerView = UIView()
        headerView.addSubview(buttonStack)
        
        if let stack = buttonStack as? UIStackView {
            stack.distribution = .fillEqually
            stack.spacing = 16
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
        greetingsLabel.text = "\(timeGreeting), \(first) 👋"
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
        let vc = RideDetailViewController()
        vc.ride = ride
        vc.driver = driver
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func attendEventFromHome(_ sender: UIButton) {
        guard events.indices.contains(sender.tag) else { return }
        openEventDetailsScreen(event: events[sender.tag])
    }

    @objc private func seeAllEventsTapped() {
        // Switch to Community tab (index 2)
        tabBarController?.selectedIndex = 2
    }

    @IBAction func offerRideTapped(_ sender: UIButton) {
        ensureAuthenticated(action: "offer a ride") { [weak self] in
            let sb = UIStoryboard(name: "OfferRide", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OfferRideViewController") as! OfferRideViewController
            self?.navigationController?.pushViewController(vc, animated: true)
        }
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
            title: "No nearby rides",
            body: "No rides found near your location right now.\nTry offering a ride!",
            tintColor: AppDesign.Color.primary
        )
        esv.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(esv)
        NSLayoutConstraint.activate([
            esv.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            esv.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            esv.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            esv.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
        ])
        return cell
    }

    // MARK: - Section index helpers

    private var upcomingSectionIndex: Int? { upcomingRide != nil ? 0 : nil }
    private var ridesSectionIndex: Int { upcomingRide != nil ? 1 : 0 }
    private var eventsSectionIndex: Int { upcomingRide != nil ? 2 : 1 }
}

// MARK: - UITableViewDelegate / DataSource

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if isLoading { return 1 }
        return upcomingRide != nil ? 3 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading { return 4 }

        if section == upcomingSectionIndex { return 1 }
        if section == ridesSectionIndex { return max(nearbyRides.count, 1) }  // 1 for empty state
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

        // ── Events ──
        if indexPath.section == eventsSectionIndex {
            if events.isEmpty {
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.textLabel?.text = "No upcoming events"
                cell.textLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.font = AppDesign.Typography.subheadline
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
        if indexPath.section == ridesSectionIndex { return nearbyRides.isEmpty ? 200 : 220 }
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
        label.applyTextStyle(AppDesign.Typography.title)

        if section == upcomingSectionIndex      { label.text = "Upcoming Ride" }
        else if section == ridesSectionIndex    { label.text = "Rides Available" }
        else if section == eventsSectionIndex   { label.text = "Top Events" }

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppDesign.Spacing.md),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        // "See All" button only on Events section
        if section == eventsSectionIndex {
            let seeAll = UIButton(type: .system)
            seeAll.setTitle("See All", for: .normal)
            seeAll.titleLabel?.font = AppDesign.Typography.captionStrong
            seeAll.tintColor = AppDesign.Color.primary
            seeAll.translatesAutoresizingMaskIntoConstraints = false
            seeAll.addTarget(self, action: #selector(seeAllEventsTapped), for: .touchUpInside)
            container.addSubview(seeAll)
            NSLayoutConstraint.activate([
                seeAll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppDesign.Spacing.md),
                seeAll.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isLoading ? 0 : 52
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
