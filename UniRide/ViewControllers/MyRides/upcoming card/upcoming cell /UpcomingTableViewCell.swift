import UIKit
import MapKit

protocol UpcomingTableViewCellDelegate: AnyObject {
    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapStartTrip(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapEndTrip(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapPassenger(_ cell: UpcomingTableViewCell, passenger: UserProfile, ride: Ride)
    func upcomingCellDidTapViewRequests(_ cell: UpcomingTableViewCell)
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
    @IBOutlet weak var startTripButton: UIButton!
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
    var trip: RideDataModel.MyTrip?
    private var rideRequests: [RideRequest] = []
    private var approvedPassengers: [UserProfile] = []
    private var isMapExpanded = false

    // Programmatic inline badge (replaces XIB viewRequestButton which overlaps roleLabel)
    private let pendingBadge = UILabel()

    weak var delegate: UpcomingTableViewCellDelegate?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        // Cell itself is transparent — the cardView is the visual "card"
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Card appearance — corner radius + white background (XIB already has 12pt H margins, 8pt V margins)
        cardView.applyCardStyle(
            corner: AppDesign.Radius.lg,
            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
            shadowRadius: AppDesign.Shadow.smallCardRadius,
            shadowOffset: AppDesign.Shadow.smallCardOffset
        )

        // Requests container begins collapsed
        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        // Map starts hidden
        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        mapView.delegate = self

        roleLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)
        statusLabel.applyTextStyle(AppDesign.Typography.captionStrong)
        dateLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        fromLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        toLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        startTimeLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        endTimeLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        durationLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        passengersLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        seatsLabel.applyTextStyle(AppDesign.Typography.bodyStrong)

        // Inline pending badge — sits to the right of roleLabel on the same row
        pendingBadge.font       = AppDesign.Typography.captionStrong
        pendingBadge.textColor  = AppDesign.Color.primary
        pendingBadge.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.12)
        pendingBadge.textAlignment   = .center
        pendingBadge.layer.cornerRadius  = AppDesign.Radius.sm
        pendingBadge.layer.masksToBounds = true
        pendingBadge.isHidden            = true
        pendingBadge.isUserInteractionEnabled = true
        pendingBadge.translatesAutoresizingMaskIntoConstraints = false
        pendingBadge.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(pendingBadgeTapped))
        )
        cardView.addSubview(pendingBadge)
        NSLayoutConstraint.activate([
            pendingBadge.leadingAnchor.constraint(equalTo: roleLabel.trailingAnchor, constant: 8),
            pendingBadge.centerYAnchor.constraint(equalTo: roleLabel.centerYAnchor),
            pendingBadge.heightAnchor.constraint(equalToConstant: 24),
        ])

        // Always hide the XIB button — it sits at cardView.top+0 and overlaps roleLabel
        viewRequestButton.isHidden = true
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant    = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Shadow path on cardView so it hugs the rounded card edges
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        trip = nil
        rideRequests.removeAll()
        approvedPassengers.removeAll()
        isMapExpanded = false

        viewRequestButton.isHidden = true
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant    = 0
        pendingBadge.isHidden = true

        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0
        passengersTopConstraint.constant = 0

        mapView.isHidden = true
        mapHeightConstraint.constant = 1

        avatarStackView.subviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        self.trip = trip
        let ride = trip.ride

        // Role badge
        roleLabel.text = "  Hosting  "
        applyBadgeStyle(to: roleLabel, backgroundColor: .systemGray6, textColor: .darkGray)

        // Date & times
        dateLabel.text = DateFormatter.localizedString(from: ride.departureTime, dateStyle: .medium, timeStyle: .none)
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)
        let travel = ride.selectedRoute?.expectedTravelTime ?? 3600
        endTimeLabel.text = tf.string(from: ride.departureTime.addingTimeInterval(travel))
        durationLabel.text = "\(Int(travel / 60)) min"

        // Route
        fromLabel.text = ride.source.address ?? "Unknown"
        toLabel.text = ride.destination.address ?? "Unknown"

        // Seats
        let confirmedCount = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .reduce(0) { $0 + $1.seats }
        seatsLabel.text = "\(confirmedCount) / \(ride.seatsTotal)"

        // Status badge
        let (statusIcon, bgColor): (String, UIColor) = {
            switch ride.status {
            case .published: return ("✓", UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0))
            case .ongoing:   return ("▶", AppDesign.Color.primary)
            default:         return ("•", UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0))
            }
        }()
        statusLabel.text = "  \(statusIcon) \(ride.status.rawValue.capitalized)  "
        applyBadgeStyle(to: statusLabel, backgroundColor: bgColor, textColor: .white)

        // Pending request badge (inline with roleLabel)
        rideRequests = RideDataModel.shared.listRequests(for: ride.id).filter { $0.status == .pending }
        if rideRequests.isEmpty {
            pendingBadge.isHidden = true
        } else {
            let count = rideRequests.count
            pendingBadge.text    = "  \(count) Pending  "
            pendingBadge.isHidden = false
        }

        // XIB viewRequestButton is permanently hidden (wrong position in XIB)
        viewRequestButton.isHidden            = true
        viewRequestsHeightConstraint.constant = 0
        viewRequestsTopConstraint.constant    = 0

        // Approved passengers
        approvedPassengers = RideDataModel.shared
            .listBookings(for: ride.id)
            .filter { $0.status == .confirmed }
            .compactMap { UserDataModel.shared.getUser(by: $0.passengerUserID) }

        passengersLabel.text = "Passengers: \(approvedPassengers.count) / \(ride.seatsTotal)"
        approvedContainerHeightConstraint.constant = 0

        renderAvatars(passengers: approvedPassengers, totalSeats: ride.seatsTotal, ride: ride)

        // Requests container always hidden now (moved to separate screen)
        requestContainerView.isHidden = true
        requestContainerView.isUserInteractionEnabled = false
        requestsContainerHeightConstraint.constant = 0
        requestsContainerTopConstraint.constant = 0

        drawRouteIfNeeded(for: ride)
        
        // Button Styles
        cancelRideButton.applyTintActionStyle(title: "Cancel Ride", color: AppDesign.Color.destructive)

        messageButton.applyTintActionStyle(title: "Chat", imageSystemName: "message.fill")

        // ── Unread badge on Chat button ──
        let rideIDStr = trip.ride.id.uuidString
        applyUnreadBadge(to: messageButton, rideID: rideIDStr)

        callButton.applyTintActionStyle(title: "Call", imageSystemName: "phone.fill")
        
        showMapButton.applyTintActionStyle(
            title: isMapExpanded ? "Hide" : "Map",
            imageSystemName: isMapExpanded ? "map.fill" : "map"
        )

        // Start / End Trip button
        startTripButton.backgroundColor = .clear
        switch ride.status {
        case .published:
            var startConfig = UIButton.Configuration.filled()
            startConfig.title = "Start Trip"
            startConfig.image = UIImage(systemName: "play.fill")
            startConfig.imagePlacement = .leading
            startConfig.imagePadding = 6
            startConfig.baseBackgroundColor = AppDesign.Color.success
            startConfig.baseForegroundColor = .white
            startConfig.cornerStyle = .capsule
            startTripButton.configuration = startConfig
            startTripButton.isHidden = false
        case .ongoing:
            var endConfig = UIButton.Configuration.filled()
            endConfig.title = "End Trip"
            endConfig.image = UIImage(systemName: "stop.fill")
            endConfig.imagePlacement = .leading
            endConfig.imagePadding = 6
            endConfig.baseBackgroundColor = .systemOrange
            endConfig.baseForegroundColor = .white
            endConfig.cornerStyle = .capsule
            startTripButton.configuration = endConfig
            startTripButton.isHidden = false
        default:
            startTripButton.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction func viewRequestsTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapViewRequests(self)
    }

    @objc private func pendingBadgeTapped() {
        delegate?.upcomingCellDidTapViewRequests(self)
    }

    @IBAction func toggleMap(_ sender: UIButton) {
        isMapExpanded.toggle()
        mapView.isHidden = !isMapExpanded
        mapHeightConstraint.constant = isMapExpanded ? 180 : 1
        var config = sender.configuration ?? UIButton.Configuration.tinted()
        config.title = isMapExpanded ? "Hide" : "Map"
        config.image = UIImage(systemName: isMapExpanded ? "map.fill" : "map")
        sender.configuration = config
        delegate?.upcomingCellRequestsToggled(self)
    }

    @IBAction func messageTapped(_ sender: UIButton)    { delegate?.upcomingCellDidTapMessage(self) }
    @IBAction func callTapped(_ sender: UIButton)       { delegate?.upcomingCellDidTapCall(self) }
    @IBAction func cancelRideTapped(_ sender: UIButton) { delegate?.upcomingCellDidTapCancelRide(self) }
    @IBAction func startTripTapped(_ sender: UIButton) {
        guard let trip = trip else { return }
        if trip.ride.status == .published {
            delegate?.upcomingCellDidTapStartTrip(self)
        } else if trip.ride.status == .ongoing {
            delegate?.upcomingCellDidTapEndTrip(self)
        }
    }

    // MARK: - Route Drawing

    private func drawRouteIfNeeded(for ride: Ride) {
        mapView.removeOverlays(mapView.overlays)
        guard let route = ride.selectedRoute else { return }
        let coords = route.coordinates.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        guard coords.count > 1 else { return }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30),
                                  animated: false)
    }

    // MARK: - Badge Styling

    private func applyBadgeStyle(to label: UILabel, backgroundColor: UIColor, textColor: UIColor) {
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.font = AppDesign.Typography.captionStrong
        label.layer.cornerRadius = AppDesign.Radius.sm
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
            avatarView.backgroundColor = .systemGray5
            avatarView.isUserInteractionEnabled = true

            if i < passengers.count {
                let passenger = passengers[i]
                let initial = String(passenger.fullName.prefix(1)).uppercased()
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
                label.text = initial
                label.textAlignment = .center
                label.font = AppDesign.Typography.bodyStrong
                label.textColor = .systemGray
                avatarView.addSubview(label)

                if let url = passenger.photoURL {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async { avatarView.image = img; label.removeFromSuperview() }
                        }
                    }.resume()
                }

                avatarView.tag = i
                avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:))))
            } else {
                let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
                avatarView.image = UIImage(systemName: "person.fill", withConfiguration: config)
                avatarView.tintColor = .systemGray3
                avatarView.contentMode = .center
            }

            avatarStackView.addSubview(avatarView)
        }
    }

    @objc private func avatarTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view,
              tappedView.tag < approvedPassengers.count,
              let ride = trip?.ride else { return }
        delegate?.upcomingCellDidTapPassenger(self, passenger: approvedPassengers[tappedView.tag], ride: ride)
    }
}



// MARK: - Map Renderer

extension UpcomingTableViewCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        r.strokeColor = AppDesign.Color.primary
        r.lineWidth = 4
        return r
    }
}

// MARK: - Unread Badge Helper

extension UpcomingTableViewCell {

    /// Attaches a red pill badge to the top-right corner of any button.
    /// Pass count = 0 to hide the badge.
    func applyUnreadBadge(to button: UIButton, rideID: String) {
        let tag = 9901
        // Remove stale badge from recycled cell
        button.subviews.first(where: { $0.tag == tag })?.removeFromSuperview()

        let count = ChatDataModel.shared.unreadCount(for: rideID)
        guard count > 0 else { return }

        let badge = UILabel()
        badge.tag = tag
        badge.text = count > 99 ? "99+" : "\(count)"
        badge.font = AppDesign.Typography.captionStrong.withSize(10)
        badge.textColor = .white
        badge.backgroundColor = AppDesign.Color.destructive
        badge.textAlignment = .center
        badge.layer.cornerRadius = 9
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: button.topAnchor, constant: -5),
            badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 5),
            badge.heightAnchor.constraint(equalToConstant: 18),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])
    }
}
