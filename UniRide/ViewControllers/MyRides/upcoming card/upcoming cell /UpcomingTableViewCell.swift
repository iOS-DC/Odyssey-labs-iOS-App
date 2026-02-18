import UIKit
import MapKit

protocol UpcomingTableViewCellDelegate: AnyObject {
    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapPassenger(_ cell: UpcomingTableViewCell, passenger: UserProfile, ride: Ride)
}

final class UpcomingTableViewCell: UITableViewCell {

    static let reuseIdentifier = "UpcomingRideCell"

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var passengersLabel: UILabel!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var showMapButton: UIButton!
    @IBOutlet weak var mapHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRideButton: UIButton!
    @IBOutlet weak var viewRequestButton: UIButton!

    @IBOutlet weak var requestContainerView: UIView!
    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var requestsContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRequestsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRequestsTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var requestsContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var passengersTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var approvedTableView: UITableView!
    @IBOutlet weak var approvedContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarStackView: UIView!

    // MARK: - State
    private var trip: RideDataModel.MyTrip?
    private var rideRequests: [RideRequest] = []
    private var approvedPassengers: [UserProfile] = []

    // Controls whether the "Confirmed Passengers" inline box is visible
    private var showConfirmedBox = false
    private var isMapExpanded = false

    weak var delegate: UpcomingTableViewCellDelegate?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        setupUI()

        // Hide the old "View Requests" toggle button — we always show requests inline now
        viewRequestButton.isHidden = true
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant = 0

        // Requests container starts hidden
        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        // Map starts hidden (keep height = 1 to avoid constraint conflicts)
        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        // Tables
        requestsTableView.delegate = self
        requestsTableView.dataSource = self
        requestsTableView.isScrollEnabled = false
        requestsTableView.rowHeight = UITableView.automaticDimension
        requestsTableView.estimatedRowHeight = 72

        approvedTableView.delegate = self
        approvedTableView.dataSource = self
        approvedTableView.isScrollEnabled = false
        approvedTableView.rowHeight = UITableView.automaticDimension
        approvedTableView.estimatedRowHeight = 60

        mapView.delegate = self

        requestsTableView.register(
            UINib(nibName: "RequestCell", bundle: nil),
            forCellReuseIdentifier: RequestCell.identifier
        )
        approvedTableView.register(ApprovedPassengerCell.self, forCellReuseIdentifier: ApprovedPassengerCell.identifier)
        approvedTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyCell")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.layer.cornerRadius = 18
        cardView.backgroundColor = .white
        cardView.layer.masksToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.masksToBounds = false
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

        trip = nil
        rideRequests.removeAll()
        approvedPassengers.removeAll()
        showConfirmedBox = false
        isMapExpanded = false

        viewRequestButton.isHidden = true
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant = 0

        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        // Remove any dynamically added avatars
        avatarStackView.subviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {
        self.trip = trip
        let ride = trip.ride

        roleLabel.text = "  Hosting  "
        applyBadgeStyle(to: roleLabel, backgroundColor: .systemGray6, textColor: .darkGray)

        dateLabel.text = DateFormatter.localizedString(
            from: ride.departureTime,
            dateStyle: .medium,
            timeStyle: .none
        )

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)

        let travel = ride.selectedRoute?.expectedTravelTime ?? 3600
        endTimeLabel.text = tf.string(from: ride.departureTime.addingTimeInterval(travel))
        durationLabel.text = "\(Int(travel / 60)) min"

        fromLabel.text = ride.source.address ?? "Unknown"
        toLabel.text = ride.destination.address ?? "Unknown"

        // Seat counts
        let confirmedCount = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .reduce(0) { $0 + $1.seats }
        seatsLabel.text = "\(confirmedCount) / \(ride.seatsTotal)"

