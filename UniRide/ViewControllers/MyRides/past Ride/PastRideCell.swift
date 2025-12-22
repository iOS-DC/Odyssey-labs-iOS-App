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


    private var namesToShow: [String] = []

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        cardView.layer.cornerRadius = 12
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)

        approvedTableView.delegate = self
        approvedTableView.dataSource = self
        approvedTableView.isScrollEnabled = false
        approvedTableView.rowHeight = 44
        approvedTableView.tableFooterView = UIView()

        approvedTableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "NameCell"
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        namesToShow.removeAll()
        approvedContainerHeightConstraint.constant = 0
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {

        let ride = trip.ride
        let isHost = trip.role == .hosting

        roleLabel.text = isHost ? "Hosting" : "Passenger"
        statusLabel.text = ride.status == .completed ? "Completed" : "Cancelled"
        statusLabel.textColor = ride.status == .completed ? .systemGreen : .systemRed

        dateLabel.text = DateFormatter.localizedString(
            from: ride.departureTime,
            dateStyle: .medium,
            timeStyle: .none
        )

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        timeLabel.text = tf.string(from: ride.departureTime)

        fromLabel.text = ride.source.address ?? "Unknown"
        toLabel.text = ride.destination.address ?? "Unknown"

        if isHost {
            let approved = RideDataModel.shared
                .listBookings(for: ride.id)
                .filter { $0.status == .confirmed }

            namesToShow = approved.compactMap {
                UserDataModel.shared.getUser(by: $0.passengerUserID)?.fullName
            }

            if namesToShow.isEmpty {
                namesToShow = ["No approved passengers"]
            }

            passengersLabel.text = "Passengers (\(approved.count))"

            let price = ride.farePerSeat
            priceLabel.text = "Rs. \(price) per passenger"
            totalAmountLabel.text = "Received Rs. \(price * Double(approved.count))"
        } else {
            passengersLabel.text = "Rider"
            namesToShow = [
                UserDataModel.shared.getUser(by: ride.driverUserID)?.fullName
                ?? "Rider unavailable"
            ]
            priceLabel.text = "Rs. \(ride.farePerSeat)"
            totalAmountLabel.text = ""
        }

        // ✅ CRITICAL FIX (NO NaN)
        let rowCount = max(namesToShow.count, 1)
        approvedContainerHeightConstraint.constant = CGFloat(rowCount) * 44

        approvedTableView.reloadData()
//        delegate?.pastRideCellNeedsResize(self)
    }
}

// MARK: - Table
extension PastRideCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesToShow.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NameCell",
            for: indexPath
        )

        let name = namesToShow[indexPath.row]
        cell.textLabel?.text = name
        cell.textLabel?.textAlignment = name.contains("No") ? .center : .left
        cell.selectionStyle = .none
        return cell
    }
}
