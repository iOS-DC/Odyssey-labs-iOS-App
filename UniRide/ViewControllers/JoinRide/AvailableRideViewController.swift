import UIKit
import MapKit

final class AvailableRideViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: - Inputs (from JoinRideViewController or EventDetailsViewController)
    var fromCoordinate: CLLocationCoordinate2D?
    var toCoordinate: CLLocationCoordinate2D?
    var fromAddress: String?
    var toAddress: String?
    var date: Date?
    var time: Date?
    var event: EventItem?

    // MARK: - Data
    private var rides: [Ride] = []          // raw, unfiltered
    private var filteredRides: [Ride] = []  // drives tableView

    private var activeFilter = RideFilter()
    private var searchQuery  = ""
    private var didAnimateListOnFirstShow = false
    private var blockedUserIDs: Set<UUID> = []

    // MARK: - UI
    private let searchController  = UISearchController(searchResultsController: nil)
    private let resultCountLabel  = UILabel()
    private let routeSummaryView  = UIView()
    private let emptyStateView    = UIView()
    private var filterBarBtn: UIBarButtonItem!
    private lazy var offlineView: OfflineEmptyStateView = {
        let v = OfflineEmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        v.retryButton.addTarget(self, action: #selector(retryConnection), for: .touchUpInside)
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event != nil ? "Rides to \(event!.title)" : "Available Rides"
        setupSearchController()
        setupFilterButton()
        setupRouteSummary()
        setupResultCountLabel()
        setupEmptyState()
        setupTableView()
        setupOfflineView()
        _ = NetworkMonitor.shared  // ensure monitor started
        NotificationCenter.default.addObserver(
            self, selector: #selector(connectivityChanged(_:)),
            name: .connectivityChanged, object: nil
        )
        loadAvailableRides()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateListOnFirstShow else { return }
        didAnimateListOnFirstShow = true
        tableView.layoutIfNeeded()
        tableView.animateVisibleCellsStaggered()
    }

    // MARK: - Offline state

    private func setupOfflineView() {
        view.addSubview(offlineView)
        NSLayoutConstraint.activate([
            offlineView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            offlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func connectivityChanged(_ note: Notification) {
        let isConnected = (note.userInfo?["isConnected"] as? Bool) ?? true
        offlineView.isHidden = isConnected
        tableView.isHidden   = !isConnected
        if isConnected { loadAvailableRides() }
    }

    @objc private func retryConnection() {
        if NetworkMonitor.shared.isConnected {
            offlineView.isHidden = true
            tableView.isHidden   = false
            loadAvailableRides()
        }
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "RideTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "RideTableViewCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = 220
        tableView.contentInset = UIEdgeInsets(top: AppDesign.Spacing.xxs, left: 0, bottom: AppDesign.Spacing.lg, right: 0)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by pickup or destination…"
        searchController.searchBar.tintColor = AppDesign.Color.primary
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupFilterButton() {
        let img = UIImage(systemName: "slider.horizontal.3")
        filterBarBtn = UIBarButtonItem(image: img,
                                       style: .plain,
                                       target: self,
                                       action: #selector(filterTapped))
        filterBarBtn.tintColor = .label
        navigationItem.rightBarButtonItem = filterBarBtn
    }

    private func setupResultCountLabel() {
        resultCountLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        resultCountLabel.textAlignment = .left
        resultCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultCountLabel)
        
        // Find and deactivate storyboard constraint: tableView.top = titleLabel.bottom + constant
        view.constraints.forEach { c in
            if (c.firstItem === tableView && c.secondItem === titleLabel && c.firstAttribute == .top) ||
               (c.firstItem === titleLabel && c.secondItem === tableView && c.secondAttribute == .top) {
                c.isActive = false
            }
        }

        NSLayoutConstraint.activate([
            resultCountLabel.topAnchor.constraint(equalTo: routeSummaryView.bottomAnchor, constant: AppDesign.Spacing.xs),
            resultCountLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            resultCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            tableView.topAnchor.constraint(equalTo: resultCountLabel.bottomAnchor, constant: 12)
        ])
        
        // Remove the top contentInset we added before as we're using real constraints now
        tableView.contentInset.top = 0
    }

    private func setupRouteSummary() {
        routeSummaryView.translatesAutoresizingMaskIntoConstraints = false
        routeSummaryView.applyCardStyle(corner: AppDesign.Radius.md,
                                        shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                                        shadowRadius: AppDesign.Shadow.smallCardRadius)
        view.addSubview(routeSummaryView)

        let fromLabel = makeRouteSummaryLabel(
            icon: "circle.fill",
            tint: AppDesign.Color.success,
            text: fromAddress?.nilIfBlank ?? event?.location?.name ?? "Selected pickup"
        )
        let toLabel = makeRouteSummaryLabel(
            icon: "mappin.circle.fill",
            tint: AppDesign.Color.destructive,
            text: toAddress?.nilIfBlank ?? event?.location?.name ?? "Selected drop-off"
        )
        let divider = UIView()
        divider.backgroundColor = AppDesign.Color.divider
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let stack: UIStackView = UIStackView(arrangedSubviews: [fromLabel, divider, toLabel])
        stack.axis = .vertical
        stack.spacing = AppDesign.Spacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false
        routeSummaryView.addSubview(stack)

        NSLayoutConstraint.activate([
            routeSummaryView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppDesign.Spacing.sm),
            routeSummaryView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            routeSummaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.md),

            stack.topAnchor.constraint(equalTo: routeSummaryView.topAnchor, constant: AppDesign.Spacing.sm),
            stack.leadingAnchor.constraint(equalTo: routeSummaryView.leadingAnchor, constant: AppDesign.Spacing.sm),
            stack.trailingAnchor.constraint(equalTo: routeSummaryView.trailingAnchor, constant: -AppDesign.Spacing.sm),
            stack.bottomAnchor.constraint(equalTo: routeSummaryView.bottomAnchor, constant: -AppDesign.Spacing.sm)
        ])
    }

    private func makeRouteSummaryLabel(icon: String, tint: UIColor, text: String) -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = tint
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: AppDesign.Size.iconSm),
            imageView.heightAnchor.constraint(equalToConstant: AppDesign.Size.iconSm)
        ])

        let label = UILabel()
        label.text = text
        label.applyTextStyle(AppDesign.Typography.captionStrong, color: AppDesign.Color.textPrimary, lines: 1)

        let row = UIStackView(arrangedSubviews: [imageView, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = AppDesign.Spacing.xs
        return row
    }

    private func setupEmptyState() {
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = AppDesign.Color.textTertiary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "No rides on this route"
        titleLbl.applyTextStyle(AppDesign.Typography.bodyStrong, color: .secondaryLabel)
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let bodyLbl = UILabel()
        bodyLbl.text = "Try a nearby date or widen your search — or offer this ride yourself."
        bodyLbl.applyTextStyle(AppDesign.Typography.subheadline, color: .tertiaryLabel, lines: 0)
        bodyLbl.textAlignment = .center
        bodyLbl.translatesAutoresizingMaskIntoConstraints = false

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Clear Filters", for: .normal)
        clearBtn.applyTextActionStyle()
        clearBtn.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false

        let offerBtn = UIButton(type: .system)
        offerBtn.setTitle("Offer This Route", for: .normal)
        offerBtn.applyTextActionStyle()
        offerBtn.addTarget(self, action: #selector(offerThisRoute), for: .touchUpInside)
        offerBtn.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLbl, bodyLbl, clearBtn, offerBtn])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = AppDesign.Spacing.sm
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.xl),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.xl),

            iconView.heightAnchor.constraint(equalToConstant: 60),
            iconView.widthAnchor.constraint(equalToConstant: 60),

            stack.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
        ])
    }

    // MARK: - Load Rides

    private func loadAvailableRides() {
        // Show a spinner while we wait for Supabase
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        Task { @MainActor [weak self] in
            guard let self else { return }

            // Fetch all published rides from Supabase and merge into local model.
            // This ensures rides posted on other devices appear in this list.
            if let remote = try? await RideRepository.shared.fetchPublishedRides(), !remote.isEmpty {
                RideDataModel.shared.mergeRemoteRides(remote)
            }

            self.blockedUserIDs = await SafetyService.shared.fetchBlockedUserIDs()

            spinner.removeFromSuperview()

            // Event-filtered rides (shown from EventDetails screen)
            if let event = self.event {
                self.rides = MockData.mockRidesForEvent(event)
                self.applyFilters()
                return
            }

            // Location-filtered rides
            guard let fromCoord = self.fromCoordinate else {
                self.rides = []
                self.applyFilters()
                return
            }
            let fromPoint = LocationPoint(lat: fromCoord.latitude, lon: fromCoord.longitude, address: nil)
            self.rides = RideDataModel.shared.ridesNear(fromPoint, maxMeters: 1500)
            self.applyFilters()
        }
    }

    // MARK: - Filter Logic

    private func applyFilters() {
        var result = activeFilter.apply(to: rides)
        
        // FILTER: Exclude rides from blocked users
        result = result.filter { !blockedUserIDs.contains($0.driverUserID) }

        // FILTER: Exclude my own rides
        if let currentUID = UserDataModel.shared.getCurrentUser()?.id {
            result = result.filter { $0.driverUserID != currentUID }
        }

        // FILTER: Exclude full rides
        result = result.filter { $0.seatsAvailable > 0 }

        // Apply text search on top of filter
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            result = result.filter { ride in
                let src  = (ride.source.address ?? "").lowercased()
                let dst  = (ride.destination.address ?? "").lowercased()
                return src.contains(q) || dst.contains(q)
            }
        }

        filteredRides = result
        updateUI()
    }

    private func updateUI() {
        tableView.reloadData()

        // Result count label
        let currentUID = UserDataModel.shared.getCurrentUser()?.id
        let eligible  = rides.filter { ride in
            !blockedUserIDs.contains(ride.driverUserID) &&
            ride.driverUserID != currentUID &&
            ride.seatsAvailable > 0
        }
        let total    = eligible.count
        let showing  = filteredRides.count
        let filtered = !activeFilter.isDefault || !searchQuery.isEmpty

        if filtered {
            resultCountLabel.text = showing == 0 ? "No matches — try clearing your filters"
                                                 : "Showing \(showing) of \(total) ride\(total == 1 ? "" : "s")"
        } else {
            resultCountLabel.text = "\(total) ride\(total == 1 ? "" : "s") available"
        }

        // Empty state
        emptyStateView.isHidden = !filteredRides.isEmpty

        // Filter button — filled icon + primary tint when a filter is active
        let isActive = !activeFilter.isDefault
        filterBarBtn.tintColor = isActive ? AppDesign.Color.primary : .label
        filterBarBtn.image = UIImage(systemName: isActive
            ? "line.3.horizontal.decrease.circle.fill"
            : "slider.horizontal.3")
    }

    // MARK: - Actions

    @objc private func filterTapped() {
        AppHaptics.impact(.light)
        let sb = UIStoryboard(name: "RideFilter", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "RideFilterViewController") as? RideFilterViewController else { return }
        vc.currentFilter = activeFilter
        vc.onApply = { [weak self] newFilter in
            self?.activeFilter = newFilter
            self?.applyFilters()
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = AppDesign.Radius.lg
        }
        present(vc, animated: true)
    }

    @objc private func clearFilters() {
        AppHaptics.selection()
        activeFilter = RideFilter()
        searchQuery  = ""
        searchController.searchBar.text = nil
        applyFilters()
    }

    @objc private func offerThisRoute() {
        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "OfferRideViewController") as? OfferRideViewController else { return }
        if let fromCoordinate {
            vc.prefilledFrom = LocationPoint(
                lat: fromCoordinate.latitude,
                lon: fromCoordinate.longitude,
                address: fromAddress
            )
        }
        if let toCoordinate {
            vc.prefilledTo = LocationPoint(
                lat: toCoordinate.latitude,
                lon: toCoordinate.longitude,
                address: toAddress
            )
        }
        vc.prefilledDate = date
        vc.prefilledTime = time
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        searchQuery = searchController.searchBar.text ?? ""
        applyFilters()
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - TableView

extension AvailableRideViewController {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredRides.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "RideTableViewCell", for: indexPath) as? RideTableViewCell
        else { return UITableViewCell() }

        let ride   = filteredRides[indexPath.row]
        let driver = ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)
        cell.configure(with: ride, driver: driver)
        cell.onJoinTapped = { [weak self] in
            self?.openDetail(ride: ride, driver: driver)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let inset: CGFloat = 12
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: 0, dy: inset / 2)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < filteredRides.count else { return }
        let ride = filteredRides[indexPath.row]
        let driver = ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)
        openDetail(ride: ride, driver: driver)
    }

    private func openDetail(ride: Ride, driver: UserProfile?) {
        ensureNonGuest { [weak self] in
            let sb = UIStoryboard(name: "RideDetail", bundle: nil)
            guard let vc = sb.instantiateViewController(withIdentifier: "RideDetailViewController") as? RideDetailViewController else { return }
            vc.ride = ride
            vc.driver = driver
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
