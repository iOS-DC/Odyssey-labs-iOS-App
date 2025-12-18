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

    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRideButton: UIButton!
    @IBOutlet weak var viewRequestButton: UIButton!

    @IBOutlet weak var requestContainerView: UIView!
    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var requestsContainerHeightConstraint: NSLayoutConstraint!

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

        selectionStyle = .none
        setupUI()

        mapView.isHidden = true
        requestContainerView.isHidden = true

        requestsTableView.delegate = self
        requestsTableView.dataSource = self
        requestsTableView.isScrollEnabled = false

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
    }

    private func setupUI() {
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        isRequestsExpanded = false
        isMapExpanded = false
        requestContainerView.isHidden = true
        mapView.isHidden = true
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {
        self.trip = trip
        let ride = trip.ride

        roleLabel.text = trip.role == .hosting ? "Hosting" : "Passenger"

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
        seatsLabel.text = "\(ride.seatsAvailable)/\(ride.seatsTotal)"

        // STATUS
        switch ride.status {
        case .draft:
            statusLabel.text = "Draft"
            statusLabel.textColor = .secondaryLabel
        case .published:
            statusLabel.text = "Active"
            statusLabel.textColor = .systemGreen
        case .ongoing:
            statusLabel.text = "Ongoing"
            statusLabel.textColor = .systemBlue
        case .completed:
            statusLabel.text = "Completed"
            statusLabel.textColor = .secondaryLabel
        case .cancelled:
            statusLabel.text = "Cancelled"
            statusLabel.textColor = .systemRed
        }

        // REQUESTS
        rideRequests = RideDataModel.shared.listRequests(for: ride.id)

        if rideRequests.isEmpty {
            viewRequestButton.isHidden = true
        } else {
            viewRequestButton.isHidden = false
            viewRequestButton.setTitle("Requests (\(rideRequests.count))", for: .normal)
        }

        // APPROVED PASSENGERS
        approvedPassengers = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .compactMap {
                UserDataModel.shared.getUser(by: $0.passengerUserID)?.fullName
            }

        passengersLabel.text = "Passengers (\(approvedPassengers.count))"
        approvedContainerHeightConstraint.constant =
            approvedPassengers.isEmpty ? 0 : CGFloat(approvedPassengers.count) * 44

        updateRequestTableHeight()
        
        drawRouteIfNeeded(for: ride)

        requestsTableView.reloadData()
        approvedTableView.reloadData()
    }

    // MARK: - Actions
    @IBAction func viewRequestsTapped(_ sender: UIButton) {
        isRequestsExpanded.toggle()
        updateRequestTableHeight()
        delegate?.upcomingCellRequestsToggled(self)
    }

    @IBAction func toggleMap(_ sender: UIButton) {
        isMapExpanded.toggle()
        mapView.isHidden = !isMapExpanded
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

    private func updateRequestTableHeight() {
        requestContainerView.isHidden = !isRequestsExpanded
        requestsContainerHeightConstraint.constant =
            isRequestsExpanded ? CGFloat(rideRequests.count) * 120 : 0
    }
    
    private func drawRouteIfNeeded(for ride: Ride) {
        mapView.removeOverlays(mapView.overlays)

        guard let route = ride.selectedRoute else { return }

        let coordinates = route.coordinates.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
        }

        guard coordinates.count > 1 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        mapView.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
            animated: false
        )
    }

}

// MARK: - Tables
extension UpcomingTableViewCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == requestsTableView ? rideRequests.count : approvedPassengers.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == requestsTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RequestCell.identifier,
                for: indexPath
            ) as! RequestCell

            let req = rideRequests[indexPath.row]
            let ride = trip!.ride

            cell.configure(
                name: UserDataModel.shared.getUser(by: req.passengerUserID)?.fullName ?? "Passenger",
                route: "\(ride.source.address ?? "From") → \(ride.destination.address ?? "To")"
            )

            cell.delegate = self
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovedCell", for: indexPath)
        cell.textLabel?.text = approvedPassengers[indexPath.row]
        return cell
    }
}

// MARK: - RequestCellDelegate
extension UpcomingTableViewCell: RequestCellDelegate {

    func requestCellApproveTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        let req = rideRequests[index]
        RideDataModel.shared.approveRequest(
            requestID: req.id,
            hostUserID: ride.driverUserID
        )
    }

    func requestCellDenyTapped(_ cell: RequestCell) {
        guard let index = requestsTableView.indexPath(for: cell)?.row,
              let ride = trip?.ride else { return }

        let req = rideRequests[index]
        RideDataModel.shared.denyRequest(
            requestID: req.id,
            hostUserID: ride.driverUserID
        )
    }
}

// MARK: - Map Renderer
extension UpcomingTableViewCell: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            renderer.lineCap = .round
            return renderer
        }
        return MKOverlayRenderer()
    }
}
