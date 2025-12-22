import UIKit

final class MyRidesViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

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
    }

    private func updateForSelectedSegment() {
        guard segmentedControl.selectedSegmentIndex < 2 else { return }

        currentTrips = segmentedControl.selectedSegmentIndex == 0
            ? upcomingTrips
            : pastTrips

        tableView.reloadData()
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
    
}

// MARK: - Passenger Actions
extension MyRidesViewController {

    @objc private func cancelPassengerRequest(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentTrips.count else { return }

        let trip = currentTrips[index]
        guard trip.role == .passenger,
              let requestID = trip.requestID,
              let me = UserDataModel.shared.getCurrentUser()
        else { return }

        RideDataModel.shared.cancelMyRequest(
            requestID: requestID,
            passengerUserID: me.id
        )

        reloadTrips()
    }
   
}





