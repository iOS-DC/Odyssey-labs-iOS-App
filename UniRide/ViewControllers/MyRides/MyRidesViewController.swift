import UIKit

final class MyRidesViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton?

    private enum RideFilter {
        case all
        case completed
        case cancelled
    }

    private var currentFilter: RideFilter = .all
    private var upcomingTrips: [RideDataModel.MyTrip] = []
    private var pastTrips: [RideDataModel.MyTrip] = []
    private var currentTrips: [RideDataModel.MyTrip] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hosting cell
        tableView.register(
            UINib(nibName: "UpcomingTableViewCell", bundle: nil),
            forCellReuseIdentifier: UpcomingTableViewCell.reuseIdentifier
        )

        // Passenger cell
        tableView.register(
            UINib(nibName: "UpcomingPassengerTableViewCell", bundle: nil),
            forCellReuseIdentifier: "UpcomingPassengerTableViewCell"
        )
        tableView.register(
            UINib(nibName: "PastRideCell", bundle: nil),
            forCellReuseIdentifier: PastRideCell.reuseIdentifier
        )


        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 260
        
        // Add content inset to table view to provide space for the filter button
        // when it's visible in the "Past" segment.
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)

        setupFilterButton()
        reloadTrips()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ridesDidUpdate),
            name: .ridesUpdated,
            object: nil
        )
        
        print("PAST COUNT =", pastTrips.count)
        for t in pastTrips {
            print("Ride:", t.ride.id, "status:", t.ride.status)
        }


    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTrips()
    }


    
    @objc private func ridesDidUpdate() {
        reloadTrips()
    }

    // MARK: - Data
    private func reloadTrips() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        upcomingTrips = RideDataModel.shared.myUpcoming(userID: user.id)
        pastTrips = RideDataModel.shared.myPast(userID: user.id)

        updateForSelectedSegment()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateForSelectedSegment()
        
        // Show/hide filter button based on segment
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
    }

    // MARK: - Filter
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Filter Rides",
            message: "Select filter option",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "All", style: .default) { [weak self] _ in
            self?.currentFilter = .all
            self?.applyFilter()
        })

        alert.addAction(UIAlertAction(title: "Completed", style: .default) { [weak self] _ in
            self?.currentFilter = .completed
            self?.applyFilter()
        })

        alert.addAction(UIAlertAction(title: "Cancelled", style: .default) { [weak self] _ in
            self?.currentFilter = .cancelled
            self?.applyFilter()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

    private func applyFilter() {
        switch currentFilter {
        case .all:
            currentTrips = pastTrips
        case .completed:
            currentTrips = pastTrips.filter { $0.ride.status == .completed }
        case .cancelled:
            currentTrips = pastTrips.filter { $0.ride.status == .cancelled }
        }
        tableView.reloadData()
    }

    
    private func setupFilterButton() {
        guard let btn = filterButton else { return }
        
        btn.layer.cornerRadius = 18
        btn.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        btn.tintColor = .systemBlue
        
        // Icon only — no title
        btn.setTitle(nil, for: .normal)
        btn.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        
        // Shadow for premium feel
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - TableView
extension MyRidesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return max(currentTrips.count, 0)
    }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let trip = currentTrips[indexPath.row]

        // UPCOMING
        if segmentedControl.selectedSegmentIndex == 0 {

            switch trip.role {

            case .hosting:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: UpcomingTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as! UpcomingTableViewCell

                cell.configure(with: trip)
                cell.delegate = self
                return cell

            case .passenger:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "UpcomingPassengerTableViewCell",
                    for: indexPath
                ) as! UpcomingPassengerTableViewCell

                cell.configure(with: trip)

                // Wire up cancel button — tag = row so the action can find the right trip
                cell.cancelRequestButton.tag = indexPath.row
                cell.cancelRequestButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.cancelRequestButton.addTarget(
                    self,
                    action: #selector(cancelPassengerRequest(_:)),
                    for: .touchUpInside
                )
                return cell
            }
        }

        // PAST
        else {
            
            print("PAST CELL RENDER:", trip.ride.id)

            let cell = tableView.dequeueReusableCell(
                withIdentifier: PastRideCell.reuseIdentifier,
                for: indexPath
            ) as! PastRideCell

            cell.configure(with: trip)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add top & bottom padding to match Home page behavior
        let inset: CGFloat = 12
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: 0, dy: inset / 2)
    }

}

// MARK: - Cell Delegate (HOST)
extension MyRidesViewController: UpcomingTableViewCellDelegate {

    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell) {
        print("Message tapped")

//        let sb = UIStoryboard(name: "Messages", bundle: nil)
//        guard let vc = sb.instantiateViewController(
//            withIdentifier: "MessageViewController"
//        ) as? MessageViewController else {
//            print("VC not found")
//            return
//        }
//
//        if let nav = navigationController {
//            nav.pushViewController(vc, animated: true)
//        } else {
//            vc.modalPresentationStyle = .fullScreen
//            present(vc, animated: true)
//        }
    }


    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell) {
        print("Call tapped (future call)")
    }

    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let trip = currentTrips[index]

        RideDataModel.shared.cancelRide(id: trip.ride.id)
        reloadTrips()
    }

    func upcomingCellDidTapPassenger(_ cell: UpcomingTableViewCell, passenger: UserProfile, ride: Ride) {
        let vc = PassengerDetailViewController(passenger: passenger, ride: ride)
        vc.onRemovePassenger = { [weak self] in
            self?.reloadTrips()
        }
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

    @objc private func cancelPassengerRequest(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }

        let trip = currentTrips[index]
        guard trip.role == .passenger,
              let me = UserDataModel.shared.getCurrentUser()
        else { return }

        let alertTitle = trip.requestStatus == .approved ? "Cancel Booking" : "Cancel Request"
        let alertMsg   = trip.requestStatus == .approved
            ? "Are you sure you want to cancel your confirmed booking?"
            : "Are you sure you want to cancel this ride request?"
        let actionTitle = trip.requestStatus == .approved ? "Cancel Booking" : "Cancel Request"

        let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        alert.addAction(UIAlertAction(title: actionTitle, style: .destructive) { [weak self] _ in
            guard let self else { return }

            if trip.requestStatus == .approved {
                // Confirmed booking — find it by rideID + passengerUserID and cancel it
                let bookings = RideDataModel.shared.listBookings(for: trip.ride.id)
                if let booking = bookings.first(where: {
                    $0.passengerUserID == me.id && $0.status == .confirmed
                }) {
                    RideDataModel.shared.cancelBooking(
                        bookingID: booking.id,
                        by: me.id
                    )
                }
            } else if let requestID = trip.requestID {
                // Pending/denied request — cancel it directly
                RideDataModel.shared.cancelMyRequest(
                    requestID: requestID,
                    passengerUserID: me.id
                )
            }

            self.reloadTrips()
        })
        present(alert, animated: true)
    }
   
}





