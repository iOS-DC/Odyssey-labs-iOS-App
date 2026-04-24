import UIKit
import SwiftUI

final class MyRidesViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton?

    private enum RideFilter { case all, completed, cancelled }
    private var currentFilter: RideFilter = .all

    private var upcomingTrips: [RideDataModel.MyTrip] = []
    private var pastTrips:     [RideDataModel.MyTrip] = []
    private var currentTrips:  [RideDataModel.MyTrip] = []
    /// Past rides grouped by "MMM yyyy" section titles — used when segment == 1
    private var pastSections: [(title: String, trips: [RideDataModel.MyTrip])] = []
    private var didAnimateListOnFirstShow = false

    // Pull-to-refresh
    private let refreshControl = UIRefreshControl()

    // Loading overlay for async trip actions
    private lazy var loadingOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        overlay.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        overlay.isHidden = true
        return overlay
    }()

    // Notification bell
    private let bellBtn   = UIButton(type: .system)
    private let bellBadge = UILabel()
    private var bellTopConstraint: NSLayoutConstraint?

    // Empty states
    private lazy var upcomingEmptyState: EmptyStateView = {
        let v = EmptyStateView(
            systemImage: "car.2.fill",
            title: "Nothing coming up",
            body: "Find a ride nearby, or offer one to classmates.",
            actionTitle: "Find a Ride",
            tintColor: AppDesign.Color.primary
        )
        v.onAction = { [weak self] in
            guard let self else { return }
            let sb = UIStoryboard(name: "JoinRide", bundle: nil)
            guard let vc = sb.instantiateViewController(withIdentifier: "JoinRideViewController") as? JoinRideViewController else { return }
            navigationController?.pushViewController(vc, animated: true)
        }
        return v
    }()

    private lazy var pastEmptyState: EmptyStateView = {
        let v = EmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: "No rides yet",
            body: "Rides you've taken or offered appear here after they complete.",
            actionTitle: "Clear Filters",
            tintColor: .systemGray
        )
        v.onAction = { [weak self] in
            self?.currentFilter = .all
            self?.updateFilterButtonAppearance()
            self?.applyFilter()
        }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = AppDesign.Color.groupedBackground
        tableView.backgroundColor = AppDesign.Color.groupedBackground
        setupTableView()
        setupRefreshControl()
        setupFilterButton()
        setupBellButton()
        setupLoadingOverlay()
        reloadTrips()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ridesDidUpdate),
            name: .ridesUpdated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationsDidUpdate),
            name: .appNotificationsUpdated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatDidUpdate),
            name: .chatMessagesUpdated,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        // Make nav bar blend with the view background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppDesign.Color.groupedBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        reloadTrips()
        refreshBellBadge()
        if let me = UserDataModel.shared.getCurrentUser() {
            Task { await AppNotificationModel.shared.refreshFromBackend(for: me.id) }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore default nav bar appearance
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = defaultAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = defaultAppearance
        navigationController?.navigationBar.compactAppearance = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateListOnFirstShow else { return }
        didAnimateListOnFirstShow = true
        tableView.layoutIfNeeded()
        tableView.animateVisibleCellsStaggered()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.register(UINib(nibName: "UpcomingTableViewCell", bundle: nil),
                           forCellReuseIdentifier: UpcomingTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "UpcomingPassengerTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "UpcomingPassengerTableViewCell")
        tableView.register(PastRideCell.self, forCellReuseIdentifier: PastRideCell.reuseIdentifier)
        tableView.register(SkeletonTableViewCell.self, forCellReuseIdentifier: SkeletonTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 260
        tableView.sectionHeaderTopPadding = 0
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.contentInset = UIEdgeInsets(top: AppDesign.Spacing.xs, left: 0, bottom: AppDesign.Spacing.lg, right: 0)
    }

    private func setupRefreshControl() {
        refreshControl.tintColor = AppDesign.Color.primary
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupFilterButton() {
        guard let btn = filterButton else { return }
        btn.layer.cornerRadius = AppDesign.Radius.md
        btn.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.1)
        btn.tintColor = AppDesign.Color.primary
        btn.setTitle(nil, for: .normal)
        btn.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        btn.layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        btn.layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        updateFilterButtonAppearance()
    }

    /// Updates the filter button icon and background to indicate whether a non-default filter is active.
    private func updateFilterButtonAppearance() {
        guard let btn = filterButton else { return }
        let isFiltered = currentFilter != .all
        UIView.animate(withDuration: 0.2) {
            btn.backgroundColor = isFiltered
                ? AppDesign.Color.primary.withAlphaComponent(0.2)
                : AppDesign.Color.primary.withAlphaComponent(0.1)
            btn.setImage(
                UIImage(systemName: isFiltered
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"),
                for: .normal
            )
        }
    }

    // MARK: - Pull-to-refresh

    @objc private func handleRefresh() {
        AppHaptics.selection()
        syncFromBackend {
            self.refreshControl.endRefreshing()
        }
    }

    func syncFromBackend(completion: (() -> Void)? = nil) {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            completion?()
            return
        }
        Task {
            await RideDataModel.shared.syncMyFullHistoryAsync(userID: user.id)
            await MainActor.run {
                self.reloadTrips()
                completion?()
            }
        }
    }

    // MARK: - Loading overlay

    private func showActionLoading() {
        loadingOverlay.isHidden = false
        view.bringSubviewToFront(loadingOverlay)
    }

    private func hideActionLoading() {
        loadingOverlay.isHidden = true
    }

    // MARK: - Data

    @objc private func ridesDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.reloadTrips()
        }
    }
    
    @objc private func chatDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func reloadTrips() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        upcomingTrips = RideDataModel.shared.myUpcoming(userID: user.id)
        pastTrips     = RideDataModel.shared.myPast(userID: user.id)
        rebuildPastSections()
        updateForSelectedSegment()
    }

    /// Groups pastTrips into sections by departure month ("Jan 2025"), sorted newest-first.
    private func rebuildPastSections() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var seen: [String: [RideDataModel.MyTrip]] = [:]
        var order: [String] = []
        for trip in pastTrips {
            let key = formatter.string(from: trip.ride.departureTime)
            if seen[key] == nil { order.append(key) }
            seen[key, default: []].append(trip)
        }
        pastSections = order
            .sorted { lhs, rhs in
                (formatter.date(from: lhs) ?? .distantPast) > (formatter.date(from: rhs) ?? .distantPast)
            }
            .map { (title: $0, trips: seen[$0]!) }
    }

    // MARK: - Segment & Filter

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        AppHaptics.selection()
        updateForSelectedSegment()
        UIView.animate(withDuration: 0.3) {
            self.filterButton?.isHidden = sender.selectedSegmentIndex == 0
        }
    }

    private func updateForSelectedSegment() {
        guard segmentedControl.selectedSegmentIndex < 2 else { return }
        if segmentedControl.selectedSegmentIndex == 0 {
            currentTrips = upcomingTrips
        } else {
            applyFilter()
        }
        tableView.reloadData()
        refreshEmptyState()
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Filter Rides", message: nil, preferredStyle: .actionSheet)

        func filterTitle(_ filter: RideFilter) -> String {
            switch filter {
            case .all:       return "All"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }

        for filter in [RideFilter.all, .completed, .cancelled] {
            let isSelected = currentFilter == filter
            let action = UIAlertAction(
                title: isSelected ? "✓ \(filterTitle(filter))" : filterTitle(filter),
                style: .default
            ) { [weak self] _ in
                guard let self, self.currentFilter != filter else { return }
                self.currentFilter = filter
                self.updateFilterButtonAppearance()
                self.applyFilter()
            }
            if isSelected { action.setValue(AppDesign.Color.primary, forKey: "titleTextColor") }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(alert, animated: true)
    }

    private func applyFilter() {
        switch currentFilter {
        case .all:       currentTrips = pastTrips
        case .completed: currentTrips = pastTrips.filter { $0.ride.status == .completed }
        case .cancelled: currentTrips = pastTrips.filter { $0.ride.status == .cancelled }
        }
        // Rebuild sections for the filtered set
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var seen: [String: [RideDataModel.MyTrip]] = [:]
        var order: [String] = []
        for trip in currentTrips {
            let key = formatter.string(from: trip.ride.departureTime)
            if seen[key] == nil { order.append(key) }
            seen[key, default: []].append(trip)
        }
        pastSections = order
            .sorted { lhs, rhs in
                (formatter.date(from: lhs) ?? .distantPast) > (formatter.date(from: rhs) ?? .distantPast)
            }
            .map { (title: $0, trips: seen[$0]!) }
        tableView.reloadData()
        refreshEmptyState()
    }

    // MARK: - Empty State

    private func refreshEmptyState() {
        let isEmpty = segmentedControl.selectedSegmentIndex == 0
            ? currentTrips.isEmpty
            : pastSections.isEmpty
        if isEmpty {
            tableView.backgroundView = segmentedControl.selectedSegmentIndex == 0
                ? upcomingEmptyState
                : pastEmptyState
        } else {
            tableView.backgroundView = nil
        }
        tableView.isScrollEnabled = !isEmpty
    }
}

// MARK: - TableView

extension MyRidesViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: Sections (past rides grouped by month)

    func numberOfSections(in tableView: UITableView) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 { return 1 }
        return max(pastSections.count, 1)   // at least 1 so the empty state background shows
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 { return currentTrips.count }
        guard section < pastSections.count else { return 0 }
        return pastSections[section].trips.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard segmentedControl.selectedSegmentIndex == 1, section < pastSections.count else { return nil }
        let container = UIView()
        container.backgroundColor = .clear
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = pastSections[section].title
        label.font = AppDesign.Typography.captionStrong
        label.textColor = .secondaryLabel
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppDesign.Spacing.md),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppDesign.Spacing.md),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard segmentedControl.selectedSegmentIndex == 1, section < pastSections.count else { return 0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trip: RideDataModel.MyTrip
        if segmentedControl.selectedSegmentIndex == 0 {
            guard indexPath.row < currentTrips.count else {
                return tableView.dequeueReusableCell(
                    withIdentifier: SkeletonTableViewCell.reuseIdentifier, for: indexPath)
            }
            trip = currentTrips[indexPath.row]
        } else {
            guard indexPath.section < pastSections.count,
                  indexPath.row < pastSections[indexPath.section].trips.count else {
                return tableView.dequeueReusableCell(
                    withIdentifier: SkeletonTableViewCell.reuseIdentifier, for: indexPath)
            }
            trip = pastSections[indexPath.section].trips[indexPath.row]
        }

        if segmentedControl.selectedSegmentIndex == 0 {
            switch trip.role {
            case .hosting:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: UpcomingTableViewCell.reuseIdentifier, for: indexPath
                ) as! UpcomingTableViewCell
                cell.configure(with: trip)
                cell.delegate = self
                return cell

            case .passenger:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "UpcomingPassengerTableViewCell", for: indexPath
                ) as! UpcomingPassengerTableViewCell
                cell.configure(with: trip)
                cell.delegate = self
                cell.cancelRequestButton.tag = indexPath.row
                cell.cancelRequestButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.cancelRequestButton.addTarget(self, action: #selector(cancelPassengerRequest(_:)), for: .touchUpInside)
                cell.messageButton.tag = indexPath.row
                cell.messageButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.messageButton.addTarget(self, action: #selector(passengerChatTapped(_:)), for: .touchUpInside)
                return cell
            }
        }

        // Past rides
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PastRideCell.reuseIdentifier, for: indexPath
        ) as! PastRideCell
        cell.configure(with: trip)
        cell.delegate = self
        cell.onRateTapped = { [weak self] tripToRate in
            self?.presentRatingSheet(for: tripToRate)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip: RideDataModel.MyTrip
        if segmentedControl.selectedSegmentIndex == 0 {
            guard indexPath.row < currentTrips.count else { return }
            trip = currentTrips[indexPath.row]
        } else {
            guard indexPath.section < pastSections.count,
                  indexPath.row < pastSections[indexPath.section].trips.count else { return }
            trip = pastSections[indexPath.section].trips[indexPath.row]
        }

        if trip.role == .hosting {
            let confirmedCount = RideDataModel.shared
                .listBookings(for: trip.ride.id)
                .filter { $0.status == .confirmed }
                .reduce(0) { $0 + $1.seats }
            
            if confirmedCount == 0 {
                let alert = UIAlertController(
                    title: "No passengers yet",
                    message: "Share your ride to get requests. Approved passengers will appear here.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Got It", style: .default))
                present(alert, animated: true)
                return
            }
            
            let vc = RideDetailViewController()
            vc.ride = trip.ride
            vc.driver = trip.ride.driverProfile ?? UserDataModel.shared.getUser(by: trip.ride.driverUserID)
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(vc, animated: true)
        } else {
            // Passenger: show driver details by default on card tap
            if let driver = trip.ride.driverProfile ?? UserDataModel.shared.getUser(by: trip.ride.driverUserID) {
                let vc = DriverDetailViewController()
                vc.driver = driver
                vc.ride = trip.ride
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 24
                }
                present(vc, animated: true)
            }
        }
    }


}

