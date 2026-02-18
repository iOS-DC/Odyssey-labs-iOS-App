import UIKit
import MapKit

protocol UpcomingTableViewCellDelegate: AnyObject {
    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell)
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

    // MARK: - State
    private var trip: RideDataModel.MyTrip?
    private var rideRequests: [RideRequest] = []
    private var approvedPassengers: [UserProfile] = []

    private var isRequestsExpanded = false
    private var isMapExpanded = false

    weak var delegate: UpcomingTableViewCellDelegate?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        print("UpcomingTableViewCell awakeFromNib")

        selectionStyle = .none
        setupUI()

        // Requests container initial state
        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        // Map initial state (KEEP 1)
        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        // Tables
        requestsTableView.delegate = self
        requestsTableView.dataSource = self
        requestsTableView.isScrollEnabled = true  // Enable scrolling for 1-2 items
        requestsTableView.rowHeight = 70

        approvedTableView.register(ApprovedPassengerCell.self, forCellReuseIdentifier: ApprovedPassengerCell.identifier)
        approvedTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyCell") // For text-only empty state
        approvedTableView.rowHeight = 50
        approvedTableView.dataSource = self
        approvedTableView.delegate = self
        approvedTableView.isScrollEnabled = false

        mapView.delegate = self

        requestsTableView.register(
            UINib(nibName: "RequestCell", bundle: nil),
            forCellReuseIdentifier: RequestCell.identifier
        )

        approvedTableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "ApprovedCell"
        )

        print("👉 viewRequestButton enabled:", viewRequestButton.isEnabled)
        print("👉 viewRequestButton interaction:", viewRequestButton.isUserInteractionEnabled)
    }

    private func setupUI() {
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

        trip = nil
        rideRequests.removeAll()
        approvedPassengers.removeAll()

        isRequestsExpanded = false
        isMapExpanded = false

        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        mapView.isHidden = true
        mapHeightConstraint.constant = 1
        showMapButton.setTitle("Show Map", for: .normal)
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {
        self.trip = trip
        let ride = trip.ride

        print(" CONFIGURE CELL — Ride:", ride.id)
        print(" Ride status:", ride.status.rawValue)

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
        
        let pendingCount = RideDataModel.shared
            .listRequests(for: ride.id)
            .filter { $0.status == .pending }
            .reduce(0) { $0 + $1.seats }

        let confirmedCount = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .reduce(0) { $0 + $1.seats }

        let occupiedSeats = pendingCount + confirmedCount

        seatsLabel.text = "\(occupiedSeats)/\(ride.seatsTotal)"

        // Apply badge styling to status label with padding
        statusLabel.text = "  \(ride.status.rawValue.capitalized)  "
        
        let (bgColor, textColor): (UIColor, UIColor)
        switch ride.status {
        case .published:
            bgColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.15)
            textColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        case .ongoing:
            bgColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.15)
            textColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        default:
            bgColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 0.15)
            textColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0)
        }
        
        applyBadgeStyle(to: statusLabel, backgroundColor: bgColor, textColor: textColor)

        // ======================
        // REQUESTS
        // ======================
        rideRequests = RideDataModel.shared
            .listRequests(for: ride.id)
            .filter { $0.status == .pending }

        print(" [DEBUG] Pending requests count:", rideRequests.count)
        
        let hasRequests = !rideRequests.isEmpty
        viewRequestButton.isHidden = !hasRequests
        viewRequestButton.setTitle("Requests (\(rideRequests.count))", for: .normal)
        viewRequestsHeightConstraint.constant = hasRequests ? 34 : 0
        viewRequestsTopConstraint.constant = hasRequests ? 12 : 0

        // ======================
        // APPROVED PASSENGERS
        // ======================
        approvedPassengers = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .compactMap {
                UserDataModel.shared.getUser(by: $0.passengerUserID)
            }

        passengersLabel.text = "Passengers (\(approvedPassengers.count))"
        let approvedRowCount = max(approvedPassengers.count, 1)
        approvedContainerHeightConstraint.constant = CGFloat(approvedRowCount) * 44

        // Manage container and spacing
        if hasRequests {
            requestContainerView.isHidden = !isRequestsExpanded
            requestContainerView.isUserInteractionEnabled = isRequestsExpanded
            
            let reqCount = min(rideRequests.count, 2)
            requestsContainerHeightConstraint.constant = isRequestsExpanded ? CGFloat(reqCount * 70) : 0
            requestsContainerTopConstraint.constant = isRequestsExpanded ? 8 : 0
            passengersTopConstraint.constant = isRequestsExpanded ? 12 : 8 // Small gap from button if collapsed
        } else {
            requestContainerView.isHidden = true
            requestContainerView.isUserInteractionEnabled = false
            requestsContainerHeightConstraint.constant = 0
            requestsContainerTopConstraint.constant = 0
            passengersTopConstraint.constant = 0 // Fully collapsed
        }

        requestsTableView.reloadData()
        approvedTableView.reloadData()

        drawRouteIfNeeded(for: ride)
    }

    // MARK: - Actions
    @IBAction func viewRequestsTapped(_ sender: UIButton) {
        print("🔥 viewRequestsTapped CALLED")

        guard !rideRequests.isEmpty else { return }

        isRequestsExpanded.toggle()

        requestContainerView.isHidden = !isRequestsExpanded
        requestContainerView.isUserInteractionEnabled = isRequestsExpanded
        
        let reqCount = min(rideRequests.count, 2)
        requestsContainerHeightConstraint.constant = isRequestsExpanded ? CGFloat(reqCount * 70) : 0
        requestsContainerTopConstraint.constant = isRequestsExpanded ? 8 : 0
        passengersTopConstraint.constant = isRequestsExpanded ? 12 : 8

        requestsTableView.reloadData()

        delegate?.upcomingCellRequestsToggled(self)
    }


    @IBAction func toggleMap(_ sender: UIButton) {

        isMapExpanded.toggle()

        mapView.isHidden = !isMapExpanded
        mapHeightConstraint.constant = isMapExpanded ? 180 : 0
        sender.setTitle(isMapExpanded ? "Hide Route" : "Show Route", for: .normal)

        delegate?.upcomingCellRequestsToggled(self)   // 👈 VERY IMPORTANT
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
        label.font = .systemFont(ofSize: 10, weight: .bold) // Slightly smaller font
        label.layer.cornerRadius = 8 // Better pill look
        label.layer.masksToBounds = true
        label.textAlignment = .center
        
        // Horizontal padding is achieved by adding spaces to the text in configure()
    }
}

