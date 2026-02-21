import UIKit

final class PastRideCell: UITableViewCell {

    static let reuseIdentifier = "PastRideCell"

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var passengersLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var approvedTableView: UITableView!
    @IBOutlet weak var approvedContainerHeightConstraint: NSLayoutConstraint!

    private var usersToShow: [UserProfile?] = []

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        // Card styling (cornerRadius, background, masksToBounds) is set in XIB.
        // Shadow must stay in code — requires masksToBounds=false on the cell layer.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        approvedTableView.delegate = self
        approvedTableView.dataSource = self
        approvedTableView.register(ApprovedPassengerCell.self, forCellReuseIdentifier: ApprovedPassengerCell.identifier)
        approvedTableView.rowHeight = 50
        approvedTableView.isScrollEnabled = false
        approvedTableView.tableFooterView = UIView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: cardView.frame,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usersToShow.removeAll()
        approvedContainerHeightConstraint.constant = 0
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        let ride = trip.ride
        let isHost = trip.role == .hosting

        roleLabel.text = isHost ? "Hosting" : "Passenger"

        // Status badge
        let isCompleted = ride.status == .completed
        statusLabel.text = isCompleted ? "  Completed  " : "  Cancelled  "
        statusLabel.backgroundColor = isCompleted
            ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15)
            : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 0.15)
        statusLabel.textColor = isCompleted
            ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
            : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0)
        statusLabel.font = .systemFont(ofSize: 11, weight: .bold)
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.masksToBounds = true
        statusLabel.textAlignment = .center

        // Date & time
        dateLabel.text = DateFormatter.localizedString(from: ride.departureTime, dateStyle: .medium, timeStyle: .none)
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        timeLabel.text = tf.string(from: ride.departureTime)

        // Route
        fromLabel.text = ride.source.address ?? "Unknown"
        toLabel.text = ride.destination.address ?? "Unknown"

        if isHost {
            let approved = RideDataModel.shared.listBookings(for: ride.id).filter { $0.status == .confirmed }
            usersToShow = approved.map { UserDataModel.shared.getUser(by: $0.passengerUserID) }
            passengersLabel.text = "Passengers (\(approved.count))"
            priceLabel.text = "Rs. \(ride.farePerSeat) per passenger"
            totalAmountLabel.text = "Received Rs. \(ride.farePerSeat * Double(approved.count))"
        } else {
            passengersLabel.text = "Rider"
            usersToShow = [UserDataModel.shared.getUser(by: ride.driverUserID)]
            priceLabel.text = "Rs. \(ride.farePerSeat)"
            totalAmountLabel.text = ""
        }

        approvedContainerHeightConstraint.constant = CGFloat(max(usersToShow.count, 1)) * 44
        approvedTableView.reloadData()
    }
}

// MARK: - TableView

extension PastRideCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(usersToShow.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ApprovedPassengerCell.identifier, for: indexPath) as! ApprovedPassengerCell
        if usersToShow.isEmpty {
            cell.configure(name: "No approved passengers", photoURL: nil)
        } else if let user = usersToShow[indexPath.row] {
            cell.configure(name: user.fullName, photoURL: user.photoURL)
        } else {
            cell.configure(name: "User unavailable", photoURL: nil)
        }
        return cell
    }
}
