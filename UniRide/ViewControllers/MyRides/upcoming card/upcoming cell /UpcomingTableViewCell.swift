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
    func upcomingCellDidTapTrackLiveRide(_ cell: UpcomingTableViewCell)
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

    // Programmatic "Track Live" button — shown only when ride is ongoing
    private let trackLiveButton = UIButton(type: .system)

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
        roleLabel.adjustsFontSizeToFitWidth = true
        roleLabel.minimumScaleFactor = 0.8
        statusLabel.applyTextStyle(AppDesign.Typography.captionStrong)
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.8
        dateLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.8
        fromLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        fromLabel.lineBreakMode = .byWordWrapping
        toLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        toLabel.lineBreakMode = .byWordWrapping
        startTimeLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        endTimeLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        durationLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        passengersLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        passengersLabel.numberOfLines = 0
        seatsLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        seatsLabel.adjustsFontSizeToFitWidth = true
        seatsLabel.minimumScaleFactor = 0.8

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

        // "Track Live" button — sits to the left of startTripButton, hidden until ride is ongoing
        var trackCfg = UIButton.Configuration.tinted()
        trackCfg.title             = "Track Live"
        trackCfg.image             = UIImage(systemName: "location.fill")
        trackCfg.imagePadding      = 6
        trackCfg.imagePlacement    = .leading
        trackCfg.baseBackgroundColor = AppDesign.Color.primary
        trackCfg.baseForegroundColor = AppDesign.Color.primary
        trackCfg.cornerStyle       = .capsule
        trackLiveButton.configuration = trackCfg
        trackLiveButton.isHidden   = true
        trackLiveButton.translatesAutoresizingMaskIntoConstraints = false
        trackLiveButton.addTarget(self, action: #selector(trackLiveTapped), for: .touchUpInside)
        cardView.addSubview(trackLiveButton)
        NSLayoutConstraint.activate([
            trackLiveButton.centerYAnchor.constraint(equalTo: startTripButton.centerYAnchor),
            trackLiveButton.trailingAnchor.constraint(equalTo: startTripButton.leadingAnchor, constant: -10),
            trackLiveButton.heightAnchor.constraint(equalTo: startTripButton.heightAnchor),
        ])
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
        trackLiveButton.isHidden = true

        avatarStackView.subviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        self.trip = trip
        let ride = trip.ride
        let lifecycle = RideLifecycle.presentation(for: trip)

        // Role badge
        roleLabel.text = "  Driving  "
        applyBadgeStyle(to: roleLabel, backgroundColor: AppDesign.Color.surfaceElevated, textColor: AppDesign.Color.textSecondary)

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

        statusLabel.text = "  \(lifecycle.title)  "
        applyBadgeStyle(to: statusLabel, backgroundColor: lifecycle.color, textColor: .white)

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
            .compactMap { $0.passengerProfile ?? UserDataModel.shared.getUser(by: $0.passengerUserID) }

        passengersLabel.text = "Passengers: \(approvedPassengers.count) / \(ride.seatsTotal)\nNext: \(lifecycle.nextStep)"
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
        // High visibility size increase
        messageButton.configuration?.buttonSize = .large
        messageButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        
        // ── Unread badge on Chat button ──
        let rideIDStr = trip.ride.id.uuidString
        applyUnreadBadge(to: messageButton, rideID: rideIDStr)

        // Remote Call button as requested
        callButton.isHidden = true
        
        showMapButton.applyTintActionStyle(
            title: isMapExpanded ? "Hide Map" : "View Map",
            imageSystemName: isMapExpanded ? "map.fill" : "map"
        )
        showMapButton.configuration?.buttonSize = .large
        showMapButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)

        // Start / End Trip button
        startTripButton.backgroundColor = .clear
        switch ride.status {
        case .published:
            var startConfig = UIButton.Configuration.filled()
            startConfig.title = lifecycle.actionTitle ?? "Start Ride"
            startConfig.image = UIImage(systemName: "play.fill")
            startConfig.imagePlacement = .leading
            startConfig.imagePadding = 6
            startConfig.baseBackgroundColor = AppDesign.Color.success
            startConfig.baseForegroundColor = .white
            startConfig.cornerStyle = .capsule
            startTripButton.configuration = startConfig
            startTripButton.isHidden = false
            trackLiveButton.isHidden = true
        case .ongoing:
            var endConfig = UIButton.Configuration.filled()
            endConfig.title = lifecycle.actionTitle ?? "End Ride"
            endConfig.image = UIImage(systemName: "stop.fill")
            endConfig.imagePlacement = .leading
            endConfig.imagePadding = 6
            endConfig.baseBackgroundColor = .systemOrange
            endConfig.baseForegroundColor = .white
            endConfig.cornerStyle = .capsule
            startTripButton.configuration = endConfig
            startTripButton.isHidden = false
            trackLiveButton.isHidden = false     // ← show "Track Live" while ride is in progress
        default:
            startTripButton.isHidden = true
            trackLiveButton.isHidden = true
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
        config.title = isMapExpanded ? "Hide Map" : "View Map"
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

    @objc private func trackLiveTapped() {
        delegate?.upcomingCellDidTapTrackLiveRide(self)
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
            avatarView.backgroundColor = AppDesign.Color.borderSubtle
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
                avatarView.tintColor = AppDesign.Color.textTertiary
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