        // Status badge
        let statusIcon: String
        let bgColor: UIColor
        switch ride.status {
        case .published:
            statusIcon = "✓"
            bgColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        case .ongoing:
            statusIcon = "▶"
            bgColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        default:
            statusIcon = "•"
            bgColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0)
        }
        statusLabel.text = "  \(statusIcon) \(ride.status.rawValue.capitalized)  "
        applyBadgeStyle(to: statusLabel, backgroundColor: bgColor, textColor: .white)

        // Pending requests
        rideRequests = RideDataModel.shared
            .listRequests(for: ride.id)
            .filter { $0.status == .pending }

        // Approved passengers
        approvedPassengers = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .compactMap { UserDataModel.shared.getUser(by: $0.passengerUserID) }

        passengersLabel.text = "Passengers: \(approvedPassengers.count) / \(ride.seatsTotal)"
        approvedContainerHeightConstraint.constant = 0

        // Render avatar circles (tappable)
        renderAvatars(passengers: approvedPassengers, totalSeats: ride.seatsTotal, ride: ride)

        // Show requests box inline if there are pending requests
        let hasRequests = !rideRequests.isEmpty
        if hasRequests {
            requestContainerView.isHidden = false
            requestContainerView.isUserInteractionEnabled = true
            // Each request row is ~72pt tall, plus 44pt header
            let rowH: CGFloat = 72
            requestsContainerHeightConstraint.constant = CGFloat(rideRequests.count) * rowH + 44
            requestsContainerTopConstraint.constant = 10
        } else if showConfirmedBox && !approvedPassengers.isEmpty {
            // Briefly show confirmed passengers box after an action
            requestContainerView.isHidden = false
            requestContainerView.isUserInteractionEnabled = false
            let rowH: CGFloat = 60
            requestsContainerHeightConstraint.constant = CGFloat(approvedPassengers.count) * rowH + 44
            requestsContainerTopConstraint.constant = 10
        } else {
            // Collapse the box completely — height=0 means avatarStackView sits right below passengersLabel
            requestContainerView.isHidden = true
            requestContainerView.isUserInteractionEnabled = false
            requestsContainerHeightConstraint.constant = 0
            requestsContainerTopConstraint.constant = 0
        }

        requestsTableView.reloadData()
        approvedTableView.reloadData()

        drawRouteIfNeeded(for: ride)
    }

    // MARK: - Actions
    @IBAction func viewRequestsTapped(_ sender: UIButton) {
        // No-op: requests are always shown inline now
    }

    @IBAction func toggleMap(_ sender: UIButton) {
        isMapExpanded.toggle()
        mapView.isHidden = !isMapExpanded
        mapHeightConstraint.constant = isMapExpanded ? 180 : 1

        // Update button title to match reference images
        if let btn = sender as? UIButton {
            var config = btn.configuration ?? UIButton.Configuration.filled()
            config.title = isMapExpanded ? "Hide Map" : "Show Map"
            btn.configuration = config
        }

        delegate?.upcomingCellRequestsToggled(self)
    }

    @IBAction func messageTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapMessage(self)
    }

    @IBAction func callTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapCall(self)
    }

    @IBAction func cancelRideTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapCancelRide(self)
    }

    // MARK: - Route Drawing
    private func drawRouteIfNeeded(for ride: Ride) {
        mapView.removeOverlays(mapView.overlays)
        guard let route = ride.selectedRoute else { return }

        let coords = route.coordinates.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
        }
        guard coords.count > 1 else { return }

        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30),
            animated: false
        )
    }

    // MARK: - Badge Styling
    private func applyBadgeStyle(to label: UILabel, backgroundColor: UIColor, textColor: UIColor) {
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.layer.cornerRadius = 13
        label.layer.masksToBounds = true
        label.textAlignment = .center
    }

    // MARK: - Avatar Stack
    private func renderAvatars(passengers: [UserProfile], totalSeats: Int, ride: Ride) {
        avatarStackView.subviews.forEach { $0.removeFromSuperview() }

        let size: CGFloat = 48
        let overlap: CGFloat = 16
        let showCount = min(max(passengers.count, totalSeats), 4)

        for i in 0..<showCount {
            let avatarView = UIImageView()
            avatarView.frame = CGRect(x: CGFloat(i) * (size - overlap), y: 2, width: size, height: size)
            avatarView.layer.cornerRadius = size / 2
            avatarView.layer.masksToBounds = true
            avatarView.layer.borderWidth = 2.5
            avatarView.layer.borderColor = UIColor.white.cgColor
            avatarView.contentMode = .scaleAspectFill
            avatarView.backgroundColor = UIColor.systemGray5
            avatarView.isUserInteractionEnabled = true

            if i < passengers.count {
                let passenger = passengers[i]
                // Show initials letter as placeholder
                let initial = String(passenger.fullName.prefix(1)).uppercased()
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
                label.text = initial
                label.textAlignment = .center
                label.font = .systemFont(ofSize: 18, weight: .semibold)
                label.textColor = .systemGray
                avatarView.addSubview(label)

                if let url = passenger.photoURL {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async {
                                avatarView.image = img
                                label.removeFromSuperview()
                            }
                        }
                    }.resume()
                }

                // Tap to show passenger details
                let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
                tap.view?.tag = i
                avatarView.tag = i
                avatarView.addGestureRecognizer(tap)
            } else {
                // Empty slot — person placeholder icon
                let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
                avatarView.image = UIImage(systemName: "person.fill", withConfiguration: config)
                avatarView.tintColor = .systemGray3
                avatarView.contentMode = .center
            }

            avatarStackView.addSubview(avatarView)
        }

        // Store ride reference for tap handler
        avatarStackView.tag = 0 // reset
    }

    @objc private func avatarTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view,
              tappedView.tag < approvedPassengers.count,
              let ride = trip?.ride else { return }

        let passenger = approvedPassengers[tappedView.tag]
        delegate?.upcomingCellDidTapPassenger(self, passenger: passenger, ride: ride)
    }
}

