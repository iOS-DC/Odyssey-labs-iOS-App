import UIKit
import MapKit

protocol UpcomingPassengerCellDelegate: AnyObject {
    func passengerCellDidTapDriver(_ cell: UpcomingPassengerTableViewCell, driver: UserProfile, ride: Ride)
}

final class UpcomingPassengerTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rideStatusLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var requestStatusLabel: UILabel!
    @IBOutlet weak var hostImageView: UIImageView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!

    // MARK: - Programmatic map & button (inserted into XIB layout)
    private let mapView = MKMapView()
    private let showMapButton = UIButton(type: .system)
    private var mapHeightConstraint: NSLayoutConstraint!
    private var cancelTopConstraint: NSLayoutConstraint!     // replaces XIB's constraint
    private var isMapExpanded = false
    private var driverHitArea: UIView?

    weak var delegate: UpcomingPassengerCellDelegate?
    private var currentTrip: RideDataModel.MyTrip?

    // MARK: – Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor            = .clear
        contentView.backgroundColor = .clear
        selectionStyle             = .none
        cardView.applyCardStyle(
            corner:         AppDesign.Radius.lg,
            shadowOpacity:  AppDesign.Shadow.smallCardOpacity,
            shadowRadius:   AppDesign.Shadow.smallCardRadius,
            shadowOffset:   AppDesign.Shadow.smallCardOffset
        )
        hostImageView.clipsToBounds = true

        insertMapButton()
        insertMapView()
        addDriverTapGesture()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
        mapView.layer.cornerRadius = 10
        mapView.clipsToBounds      = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if isMapExpanded { collapseMap(animated: false) }
        mapView.removeOverlays(mapView.overlays)
    }

    // MARK: – Map button insertion

    private func insertMapButton() {
        // Insert "Map" button as first item in the existing XIB button stack
        guard let btnStack = messageButton.superview as? UIStackView else { return }
        showMapButton.applyTintActionStyle(title: "Map", imageSystemName: "map")
        showMapButton.addTarget(self, action: #selector(toggleMap), for: .touchUpInside)
        btnStack.insertArrangedSubview(showMapButton, at: 0)
    }

    private func insertMapView() {
        // Find the XIB constraint tying cancelRequestButton.top to the button stack bottom
        // and replace it so we can insert the map view between them.
        guard let btnStack = messageButton.superview else { return }

        // Deactivate existed XIB constraint: cancelRequestButton.top = btnStack.bottom + 12
        let oldConstraint = cardView.constraints.first {
            ($0.firstItem  as? UIView == cancelRequestButton && $0.firstAttribute == .top) ||
            ($0.secondItem as? UIView == cancelRequestButton && $0.secondAttribute == .top)
        }
        oldConstraint?.isActive = false

        // Map view
        mapView.isHidden        = true
        mapView.showsUserLocation = true   // standard iOS blue dot for passenger's location
        mapView.delegate        = self
        mapView.layer.cornerRadius = 10
        mapView.clipsToBounds   = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mapView)

        mapHeightConstraint = mapView.heightAnchor.constraint(equalToConstant: 0)
        cancelTopConstraint = cancelRequestButton.topAnchor.constraint(
            equalTo: mapView.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            // Map pinned below button stack
            mapView.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            mapView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            mapHeightConstraint,
            // Cancel button now hangs off map bottom
            cancelTopConstraint,
        ])
    }

    private func addDriverTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(driverRowTapped))
        let hitArea = UIView()
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        hitArea.isUserInteractionEnabled = true
        hitArea.backgroundColor = .clear
        cardView.addSubview(hitArea)
        NSLayoutConstraint.activate([
            hitArea.topAnchor.constraint(equalTo: hostImageView.topAnchor, constant: -4),
            hitArea.leadingAnchor.constraint(equalTo: hostImageView.leadingAnchor, constant: -4),
            hitArea.bottomAnchor.constraint(equalTo: hostImageView.bottomAnchor, constant: 4),
            hitArea.trailingAnchor.constraint(equalTo: hostNameLabel.trailingAnchor, constant: 4),
        ])
        hitArea.addGestureRecognizer(tap)
        self.driverHitArea = hitArea
    }

    // MARK: – Configure

    func configure(with trip: RideDataModel.MyTrip) {
        currentTrip = trip
        let ride = trip.ride

        // Date
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        dateLabel.text = df.string(from: ride.departureTime)

        // Times
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)
        let travelSeconds = ride.selectedRoute?.expectedTravelTime ?? (2 * 3600)
        endTimeLabel.text  = tf.string(from: ride.departureTime.addingTimeInterval(travelSeconds))
        durationLabel.text = formatDuration(travelSeconds)

        // Route labels
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text   = ride.destination.address ?? "To"

        // Seat count
        seatsLabel.text = "\(ride.seatsTotal - ride.seatsAvailable)/\(ride.seatsTotal) seats"

        rideStatusLabel.isHidden = true

        // Role badge
        roleLabel.text            = "  Passenger  "
        roleLabel.backgroundColor = .systemGray6
        roleLabel.textColor       = .secondaryLabel
        roleLabel.font            = AppDesign.Typography.captionStrong
        roleLabel.layer.cornerRadius  = AppDesign.Radius.sm
        roleLabel.layer.masksToBounds = true

        // Request / booking status badge
        let isConfirmed: Bool
        if let status = trip.requestStatus {
            isConfirmed = (status == .approved)
        } else {
            let me = UserDataModel.shared.getCurrentUser()
            let bookings = RideDataModel.shared.listBookings(for: ride.id)
            isConfirmed = me != nil && bookings.contains { $0.passengerUserID == me!.id && $0.status == .confirmed }
        }

        let cancelTitle: String
        if isConfirmed {
            if ride.status == .ongoing {
                requestStatusLabel.text            = "  Trip Started  "
                requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                requestStatusLabel.textColor       = .white
                cancelTitle = "Cancel Booking"
                cancelRequestButton.isEnabled = false
                cancelRequestButton.alpha     = 0.4
            } else {
                requestStatusLabel.text            = "  ✓ Confirmed  "
                requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                requestStatusLabel.textColor       = .white
                cancelTitle = "Cancel Booking"
                cancelRequestButton.isEnabled = true
                cancelRequestButton.alpha     = 1.0
            }
        } else {
            let (text, color): (String, UIColor) = {
                switch trip.requestStatus {
                case .pending:   return ("  Pending  ",   UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0))
                case .denied:    return ("  Denied  ",    UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0))
                case .cancelled: return ("  Cancelled  ", UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0))
                default:         return ("  Pending  ",   UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0))
                }
            }()
            requestStatusLabel.text            = text
            requestStatusLabel.backgroundColor = color
            requestStatusLabel.textColor       = .white
            cancelTitle = "Cancel Request"
        }
        requestStatusLabel.font                   = AppDesign.Typography.captionStrong
        requestStatusLabel.layer.cornerRadius     = AppDesign.Radius.sm
        requestStatusLabel.layer.masksToBounds    = true
        requestStatusLabel.textAlignment          = .center

        // Host info
        configureHostInfo(driverID: ride.driverUserID)

        // Button styles
        messageButton.applyTintActionStyle(title: "Chat", imageSystemName: "message.fill")
        applyUnreadBadge(to: messageButton, rideID: ride.id.uuidString)
        showMapButton.applyTintActionStyle(title: isMapExpanded ? "Hide" : "Map",
                                          imageSystemName: isMapExpanded ? "map.fill" : "map")
        cancelRequestButton.applyTintActionStyle(title: cancelTitle, color: AppDesign.Color.destructive)

        // Draw route on map
        drawRouteIfNeeded(for: ride)

        // Ensure hit area is above labels/images
        if let ha = driverHitArea { cardView.bringSubviewToFront(ha) }
    }

    // MARK: – Map

    @objc private func toggleMap(_ sender: UIButton) {
        if isMapExpanded { collapseMap(animated: true) } else { expandMap(animated: true) }
    }

    private func expandMap(animated: Bool) {
        isMapExpanded = true
        mapView.isHidden = false
        mapHeightConstraint.constant = 180
        showMapButton.applyTintActionStyle(title: "Hide", imageSystemName: "map.fill")
        animateIfNeeded(animated)
    }

    private func collapseMap(animated: Bool) {
        isMapExpanded = false
        mapHeightConstraint.constant = 0
        showMapButton.applyTintActionStyle(title: "Map", imageSystemName: "map")
        animateIfNeeded(animated) { [weak self] in
            self?.mapView.isHidden = true
        }
    }

    private func animateIfNeeded(_ animated: Bool, completion: (() -> Void)? = nil) {
        // Tell tableView to recalculate this row's height
        func updateTableHeight() {
            var v: UIView? = superview
            while let current = v {
                if let tv = current as? UITableView {
                    tv.beginUpdates()
                    tv.endUpdates()
                    return
                }
                v = current.superview
            }
        }

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.superview?.layoutIfNeeded()
                updateTableHeight()
            } completion: { _ in completion?() }
        } else {
            completion?()
            updateTableHeight()
        }
    }

    private func drawRouteIfNeeded(for ride: Ride) {
        mapView.removeOverlays(mapView.overlays)
        guard let route = ride.selectedRoute else { return }
        let coords = route.coordinates.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        guard coords.count > 1 else { return }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
                                  animated: false)
    }

    // MARK: – Helpers

    private func configureHostInfo(driverID: UUID) {
        let host = currentTrip?.ride.driverProfile ?? UserDataModel.shared.getUser(by: driverID)
        let name = host?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let display = name.isEmpty ? (host?.email ?? "Driver") : name

        hostNameLabel.text      = display
        hostNameLabel.font      = AppDesign.Typography.subheadline
        hostNameLabel.textColor = .label
        hostImageView.loadAndFallback(from: host?.photoURL, name: display)
    }

    @objc private func driverRowTapped() {
        guard let trip = currentTrip else { return }
        let driver = trip.ride.driverProfile ?? UserDataModel.shared.getUser(by: trip.ride.driverUserID)
        guard let validDriver = driver else { return }
        delegate?.passengerCellDidTapDriver(self, driver: validDriver, ride: trip.ride)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(round(seconds / 60.0))
        let h = totalMinutes / 60, m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        else if h > 0      { return "\(h)h" }
        else               { return "\(m)m" }
    }

    private func applyUnreadBadge(to button: UIButton, rideID: String) {
        let tag = 9901
        button.subviews.first(where: { $0.tag == tag })?.removeFromSuperview()
        let count = ChatDataModel.shared.unreadCount(for: rideID)
        guard count > 0 else { return }
        let badge = UILabel()
        badge.tag  = tag
        badge.text = count > 99 ? "99+" : "\(count)"
        badge.font = AppDesign.Typography.captionStrong.withSize(10)
        badge.textColor       = .white
        badge.backgroundColor = AppDesign.Color.destructive
        badge.textAlignment   = .center
        badge.layer.cornerRadius  = 9
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

// MARK: – MKMapViewDelegate
extension UpcomingPassengerTableViewCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        r.strokeColor = AppDesign.Color.primary
        r.lineWidth   = 4
        return r
    }
}
