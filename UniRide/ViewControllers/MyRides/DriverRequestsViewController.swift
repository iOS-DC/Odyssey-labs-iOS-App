import UIKit

/// A dedicated sheet for drivers to review and manage pending passenger requests.
final class DriverRequestsViewController: UIViewController {

    private let trip: RideDataModel.MyTrip
    private var requests: [RideRequest] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateView = EmptyStateView(
        systemImage: "checkmark.seal.fill",
        title: "All Caught Up!",
        body: "No pending join requests for this ride.",
        tintColor: AppDesign.Color.primary
    )

    init(trip: RideDataModel.MyTrip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Requests"
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        setupEmptyState()
        loadData()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Layout

    private func setupTableView() {
        tableView.backgroundColor  = .clear
        tableView.delegate         = self
        tableView.dataSource       = self
        tableView.rowHeight        = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.separatorInset   = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.contentInset     = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(RequestCell.self, forCellReuseIdentifier: RequestCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        ])
    }

    // MARK: - Data

    private func loadData() {
        requests = RideDataModel.shared.listRequests(for: trip.ride.id).filter { $0.status == .pending }
        tableView.reloadData()
        let isEmpty = requests.isEmpty
        tableView.isHidden    = isEmpty
        emptyStateView.isHidden = !isEmpty
    }

    // MARK: - Handle action result
    /// Removes the row at index and auto-dismisses when no requests remain.
    private func handleActionResult(removingAt index: Int) {
        requests.remove(at: index)
        if requests.isEmpty {
            // Show empty state briefly then dismiss
            tableView.isHidden      = true
            emptyStateView.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                self?.dismiss(animated: true)
            }
        } else {
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate
extension DriverRequestsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        requests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: RequestCell.identifier, for: indexPath) as! RequestCell
        let req       = requests[indexPath.row]
        let passenger = UserDataModel.shared.getUser(by: req.passengerUserID)
        cell.configure(
            name: passenger?.fullName ?? "Passenger",
            subtitle: passenger?.role == .student ? "Student" : "Faculty",
            photoURL: passenger?.photoURL
        )
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await RideDataModel.shared.approveRequestAsync(
                    requestID: request.id, hostUserID: trip.ride.driverUserID)
                handleActionResult(removingAt: index)
            } catch {
                showError("Couldn't approve request", message: error.localizedDescription)
            }
        }
    }

    func requestCellDenyTapped(_ cell: RequestCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let request = requests[index]
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await RideDataModel.shared.denyRequestAsync(
                    requestID: request.id, hostUserID: trip.ride.driverUserID)
                handleActionResult(removingAt: index)
            } catch {
                showError("Couldn't decline request", message: error.localizedDescription)
            }
        }
    }

    private func showError(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