// MARK: - TableView (Requests + Confirmed Passengers)
extension UpcomingTableViewCell: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == requestsTableView {
            // If we have pending requests, show them; otherwise show confirmed passengers
            return rideRequests.isEmpty ? approvedPassengers.count : rideRequests.count
        }
        return max(approvedPassengers.count, 1)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == requestsTableView {
            return makeBoxHeader(
                title: rideRequests.isEmpty
                    ? "Confirmed Passengers"
                    : "Requests (\(rideRequests.count))"
            )
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView == requestsTableView ? 44 : 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == requestsTableView {
            if !rideRequests.isEmpty {
                // Pending request row with approve/deny
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: RequestCell.identifier,
                    for: indexPath
                ) as! RequestCell

                let req = rideRequests[indexPath.row]
                let ride = trip!.ride
                let passenger = UserDataModel.shared.getUser(by: req.passengerUserID)
                let name = passenger?.fullName ?? "Passenger"

                cell.configure(
                    name: name,
                    route: "\(ride.source.address ?? "From") → \(ride.destination.address ?? "To")",
                    photoURL: passenger?.photoURL
                )
                cell.delegate = self
                return cell
            } else {
                // Confirmed passenger row (shown briefly after action)
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                let passenger = approvedPassengers[indexPath.row]
                cell.textLabel?.text = passenger.fullName
                cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                cell.detailTextLabel?.text = "Confirmed"
                cell.detailTextLabel?.textColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1)
                cell.selectionStyle = .none
                cell.backgroundColor = .clear

                // Green accepted badge
                let badge = UILabel()
                badge.text = "  ✓ Accepted  "
                badge.font = .systemFont(ofSize: 12, weight: .bold)
                badge.textColor = .white
                badge.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1)
                badge.layer.cornerRadius = 11
                badge.layer.masksToBounds = true
                badge.sizeToFit()
                badge.frame.size.height = 26
                cell.accessoryView = badge
                return cell
            }
        }

        // approvedTableView (hidden, kept for outlet)
        if approvedPassengers.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            cell.textLabel?.text = "No passengers yet"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.textLabel?.textColor = .tertiaryLabel
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ApprovedPassengerCell.identifier, for: indexPath) as! ApprovedPassengerCell
        let passenger = approvedPassengers[indexPath.row]
        cell.configure(name: passenger.fullName, photoURL: passenger.photoURL)
        return cell
    }

    // MARK: - Box Header
    private func makeBoxHeader(title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}

// MARK: - RequestCellDelegate
extension UpcomingTableViewCell: RequestCellDelegate {

    func requestCellApproveTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        RideDataModel.shared.approveRequest(
            requestID: rideRequests[index].id,
            hostUserID: ride.driverUserID
        )

        // Show "Confirmed Passengers" box briefly, then auto-dismiss
        showConfirmedBox = true
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self else { return }
            self.showConfirmedBox = false
            NotificationCenter.default.post(name: .ridesUpdated, object: nil)
        }
    }

    func requestCellDenyTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        RideDataModel.shared.denyRequest(
            requestID: rideRequests[index].id,
            hostUserID: ride.driverUserID
        )

        showConfirmedBox = false
        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
    }
}

// MARK: - Map Renderer
extension UpcomingTableViewCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        r.strokeColor = .systemBlue
        r.lineWidth = 4
        return r
    }
}
