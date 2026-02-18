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

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Unified card styling to match Home page
        cardView.layer.cornerRadius = 18
        cardView.backgroundColor = .systemBackground
        cardView.layer.masksToBounds = true

        // Shadow styling
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        approvedTableView.delegate = self
        approvedTableView.register(ApprovedPassengerCell.self, forCellReuseIdentifier: ApprovedPassengerCell.identifier)
        approvedTableView.rowHeight = 50
        approvedTableView.dataSource = self
        approvedTableView.isScrollEnabled = false
        approvedTableView.tableFooterView = UIView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Compute shadow path based on cardView frame
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
        
        // Configure status badge — add padding spaces for pill breathing room
        let isCompleted = ride.status == .completed
        statusLabel.text = isCompleted ? "  Completed  " : "  Cancelled  "
        
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

            usersToShow = approved.map {
                UserDataModel.shared.getUser(by: $0.passengerUserID)
            }

            if usersToShow.isEmpty {
                usersToShow = [] // Will show "No approved passengers" logic later
            }

            passengersLabel.text = "Passengers (\(approved.count))"

            let price = ride.farePerSeat
            priceLabel.text = "Rs. \(price) per passenger"
            totalAmountLabel.text = "Received Rs. \(price * Double(approved.count))"
        } else {
            passengersLabel.text = "Rider"
            usersToShow = [
                UserDataModel.shared.getUser(by: ride.driverUserID)
            ]
            priceLabel.text = "Rs. \(ride.farePerSeat)"
            totalAmountLabel.text = ""
        }

        // ✅ CRITICAL FIX (NO NaN)
        let rowCount = max(usersToShow.count, 1)
        approvedContainerHeightConstraint.constant = CGFloat(rowCount) * 44

        approvedTableView.reloadData()
//        delegate?.pastRideCellNeedsResize(self)
    }
    
    // MARK: - Badge Styling
    private func applyBadgeStyle(to label: UILabel, backgroundColor: UIColor, textColor: UIColor) {
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
    }
}

// MARK: - Table
extension PastRideCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(usersToShow.count, 1)
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: ApprovedPassengerCell.identifier, for: indexPath) as! ApprovedPassengerCell
        
        if usersToShow.isEmpty {
            cell.configure(name: "No approved passengers", photoURL: nil)
        } else if let passenger = usersToShow[indexPath.row] {
            cell.configure(name: passenger.fullName, photoURL: passenger.photoURL)
        } else {
            cell.configure(name: "User unavailable", photoURL: nil)
        }
        
        return cell
    }
}
