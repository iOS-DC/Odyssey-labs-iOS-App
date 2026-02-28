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
    private var didAnimateListOnFirstShow = false

    // Notification bell
    private let bellBtn   = UIButton(type: .system)
    private let bellBadge = UILabel()

    // Empty states
    private lazy var upcomingEmptyState: EmptyStateView = {
        let v = EmptyStateView(
            systemImage: "car.2.fill",
            title: "No upcoming rides",
            body: "Rides you've offered or joined will appear here once approved.",
            tintColor: AppDesign.Color.primary
        )
        return v
    }()

    private lazy var pastEmptyState: EmptyStateView = {
        let v = EmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: "No past rides yet",
            body: "Completed and cancelled rides will show up here.",
            actionTitle: "Clear filter",
            tintColor: .systemGray
        )
        v.onAction = { [weak self] in
            self?.currentFilter = .all
            self?.applyFilter()
        }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFilterButton()
        setupBellButton()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTrips()
        refreshBellBadge()
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

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 260
        tableView.sectionHeaderTopPadding = 0
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.contentInset = UIEdgeInsets(top: AppDesign.Spacing.xs, left: 0, bottom: AppDesign.Spacing.lg, right: 0)
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
    }

    // MARK: - Data

    @objc private func ridesDidUpdate() {
        reloadTrips()
    }

    private func reloadTrips() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        upcomingTrips = RideDataModel.shared.myUpcoming(userID: user.id)
        pastTrips = RideDataModel.shared.myPast(userID: user.id)
        updateForSelectedSegment()
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
        let alert = UIAlertController(title: "Filter Rides", message: "Select filter option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All", style: .default) { [weak self] _ in
            self?.currentFilter = .all; self?.applyFilter()
        })
        alert.addAction(UIAlertAction(title: "Completed", style: .default) { [weak self] _ in
            self?.currentFilter = .completed; self?.applyFilter()
        })
        alert.addAction(UIAlertAction(title: "Cancelled", style: .default) { [weak self] _ in
            self?.currentFilter = .cancelled; self?.applyFilter()
        })
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
        tableView.reloadData()
        refreshEmptyState()
    }

    // MARK: - Empty State

    private func refreshEmptyState() {
        let isEmpty = currentTrips.isEmpty
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentTrips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trip = currentTrips[indexPath.row]

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
                // Cancel button
                cell.cancelRequestButton.tag = indexPath.row
                cell.cancelRequestButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.cancelRequestButton.addTarget(self, action: #selector(cancelPassengerRequest(_:)), for: .touchUpInside)
                // Message button → opens SAME group chat as the driver
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
        cell.onRateTapped = { [weak self] tripToRate in
            self?.presentRatingSheet(for: tripToRate)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: 0, dy: 6)
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
        let vc = DriverRequestsViewController(trip: trip)
        
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

        // Collect confirmed passenger profiles for this ride
        let approvedBookings = RideDataModel.shared.listBookings(for: ride.id)
        let passengerProfiles: [UserProfile] = approvedBookings.compactMap {
            UserDataModel.shared.getUser(by: $0.passengerUserID)
        }

        // Seed the driver's welcome message the first time this chat is opened
        if let driverProfile = UserDataModel.shared.getUser(by: ride.driverUserID) {
            ChatDataModel.shared.seedWelcomeIfNeeded(ride: ride, driverName: driverProfile.fullName)
        }

        let vm = ChatViewModel(rideID: ride.id.uuidString, rideTitle: title, participants: passengerProfiles)
        openChatSheet(vm)
    }

    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell) {
        // Future: initiate call
    }

    // Helper shared by host + passenger chat buttons
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

    /// Presents RateRideViewController for each unrated person, chained sequentially.
    func presentRatingSheet(for trip: RideDataModel.MyTrip) {
        guard let myID = UserDataModel.shared.getCurrentUser()?.id else { return }
        let ride = trip.ride

        // Build list of (id, name, photo) for everyone still needing a rating
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
            reloadTrips()   // refresh after all ratings done (removes rate button)
            return
        }
        let remaining = Array(queue.dropFirst())
        let vc = RateRideViewController(
            rideID: rideID,
            revieweeID: first.0,
            name: first.1,
            photoURL: first.2
        )
        vc.onSubmitted = { [weak self] in
            self?.presentNextRating(rideID: rideID, queue: remaining)
        }
        present(vc, animated: true)
    }

    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        RideDataModel.shared.cancelRide(id: currentTrips[index].ride.id)
        reloadTrips()
    }

    func upcomingCellDidTapStartTrip(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let rideID = currentTrips[index].ride.id

        let alert = UIAlertController(
            title: "Start Trip?",
            message: "This will mark the ride as ongoing. Passengers will be notified.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Start Trip", style: .default) { [weak self] _ in
            RideDataModel.shared.startRide(id: rideID)
            self?.reloadTrips()
        })
        present(alert, animated: true)
    }

    func upcomingCellDidTapEndTrip(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let rideID = currentTrips[index].ride.id

        let alert = UIAlertController(
            title: "End Trip?",
            message: "This will mark the ride as completed. It will move to your past rides.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End Trip", style: .destructive) { [weak self] _ in
            RideDataModel.shared.endRide(id: rideID)
            self?.reloadTrips()
        })
        present(alert, animated: true)
    }

    func upcomingCellDidTapPassenger(_ cell: UpcomingTableViewCell, passenger: UserProfile, ride: Ride) {
        let vc = PassengerDetailViewController(passenger: passenger, ride: ride)
        vc.onRemovePassenger = { [weak self] in self?.reloadTrips() }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
}