// MARK: - Tables
extension UpcomingTableViewCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == requestsTableView {
            return rideRequests.count
        } else {
            return max(approvedPassengers.count, 1)
        }

    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == requestsTableView {
            print("🟢 cellForRowAt REQUEST index =", indexPath.row)

            let cell = tableView.dequeueReusableCell(
                withIdentifier: RequestCell.identifier,
                for: indexPath
            ) as! RequestCell

            let req = rideRequests[indexPath.row]
            print("🟢 Request ID =", req.id)

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
        }

        if approvedPassengers.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            cell.textLabel?.text = "No approved passengers"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            cell.textLabel?.textColor = .secondaryLabel
            cell.imageView?.image = nil
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ApprovedPassengerCell.identifier, for: indexPath) as! ApprovedPassengerCell
            let passenger = approvedPassengers[indexPath.row]
            cell.configure(name: passenger.fullName, photoURL: passenger.photoURL)
            return cell
        }

    }
}

// MARK: - RequestCellDelegate
extension UpcomingTableViewCell: RequestCellDelegate {

    func requestCellApproveTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        print("✅ APPROVE tapped")

        RideDataModel.shared.approveRequest(
            requestID: rideRequests[index].id,
            hostUserID: ride.driverUserID
        )

        NotificationCenter.default.post(name: .ridesUpdated, object: nil)
    }

    func requestCellDenyTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        print("❌ DENY tapped")

        RideDataModel.shared.denyRequest(
            requestID: rideRequests[index].id,
            hostUserID: ride.driverUserID
        )

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
