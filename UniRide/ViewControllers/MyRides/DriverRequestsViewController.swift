import UIKit

/// A dedicated sheet for drivers to review and manage pending passenger requests.
final class DriverRequestsViewController: UIViewController {

    var trip: RideDataModel.MyTrip!
    private var requests: [RideRequest] = []

    @IBOutlet private var tableView: UITableView!

    private let emptyStateView = EmptyStateView(
        systemImage: "checkmark.seal.fill",
        title: "No requests yet",
        body: "Share your ride with classmates to start getting requests.",
        actionTitle: "Share Ride",
        tintColor: AppDesign.Color.primary
    )

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
        tableView.backgroundColor    = .clear
        tableView.delegate           = self
        tableView.dataSource         = self
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.separatorInset     = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tableView.contentInset       = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(RequestCell.self, forCellReuseIdentifier: RequestCell.identifier)
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        emptyStateView.onAction = { [weak self] in self?.shareRide() }
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        ])
    }

    private func shareRide() {
        let ride = trip.ride
        let tf = DateFormatter()
        tf.dateStyle = .medium
        tf.timeStyle = .short
        let from = ride.source.address ?? "Pickup"
        let to   = ride.destination.address ?? "Drop-off"
        let date = tf.string(from: ride.departureTime)
        let text = "I'm offering a ride on UniRide 🚗\n\(from) → \(to)\n\(date)\n\nFare: ₹\(Int(ride.farePerSeat)) per seat · \(ride.seatsAvailable) seat\(ride.seatsAvailable == 1 ? "" : "s") left\n\nOpen UniRide to request a seat."
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(vc, animated: true)
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
        let passenger = req.passengerProfile ?? UserDataModel.shared.getUser(by: req.passengerUserID)
        cell.configure(
            name: passenger?.fullName ?? "Passenger",
            subtitle: (passenger?.role?.rawValue.capitalized) ?? "User",
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
                showError("Request Not Approved", message: error.localizedDescription)
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
                showError("Request Not Declined", message: error.localizedDescription)
            }
        }
    }

    private func showError(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