// MARK: - Passenger Actions

extension MyRidesViewController {

    /// Opens the shared group chat for the ride (same room the driver sees)
    @objc private func passengerChatTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }
        let trip = currentTrips[index]
        let ride = trip.ride
        let from  = ride.source.address ?? "From"
        let to    = ride.destination.address ?? "To"
        let title = "\(from) → \(to)"

        // Seed welcome from driver if not yet done
        if let driver = UserDataModel.shared.getUser(by: ride.driverUserID) {
            ChatDataModel.shared.seedWelcomeIfNeeded(ride: ride, driverName: driver.fullName)
        }

        // Participants = driver + everyone else in the booking list except current user
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
        let title = isConfirmed ? "Cancel Booking" : "Cancel Request"

        // Enhanced message for confirmed bookings — explicitly warn driver will be notified
        let msg: String
        if isConfirmed {
            let from = trip.ride.source.address ?? "Origin"
            let to   = trip.ride.destination.address ?? "Destination"
            msg = "Cancel your confirmed booking for \(from) → \(to)?\n\nThe driver will be notified and your seat will be freed automatically."
        } else {
            msg = "Are you sure you want to cancel this ride request?"
        }

        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        alert.addAction(UIAlertAction(title: title, style: .destructive) { [weak self] _ in
            guard let self else { return }
            if isConfirmed {
                let bookings = RideDataModel.shared.listBookings(for: trip.ride.id)
                if let booking = bookings.first(where: { $0.passengerUserID == me.id && $0.status == .confirmed }) {
                    RideDataModel.shared.cancelBooking(bookingID: booking.id, by: me.id)
                }
            } else if let requestID = trip.requestID {
                RideDataModel.shared.cancelMyRequest(requestID: requestID, passengerUserID: me.id)
            }
            self.reloadTrips()
        })
        present(alert, animated: true)
    }

    // MARK: - Notification Bell

    private func setupBellButton() {
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: bellBtn)
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
        let notifs = AppNotificationModel.shared.notifications
            .filter { $0.recipientUserID == me.id }

        AppNotificationModel.shared.markAllRead(for: me.id)
        refreshBellBadge()

        if notifs.isEmpty {
            let a = UIAlertController(title: "No Notifications",
                                      message: "You're all caught up! ✅",
                                      preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        let vc = NotificationInboxViewController(notifications: notifs)
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
}
