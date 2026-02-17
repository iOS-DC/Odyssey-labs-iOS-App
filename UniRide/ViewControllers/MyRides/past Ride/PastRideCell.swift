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
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Match Home page card styling - flat design with 20pt corners
        cardView.layer.cornerRadius = 20
        cardView.backgroundColor = .systemBackground

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
        
        // Configure status badge
        let isCompleted = ride.status == .completed
        statusLabel.text = isCompleted ? "Completed" : "Cancelled"
        
        // Apply badge styling
        applyBadgeStyle(
            to: statusLabel,
            backgroundColor: isCompleted ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15) : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 0.15),
            textColor: isCompleted ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0) : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0)
        )

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
    
    // MARK: - Badge Styling
    private func applyBadgeStyle(to label: UILabel, backgroundColor: UIColor, textColor: UIColor) {
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
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