// MARK: - Host Cell Delegate

extension MyRidesViewController: UpcomingTableViewCellDelegate {

    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func upcomingCellDidTapViewRequests(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row, index < currentTrips.count else { return }
        let trip = currentTrips[index]
        let sb = UIStoryboard(name: "DriverRequests", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "DriverRequestsViewController") as? DriverRequestsViewController else { return }
        vc.trip = trip
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(nav, animated: true)
    }

    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row, index < currentTrips.count else { return }
        let trip = currentTrips[index]
        let ride  = trip.ride
        let from  = ride.source.address ?? "From"
        let to    = ride.destination.address ?? "To"
        let title = "\(from) → \(to)"

        let approvedBookings = RideDataModel.shared.listBookings(for: ride.id)
        let passengerProfiles: [UserProfile] = approvedBookings.compactMap {
            UserDataModel.shared.getUser(by: $0.passengerUserID)
        }
        if let driverProfile = UserDataModel.shared.getUser(by: ride.driverUserID) {
            ChatDataModel.shared.seedWelcomeIfNeeded(ride: ride, driverName: driverProfile.fullName)
        }
        let vm = ChatViewModel(rideID: ride.id.uuidString, rideTitle: title, participants: passengerProfiles)
        openChatSheet(vm)
    }

    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell) {
        // Future: initiate call
    }

    func openChatSheet(_ vm: ChatViewModel) {
        let host = UIHostingController(rootView: GroupChatView(viewModel: vm))
        host.modalPresentationStyle = .pageSheet
        if let sheet = host.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(host, animated: true)
    }

    // MARK: - Rating Sheet

    func presentRatingSheet(for trip: RideDataModel.MyTrip) {
        guard let myID = UserDataModel.shared.getCurrentUser()?.id else { return }
        let ride = trip.ride
        var toRate: [(UUID, String, URL?)] = []
        if trip.role == .hosting {
            let bookings = RideDataModel.shared.listBookings(for: ride.id).filter { $0.status == .confirmed }
            for b in bookings {
                guard !ReviewDataModel.shared.hasReviewed(rideID: ride.id,
                                                          reviewerID: myID,
                                                          revieweeID: b.passengerUserID) else { continue }
                let p = UserDataModel.shared.getUser(by: b.passengerUserID)
                toRate.append((b.passengerUserID, p?.fullName ?? "Passenger", p?.photoURL))
            }
        } else {
            if !ReviewDataModel.shared.hasReviewed(rideID: ride.id,
                                                   reviewerID: myID,
                                                   revieweeID: ride.driverUserID) {
                let d = UserDataModel.shared.getUser(by: ride.driverUserID)
                toRate.append((ride.driverUserID, d?.fullName ?? "Driver", d?.photoURL))
            }
        }
        guard !toRate.isEmpty else { return }
        presentNextRating(rideID: ride.id, queue: toRate)
    }

    private func presentNextRating(rideID: UUID, queue: [(UUID, String, URL?)]) {
        guard let first = queue.first else {
            reloadTrips()
            return
        }
        let remaining = Array(queue.dropFirst())
        let sb = UIStoryboard(name: "RateRide", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "RateRideViewController") as? RateRideViewController else { return }
        vc.rideID = rideID
        vc.revieweeID = first.0
        vc.revieweeName = first.1
        vc.revieweePhotoURL = first.2
        vc.onSubmitted = { [weak self] in
            self?.presentNextRating(rideID: rideID, queue: remaining)
        }
        present(vc, animated: true)
    }

    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let rideID = currentTrips[index].ride.id

        // Ask for cancellation reason before cancelling
        let reasons = ["Plans changed", "Vehicle issue", "Emergency", "Found alternative", "Other"]
        let sheet = UIAlertController(title: "Why are you cancelling?",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        for reason in reasons {
            sheet.addAction(UIAlertAction(title: reason, style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showActionLoading()
                Task { @MainActor in
                    defer { self.hideActionLoading() }
                    do {
                        _ = try await RideDataModel.shared.cancelRideAsync(id: rideID)
                        self.reloadTrips()
                    } catch {
                        let alert = UIAlertController(
                            title: "Cancellation Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            })
        }
        sheet.addAction(UIAlertAction(title: "Keep Ride", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(sheet, animated: true)
    }

    func upcomingCellDidTapStartTrip(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let rideID = currentTrips[index].ride.id
        let alert = UIAlertController(
            title: "Start Ride?",
            message: "Your passengers will be notified that the ride has started.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Start Ride", style: .default) { [weak self] _ in
            self?.showActionLoading()
            Task { @MainActor in
                defer { self?.hideActionLoading() }
                do {
                    _ = try await RideDataModel.shared.startRideAsync(id: rideID)
                    self?.reloadTrips()
                } catch {
                    let alert = UIAlertController(
                        title: "Couldn't Start Ride",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    func upcomingCellDidTapEndTrip(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let rideID = currentTrips[index].ride.id
        let alert = UIAlertController(
            title: "End Ride?",
            message: "This completes the ride. It'll appear in your ride history.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End Ride", style: .destructive) { [weak self] _ in
            self?.showActionLoading()
            Task { @MainActor in
                defer { self?.hideActionLoading() }
                do {
                    _ = try await RideDataModel.shared.endRideAsync(id: rideID)
                    self?.reloadTrips()
                } catch {
                    let alert = UIAlertController(
                        title: "Couldn't End Ride",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    func upcomingCellDidTapPassenger(_ cell: UpcomingTableViewCell, passenger: UserProfile, ride: Ride) {
        let vc = PassengerDetailViewController()
        vc.passenger = passenger
        vc.ride = ride
        vc.onRemovePassenger = { [weak self] in self?.reloadTrips() }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
}

// MARK: - UpcomingPassengerCellDelegate
extension MyRidesViewController: UpcomingPassengerCellDelegate {
    func passengerCellDidTapDriver(
        _ cell: UpcomingPassengerTableViewCell,
        driver: UserProfile,
        ride: Ride
    ) {
        let vc = DriverDetailViewController()
        vc.driver = driver
        vc.ride = ride
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
}

// MARK: - PastRideCellDelegate
extension MyRidesViewController: PastRideCellDelegate {
    func pastRideCellDidTapPerson(_ cell: PastRideCell, user: UserProfile) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let trip: RideDataModel.MyTrip
        if segmentedControl.selectedSegmentIndex == 0 {
            trip = currentTrips[indexPath.row]
        } else {
            trip = pastSections[indexPath.section].trips[indexPath.row]
        }

        if trip.role == .hosting {
            // Tapped a passenger
            let vc = PassengerDetailViewController()
            vc.passenger = user
            vc.ride = trip.ride
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(vc, animated: true)
        } else {
            // Tapped the driver
            let vc = DriverDetailViewController()
            vc.driver = user
            vc.ride = trip.ride
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(vc, animated: true)
        }
    }
}

// MARK: - Passenger Actions

extension MyRidesViewController {

    @objc private func passengerChatTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        let ride = trip.ride
        let from  = ride.source.address ?? "From"
        let to    = ride.destination.address ?? "To"
        let title = "\(from) → \(to)"

        if let driver = UserDataModel.shared.getUser(by: ride.driverUserID) {
            ChatDataModel.shared.seedWelcomeIfNeeded(ride: ride, driverName: driver.fullName)
        }

        var participants: [UserProfile] = []
        if let driver = UserDataModel.shared.getUser(by: ride.driverUserID) { participants.append(driver) }
        let bookings = RideDataModel.shared.listBookings(for: ride.id)
        let meID = UserDataModel.shared.getCurrentUser()?.id
        let others = bookings.compactMap { UserDataModel.shared.getUser(by: $0.passengerUserID) }
            .filter { $0.id != meID }
        participants += others

        let vm = ChatViewModel(rideID: ride.id.uuidString, rideTitle: title, participants: participants)
        openChatSheet(vm)
    }

    @objc private func cancelPassengerRequest(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        guard trip.role == .passenger, let me = UserDataModel.shared.getCurrentUser() else { return }

        let isConfirmed = trip.requestStatus == .approved
        let alertTitle = isConfirmed ? "Cancel Booking" : "Cancel Request"
        let msg: String
        if isConfirmed {
            let from = trip.ride.source.address ?? "Origin"
            let to   = trip.ride.destination.address ?? "Destination"
            msg = "Cancel your ride from \(from) to \(to)? The driver will be notified and your seat will open up for others."
        } else {
            msg = "Cancel this booking? You can always find another ride."
        }

        let alert = UIAlertController(title: alertTitle, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        alert.addAction(UIAlertAction(title: alertTitle, style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.showActionLoading()
            Task { @MainActor in
                defer { self.hideActionLoading() }
                do {
                    if isConfirmed {
                        let bookings = RideDataModel.shared.listBookings(for: trip.ride.id)
                        if let booking = bookings.first(where: { $0.passengerUserID == me.id && $0.status == .confirmed }) {
                            try await RideDataModel.shared.cancelBookingAsync(bookingID: booking.id, by: me.id)
                        }
                    } else if let requestID = trip.requestID {
                        try await RideDataModel.shared.cancelMyRequestAsync(requestID: requestID, passengerUserID: me.id)
                    }
                    self.reloadTrips()
                } catch {
                    let fail = UIAlertController(
                        title: "Cancellation Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    fail.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(fail, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Notification Bell

    private func setupBellButton() {
        bellBtn.translatesAutoresizingMaskIntoConstraints = false
        bellBtn.setImage(UIImage(systemName: "bell"), for: .normal)
        bellBtn.tintColor = .label
        bellBtn.addTarget(self, action: #selector(bellTapped), for: .touchUpInside)

        bellBadge.font = AppDesign.Typography.captionStrong.withSize(9)
        bellBadge.textColor = .white
        bellBadge.backgroundColor = AppDesign.Color.destructive
        bellBadge.textAlignment = .center
        bellBadge.layer.cornerRadius = 7
        bellBadge.layer.masksToBounds = true
        bellBadge.isHidden = true
        bellBadge.translatesAutoresizingMaskIntoConstraints = false
        bellBtn.addSubview(bellBadge)
        NSLayoutConstraint.activate([
            bellBadge.topAnchor.constraint(equalTo: bellBtn.topAnchor, constant: -2),
            bellBadge.trailingAnchor.constraint(equalTo: bellBtn.trailingAnchor, constant: 2),
            bellBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 14),
            bellBadge.heightAnchor.constraint(equalToConstant: 14),
        ])

        if navigationController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: bellBtn)
        } else {
            view.addSubview(bellBtn)
            bellTopConstraint = bellBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
            NSLayoutConstraint.activate([
                bellTopConstraint!,
                bellBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                bellBtn.widthAnchor.constraint(equalToConstant: 32),
                bellBtn.heightAnchor.constraint(equalToConstant: 32),
            ])
        }
        refreshBellBadge()
    }

    func refreshBellBadge() {
        guard let me = UserDataModel.shared.getCurrentUser() else { return }
        let count = AppNotificationModel.shared.unreadCount(for: me.id)
        bellBadge.isHidden = count == 0
        bellBadge.text = count > 9 ? "9+" : "\(count)"
        bellBtn.setImage(UIImage(systemName: count > 0 ? "bell.badge" : "bell"), for: .normal)
        bellBtn.tintColor = count > 0 ? AppDesign.Color.destructive : .label
    }

    @objc private func notificationsDidUpdate() {
        DispatchQueue.main.async { self.refreshBellBadge() }
    }

    @objc private func bellTapped() {
        guard let me = UserDataModel.shared.getCurrentUser() else { return }
        Task { [weak self] in
            await AppNotificationModel.shared.refreshFromBackend(for: me.id)
            await MainActor.run {
                guard let self else { return }
                let notifs = AppNotificationModel.shared.all(for: me.id)
                AppNotificationModel.shared.markAllRead(for: me.id)
                self.refreshBellBadge()

                if notifs.isEmpty {
                    let a = UIAlertController(title: "You're all caught up",
                                              message: "No new notifications right now.",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "Got It", style: .default))
                    self.present(a, animated: true)
                    return
                }

                let sb = UIStoryboard(name: "NotificationInbox", bundle: nil)
                guard let vc = sb.instantiateViewController(withIdentifier: "NotificationInboxViewController") as? NotificationInboxViewController else { return }
                vc.notifications = notifs
                vc.modalPresentationStyle = .pageSheet
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 24
                }
                self.present(vc, animated: true)
            }
        }
    }
}

// MARK: - SkeletonTableViewCell
/// Simple shimmer-style placeholder cell used while rides are loading.
final class SkeletonTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SkeletonTableViewCell"

    private let shimmerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        shimmerView.backgroundColor = .systemGray5
        shimmerView.layer.cornerRadius = AppDesign.Radius.md
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerView)

        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            shimmerView.heightAnchor.constraint(equalToConstant: 110),
        ])

        startPulse()
    }

    private func startPulse() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue   = 0.4
        pulse.duration  = 0.9
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        shimmerView.layer.add(pulse, forKey: "pulse")
    }
}
