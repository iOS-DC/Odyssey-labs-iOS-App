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
//    @IBOutlet weak var requestsContainerHeightConstraint: NSLayoutConstraint!
//    @IBOutlet weak var requestsTableHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var approvedTableView: UITableView!
    @IBOutlet weak var approvedContainerHeightConstraint: NSLayoutConstraint!

    // MARK: - State
    private var trip: RideDataModel.MyTrip?
    private var rideRequests: [RideRequest] = []
    private var approvedPassengers: [String] = []

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
//        requestsContainerHeightConstraint.constant = 200
//        requestsTableHeightConstraint.constant = 200

        // Map initial state (KEEP 1)
        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        // Tables
        requestsTableView.delegate = self
        requestsTableView.dataSource = self
        requestsTableView.isScrollEnabled = false
        requestsTableView.rowHeight = 70

        approvedTableView.delegate = self
        approvedTableView.dataSource = self
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
        
        // Match Home page card styling - flat design with 20pt corners
        cardView.layer.cornerRadius = 20
        cardView.backgroundColor = .systemBackground
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
//        requestsContainerHeightConstraint.constant = 200
//        requestsTableHeightConstraint.constant = 200

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

        roleLabel.text = "Hosting"

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

        // Apply badge styling to status label
        statusLabel.text = ride.status.rawValue.capitalized
        
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
        print(" [DEBUG] Request IDs:", rideRequests.map { $0.id })

        viewRequestButton.isHidden = rideRequests.isEmpty
        viewRequestButton.setTitle("Requests (\(rideRequests.count))", for: .normal)

        // ======================
        // APPROVED PASSENGERS
        // ======================
        approvedPassengers = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .compactMap {
                UserDataModel.shared.getUser(by: $0.passengerUserID)?.fullName
            }

        passengersLabel.text = "Passengers (\(approvedPassengers.count))"
        let approvedRowCount = max(approvedPassengers.count, 1)
        approvedContainerHeightConstraint.constant = CGFloat(approvedRowCount) * 44

        // RESET REQUEST UI ON CONFIGURE
        isRequestsExpanded = false
        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
//        requestsContainerHeightConstraint.constant = 200
//        requestsTableHeightConstraint.constant = 200


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

        requestsTableView.reloadData()

        delegate?.upcomingCellRequestsToggled(self)
    }


    @IBAction func toggleMap(_ sender: UIButton) {

        isMapExpanded.toggle()

        mapView.isHidden = !isMapExpanded
        mapHeightConstraint.constant = isMapExpanded ? 180 : 0
        sender.setTitle(isMapExpanded ? "Hide Map" : "Show Map", for: .normal)

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
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
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
            cell.configure(
                name: UserDataModel.shared.getUser(by: req.passengerUserID)?.fullName ?? "Passenger",
                route: "\(ride.source.address ?? "From") → \(ride.destination.address ?? "To")"
            )

            cell.delegate = self
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovedCell", for: indexPath)

        if approvedPassengers.isEmpty {
            cell.textLabel?.text = "No approved passengers"
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = approvedPassengers[indexPath.row]
            cell.textLabel?.textAlignment = .left
        }

        return cell

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
