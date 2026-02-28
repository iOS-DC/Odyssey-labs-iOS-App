import UIKit

/// A dedicated screen for drivers to review and manage pending passenger requests.
final class DriverRequestsViewController: UIViewController {

    private let trip: RideDataModel.MyTrip
    private var requests: [RideRequest] = []

    private let tableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateView = EmptyStateView(
        systemImage: "person.3.sequence",
        title: "No Pending Requests",
        body: "You don't have any new join requests right now.",
        tintColor: AppDesign.Color.primary
    )

    init(trip: RideDataModel.MyTrip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Requests"
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        setupEmptyState()
        
        // Listen for data changes so we can refresh
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: .rideRequestsUpdated, object: nil)
        
        loadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.contentInset = UIEdgeInsets(top: AppDesign.Spacing.xs, left: 0, bottom: AppDesign.Spacing.lg, right: 0)
        
        tableView.register(UINib(nibName: "RequestCell", bundle: nil), forCellReuseIdentifier: RequestCell.identifier)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }

    @objc private func loadData() {
        // Fetch only pending requests for this specific ride
        requests = RideDataModel.shared.listRequests(for: trip.ride.id).filter { $0.status == .pending }
        tableView.reloadData()

        let isEmpty = requests.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
    }
}

// MARK: - UITableViewDataSource
extension DriverRequestsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RequestCell.identifier, for: indexPath) as! RequestCell
        let req = requests[indexPath.row]
        let passenger = UserDataModel.shared.getUser(by: req.passengerUserID)
        
        cell.configure(
            name: passenger?.fullName ?? "Passenger",
            route: "\(trip.ride.source.address ?? "From") → \(trip.ride.destination.address ?? "To")",
            photoURL: passenger?.photoURL
        )
        // Set the cell's delegate so we can capture approve/deny taps
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - RequestCellDelegate
extension DriverRequestsViewController: RequestCellDelegate {
    
    func requestCellApproveTapped(_ cell: RequestCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let request = requests[index]
        RideDataModel.shared.approveRequest(requestID: request.id, hostUserID: trip.ride.driverUserID)
        // UI updates automatically because approveRequest posts .rideRequestsUpdated -> loadData() gets called
    }

    func requestCellDenyTapped(_ cell: RequestCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let request = requests[index]
        RideDataModel.shared.denyRequest(requestID: request.id, hostUserID: trip.ride.driverUserID)
    }
}
