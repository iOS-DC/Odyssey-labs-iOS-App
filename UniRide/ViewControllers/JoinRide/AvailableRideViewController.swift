import UIKit
import MapKit

final class AvailableRideViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Inputs (from JoinRideViewController or EventDetailsViewController)
    var fromCoordinate: CLLocationCoordinate2D?
    var toCoordinate: CLLocationCoordinate2D?
    var date: Date?
    var time: Date?
    var event: EventItem?

    // MARK: - Data
    private var rides: [Ride] = []          // raw, unfiltered
    private var filteredRides: [Ride] = []  // drives tableView

    private var activeFilter = RideFilter()
    private var searchQuery  = ""

    // MARK: - UI
    private let searchController  = UISearchController(searchResultsController: nil)
    private let resultCountLabel  = UILabel()
    private let emptyStateView    = UIView()
    private var filterBarBtn: UIBarButtonItem!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event != nil ? "Rides to \(event!.title)" : "Available Rides"
        setupSearchController()
        setupFilterButton()
        setupResultCountLabel()
        setupEmptyState()
        setupTableView()
        loadAvailableRides()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "RideTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "RideTableViewCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = 220
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 20, right: 0)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by pickup or destination…"
        searchController.searchBar.tintColor = .systemGreen
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
        resultCountLabel.font = .systemFont(ofSize: 13, weight: .medium)
        resultCountLabel.textColor = .secondaryLabel
        resultCountLabel.textAlignment = .center
        resultCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultCountLabel)
        NSLayoutConstraint.activate([
            resultCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            resultCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        if let tv = tableView {
            tv.contentInset.top = 28
        }
    }

    private func setupEmptyState() {
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = .systemGray3
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "No rides found"
        titleLbl.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLbl.textColor = .secondaryLabel
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let bodyLbl = UILabel()
        bodyLbl.text = "Try adjusting your filters\nor search for a different route."
        bodyLbl.font = .systemFont(ofSize: 14)
        bodyLbl.textColor = .tertiaryLabel
        bodyLbl.textAlignment = .center
        bodyLbl.numberOfLines = 0
        bodyLbl.translatesAutoresizingMaskIntoConstraints = false

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Clear Filters", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        clearBtn.tintColor = .systemGreen
        clearBtn.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLbl, bodyLbl, clearBtn])
        stack.axis = .vertical; stack.alignment = .center; stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

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
        if let event = event {
            rides = MockData.mockRidesForEvent(event)
            applyFilters()
            return
        }
        guard let fromCoord = fromCoordinate else {
            rides = []; applyFilters(); return
        }
        let fromPoint = LocationPoint(lat: fromCoord.latitude, lon: fromCoord.longitude, address: nil)
        rides = RideDataModel.shared.ridesNear(fromPoint, maxMeters: 1500)
        applyFilters()
    }

    // MARK: - Filter Logic

    private func applyFilters() {
        var result = activeFilter.apply(to: rides)

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
        let total    = rides.count
        let showing  = filteredRides.count
        let filtered = !activeFilter.isDefault || !searchQuery.isEmpty

        if filtered {
            resultCountLabel.text = showing == 0 ? "No rides match your filters"
                                                 : "Showing \(showing) of \(total) ride\(total == 1 ? "" : "s")"
        } else {
            resultCountLabel.text = "\(total) ride\(total == 1 ? "" : "s") available"
        }

        // Empty state
        emptyStateView.isHidden = !filteredRides.isEmpty

        // Filter button badge (orange tint when active)
        let isActive = !activeFilter.isDefault
        filterBarBtn.tintColor = isActive ? .systemOrange : .label
        filterBarBtn.image = UIImage(systemName: isActive
            ? "slider.horizontal.3"
            : "slider.horizontal.3")
    }

    // MARK: - Actions

    @objc private func filterTapped() {
        let vc = RideFilterViewController()
        vc.currentFilter = activeFilter
        vc.onApply = { [weak self] newFilter in
            self?.activeFilter = newFilter
            self?.applyFilters()
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }

    @objc private func clearFilters() {
        activeFilter = RideFilter()
        searchQuery  = ""
        searchController.searchBar.text = nil
        applyFilters()
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        searchQuery = searchController.searchBar.text ?? ""
        applyFilters()
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
        let driver = UserDataModel.shared.getUser(by: ride.driverUserID)
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
        openDetail(ride: ride, driver: UserDataModel.shared.getUser(by: ride.driverUserID))
    }

    private func openDetail(ride: Ride, driver: UserProfile?) {
        let vc = RideDetailViewController()
        vc.ride = ride; vc.driver = driver
        navigationController?.pushViewController(vc, animated: true)
    }
}
