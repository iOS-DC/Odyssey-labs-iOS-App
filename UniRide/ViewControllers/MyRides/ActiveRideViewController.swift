// ActiveRideViewController.swift
// UniRide
//
// Full-screen live-tracking map shown to both the driver and passengers
// once a ride is started.  Mirrors the Uber/Ola tracking experience.
//
// Driver  → sees their own position (blue dot), route to destination, "End Ride".
// Passenger → sees the driver's animated car pin moving in real-time, ETA, "Close".

import UIKit
import MapKit
import CoreLocation

// MARK: - DriverAnnotation

/// A KVO-compliant MKAnnotation whose coordinate can be set to animate
/// the car pin smoothly across the map.
final class DriverAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { "Your Driver" }

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - ActiveRideViewController

final class ActiveRideViewController: UIViewController {

    // MARK: - Mode

    enum Mode {
        case driver(ride: Ride, passengers: [UserProfile])
        case passenger(ride: Ride, driver: UserProfile?)
    }

    // MARK: - Public config

    var mode: Mode!
    /// Called after the driver successfully ends the ride.
    var onRideEnded: (() -> Void)?

    // MARK: - Factory

    static func make(mode: Mode, onRideEnded: (() -> Void)? = nil) -> ActiveRideViewController {
        let vc = ActiveRideViewController()
        vc.mode = mode
        vc.onRideEnded = onRideEnded
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        return vc
    }

    // MARK: - Map

    private let mapView = MKMapView()
    private var driverAnnotation: DriverAnnotation?
    private var routeOverlay: MKPolyline?
    private var hasSetInitialRegion = false

    // MARK: - Top bar

    private let closeButton = UIButton(type: .system)
    private let titleChip   = UILabel()
    private let recenterBtn = UIButton(type: .system)

    // MARK: - Bottom card

    private let bottomCard  = UIView()
    private let blurView    = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let grabber     = UIView()

    // Shared labels
    private let routeFromLabel = UILabel()
    private let routeArrow     = UILabel()
    private let routeToLabel   = UILabel()

    // Driver-only
    private let passengerInfoLabel = UILabel()
    private let endRideButton      = UIButton()

    // Passenger-only
    private let driverCard      = UIView()
    private let driverAvatar    = UIImageView()
    private let driverNameLabel = UILabel()
    private let vehicleLabel    = UILabel()
    private let statusLabel     = UILabel()
    private let etaLabel        = UILabel()
    private let closeBigButton  = UIButton()

    // MARK: - Internal state

    private var rideStatusPollTimer: Timer?

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Lifecycle
    // ─────────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMap()
        setupTopBar()
        setupBottomCard()
        populateStaticInfo()
        drawRoutePolyline()
        startTracking()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasSetInitialRegion else { return }
        hasSetInitialRegion = true
        setInitialMapRegion()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTracking()
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Setup: Map
    // ─────────────────────────────────────────────────────────────────

    private func setupMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate            = self
        mapView.showsUserLocation   = true
        mapView.showsCompass        = false
        mapView.showsScale          = false
        mapView.pointOfInterestFilter = .excludingAll
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // In driver mode set userTracking so the map follows the driver's blue dot
        if case .driver = mode {
            mapView.userTrackingMode = .follow
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Setup: Top bar
    // ─────────────────────────────────────────────────────────────────

    private func setupTopBar() {
        // Close / back button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let symCfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: symCfg), for: .normal)
        closeButton.tintColor = .label
        closeButton.backgroundColor = .systemBackground.withAlphaComponent(0.88)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.shadowColor  = UIColor.black.cgColor
        closeButton.layer.shadowOpacity = 0.12
        closeButton.layer.shadowOffset  = CGSize(width: 0, height: 2)
        closeButton.layer.shadowRadius  = 4
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // "Live" status chip
        titleChip.translatesAutoresizingMaskIntoConstraints = false
        titleChip.text = modeTitleText
        titleChip.font = AppDesign.Typography.captionStrong
        titleChip.textColor = .white
        titleChip.backgroundColor = AppDesign.Color.primary
        titleChip.layer.cornerRadius = 12
        titleChip.layer.masksToBounds = true
        titleChip.textAlignment = .center
        view.addSubview(titleChip)

        // Re-center button
        recenterBtn.translatesAutoresizingMaskIntoConstraints = false
        recenterBtn.setImage(UIImage(systemName: "location.fill", withConfiguration: symCfg), for: .normal)
        recenterBtn.tintColor = AppDesign.Color.primary
        recenterBtn.backgroundColor = .systemBackground.withAlphaComponent(0.88)
        recenterBtn.layer.cornerRadius = 18
        recenterBtn.layer.shadowColor  = UIColor.black.cgColor
        recenterBtn.layer.shadowOpacity = 0.12
        recenterBtn.layer.shadowOffset  = CGSize(width: 0, height: 2)
        recenterBtn.layer.shadowRadius  = 4
        recenterBtn.addTarget(self, action: #selector(recenterTapped), for: .touchUpInside)
        view.addSubview(recenterBtn)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            titleChip.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleChip.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleChip.heightAnchor.constraint(equalToConstant: 28),

            recenterBtn.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            recenterBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            recenterBtn.widthAnchor.constraint(equalToConstant: 36),
            recenterBtn.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Setup: Bottom card
    // ─────────────────────────────────────────────────────────────────

    private func setupBottomCard() {
        bottomCard.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.layer.cornerRadius = 24
        bottomCard.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomCard.layer.shadowColor   = UIColor.black.cgColor
        bottomCard.layer.shadowOpacity = 0.18
        bottomCard.layer.shadowOffset  = CGSize(width: 0, height: -4)
        bottomCard.layer.shadowRadius  = 12
        bottomCard.clipsToBounds = true
        view.addSubview(bottomCard)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: bottomCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomCard.bottomAnchor),
        ])

        // Grabber
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.backgroundColor     = UIColor.systemGray4
        grabber.layer.cornerRadius  = 2.5
        bottomCard.addSubview(grabber)

        switch mode! {
        case .driver: buildDriverPanel()
        case .passenger: buildPassengerPanel()
        }

        let cardHeight: CGFloat
        if case .driver = mode { cardHeight = 230 } else { cardHeight = 220 }

        NSLayoutConstraint.activate([
            bottomCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomCard.heightAnchor.constraint(equalToConstant: cardHeight),

            grabber.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: bottomCard.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),
        ])

        // Push map content up so it isn't hidden behind card
        mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: cardHeight - 80, right: 0)
    }

    private func buildDriverPanel() {
        // Route row
        let routeRow = makeRouteRow()
        routeRow.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(routeRow)

        // Passenger info chip
        passengerInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        passengerInfoLabel.font      = AppDesign.Typography.caption
        passengerInfoLabel.textColor = .secondaryLabel
        bottomCard.addSubview(passengerInfoLabel)

        // End Ride button
        endRideButton.translatesAutoresizingMaskIntoConstraints = false
        var cfg = UIButton.Configuration.filled()
        cfg.title              = "End Ride"
        cfg.image              = UIImage(systemName: "flag.checkered")
        cfg.imagePadding       = 8
        cfg.baseBackgroundColor = AppDesign.Color.destructive
        cfg.baseForegroundColor = .white
        cfg.cornerStyle        = .capsule
        endRideButton.configuration = cfg
        endRideButton.addTarget(self, action: #selector(endRideTapped), for: .touchUpInside)
        endRideButton.applyPressMicroInteraction()
        bottomCard.addSubview(endRideButton)

        NSLayoutConstraint.activate([
            routeRow.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 14),
            routeRow.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),
            routeRow.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -20),

            passengerInfoLabel.topAnchor.constraint(equalTo: routeRow.bottomAnchor, constant: 8),
            passengerInfoLabel.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),

            endRideButton.topAnchor.constraint(equalTo: passengerInfoLabel.bottomAnchor, constant: 14),
            endRideButton.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),
            endRideButton.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -20),
            endRideButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func buildPassengerPanel() {
        // Driver info row
        driverAvatar.translatesAutoresizingMaskIntoConstraints = false
        driverAvatar.layer.cornerRadius = 22
        driverAvatar.clipsToBounds      = true
        driverAvatar.backgroundColor    = AppDesign.Color.fieldBackground
        driverAvatar.contentMode        = .scaleAspectFill
        driverAvatar.layer.borderWidth  = 2
        driverAvatar.layer.borderColor  = AppDesign.Color.primary.withAlphaComponent(0.4).cgColor
        bottomCard.addSubview(driverAvatar)

        driverNameLabel.translatesAutoresizingMaskIntoConstraints = false
        driverNameLabel.font      = AppDesign.Typography.bodyStrong
        driverNameLabel.textColor = .label
        bottomCard.addSubview(driverNameLabel)

        vehicleLabel.translatesAutoresizingMaskIntoConstraints = false
        vehicleLabel.font      = AppDesign.Typography.caption
        vehicleLabel.textColor = .secondaryLabel
        bottomCard.addSubview(vehicleLabel)

        // Status + ETA row
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font      = AppDesign.Typography.captionStrong
        statusLabel.textColor = AppDesign.Color.primary
        statusLabel.text      = "Driver is on the way…"
        bottomCard.addSubview(statusLabel)

        etaLabel.translatesAutoresizingMaskIntoConstraints = false
        etaLabel.font      = AppDesign.Typography.captionStrong
        etaLabel.textColor = .secondaryLabel
        bottomCard.addSubview(etaLabel)

        // Route row
        let routeRow = makeRouteRow()
        routeRow.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(routeRow)

        // Close button
        closeBigButton.translatesAutoresizingMaskIntoConstraints = false
        var cfg = UIButton.Configuration.filled()
        cfg.title              = "Close"
        cfg.baseBackgroundColor = UIColor.systemGray5
        cfg.baseForegroundColor = .label
        cfg.cornerStyle        = .capsule
        closeBigButton.configuration = cfg
        closeBigButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBigButton.applyPressMicroInteraction()
        bottomCard.addSubview(closeBigButton)

        NSLayoutConstraint.activate([
            driverAvatar.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 14),
            driverAvatar.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),
            driverAvatar.widthAnchor.constraint(equalToConstant: 44),
            driverAvatar.heightAnchor.constraint(equalToConstant: 44),

            driverNameLabel.topAnchor.constraint(equalTo: driverAvatar.topAnchor, constant: 2),
            driverNameLabel.leadingAnchor.constraint(equalTo: driverAvatar.trailingAnchor, constant: 12),
            driverNameLabel.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16),

            vehicleLabel.topAnchor.constraint(equalTo: driverNameLabel.bottomAnchor, constant: 2),
            vehicleLabel.leadingAnchor.constraint(equalTo: driverNameLabel.leadingAnchor),

            statusLabel.topAnchor.constraint(equalTo: driverAvatar.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),

            etaLabel.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            etaLabel.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -20),

            routeRow.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            routeRow.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),
            routeRow.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -20),

            closeBigButton.topAnchor.constraint(equalTo: routeRow.bottomAnchor, constant: 12),
            closeBigButton.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 20),
            closeBigButton.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -20),
            closeBigButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    /// Compact "From → To" label row used in both panels.
    private func makeRouteRow() -> UIStackView {
        routeFromLabel.font      = AppDesign.Typography.captionStrong
        routeFromLabel.textColor = .secondaryLabel
        routeFromLabel.numberOfLines = 1
        routeFromLabel.lineBreakMode = .byTruncatingTail

        routeArrow.text      = " → "
        routeArrow.font      = AppDesign.Typography.caption
        routeArrow.textColor = .tertiaryLabel

        routeToLabel.font      = AppDesign.Typography.captionStrong
        routeToLabel.textColor = .label
        routeToLabel.numberOfLines = 1
        routeToLabel.lineBreakMode = .byTruncatingTail
        routeToLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [routeFromLabel, routeArrow, routeToLabel])
        stack.axis    = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        return stack
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Populate static content from mode
    // ─────────────────────────────────────────────────────────────────

    private func populateStaticInfo() {
        switch mode! {

        case .driver(let ride, let passengers):
            routeFromLabel.text = ride.source.address      ?? "Pickup"
            routeToLabel.text   = ride.destination.address ?? "Destination"
            let count = passengers.count
            passengerInfoLabel.text = count == 0
                ? "No confirmed passengers yet"
                : "\(count) passenger\(count == 1 ? "" : "s") on board"

        case .passenger(let ride, let driver):
            routeFromLabel.text = ride.source.address      ?? "Pickup"
            routeToLabel.text   = ride.destination.address ?? "Destination"

            // Driver info
            let first = driver?.fullName.components(separatedBy: " ").first ?? "Driver"
            driverNameLabel.text = driver?.fullName ?? "Your Driver"
            vehicleLabel.text    = [ride.vehicleModel, ride.registrationPlate]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            if vehicleLabel.text?.isEmpty == true { vehicleLabel.text = "Vehicle details not available" }

            if let url = driver?.photoURL {
                URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                    if let data, let img = UIImage(data: data) {
                        DispatchQueue.main.async { self?.driverAvatar.image = img }
                    }
                }.resume()
            } else {
                let initLabel = UILabel()
                initLabel.text          = String(first.prefix(1))
                initLabel.font          = AppDesign.Typography.bodyStrong
                initLabel.textColor     = AppDesign.Color.primary
                initLabel.textAlignment = .center
                initLabel.translatesAutoresizingMaskIntoConstraints = false
                driverAvatar.addSubview(initLabel)
                NSLayoutConstraint.activate([
                    initLabel.centerXAnchor.constraint(equalTo: driverAvatar.centerXAnchor),
                    initLabel.centerYAnchor.constraint(equalTo: driverAvatar.centerYAnchor),
                ])
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Map region
    // ─────────────────────────────────────────────────────────────────

    private func setInitialMapRegion() {
        let ride: Ride
        switch mode! {
        case .driver(let r, _):    ride = r
        case .passenger(let r, _): ride = r
        }
        var coords = [
            CLLocationCoordinate2D(latitude: ride.source.lat,      longitude: ride.source.lon),
            CLLocationCoordinate2D(latitude: ride.destination.lat,  longitude: ride.destination.lon),
        ]
        if let userLoc = mapView.userLocation.location {
            coords.append(userLoc.coordinate)
        }
        fitMapToCoordinates(coords, animated: false)
    }

    private func fitMapToCoordinates(_ coords: [CLLocationCoordinate2D], animated: Bool) {
        guard !coords.isEmpty else { return }
        var region = MKCoordinateRegion(
            center: coords[0],
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        var minLat =  90.0, maxLat = -90.0, minLon =  180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let padding = 0.01
        region.center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                               longitude: (minLon + maxLon) / 2)
        region.span   = MKCoordinateSpan(latitudeDelta:  (maxLat - minLat) + padding * 2,
                                         longitudeDelta: (maxLon - minLon) + padding * 2)
        mapView.setRegion(region, animated: animated)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Route polyline
    // ─────────────────────────────────────────────────────────────────

    private func drawRoutePolyline() {
        let ride: Ride
        switch mode! {
        case .driver(let r, _):    ride = r
        case .passenger(let r, _): ride = r
        }

        // Use pre-calculated route if available
        if let coords = ride.selectedRoute?.coordinates, coords.count >= 2 {
            let clCoords = coords.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
            addPolyline(clCoords)
            return
        }

        // Fallback: ask MapKit to calculate the route
        let src = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon))
        let dst = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: ride.destination.lat, longitude: ride.destination.lon))
        let req = MKDirections.Request()
        req.source      = MKMapItem(placemark: src)
        req.destination = MKMapItem(placemark: dst)
        req.transportType = .automobile
        MKDirections(request: req).calculate { [weak self] response, _ in
            guard let route = response?.routes.first else { return }
            DispatchQueue.main.async {
                self?.addPolyline(route.polyline.coordinates)
            }
        }
    }

    private func addPolyline(_ coords: [CLLocationCoordinate2D]) {
        if let old = routeOverlay { mapView.removeOverlay(old) }
        let poly = MKPolyline(coordinates: coords, count: coords.count)
        routeOverlay = poly
        mapView.addOverlay(poly, level: .aboveRoads)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Destination / Pickup pins
    // ─────────────────────────────────────────────────────────────────

    private func addDestinationPin(for ride: Ride) {
        let ann = MKPointAnnotation()
        ann.coordinate = CLLocationCoordinate2D(latitude: ride.destination.lat, longitude: ride.destination.lon)
        ann.title = ride.destination.address ?? "Destination"
        mapView.addAnnotation(ann)
    }

    private func addPickupPin(for ride: Ride) {
        let ann = MKPointAnnotation()
        ann.coordinate = CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon)
        ann.title = ride.source.address ?? "Pickup"
        mapView.addAnnotation(ann)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Tracking start / stop
    // ─────────────────────────────────────────────────────────────────

    private func startTracking() {
        switch mode! {

        case .driver(let ride, _):
            addDestinationPin(for: ride)
            RideTrackingService.shared.startBroadcasting(for: ride.id)

        case .passenger(let ride, _):
            addPickupPin(for: ride)
            addDestinationPin(for: ride)

            // Add the car annotation at the source until first location arrives
            let initial = CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon)
            let ann = DriverAnnotation(coordinate: initial)
            driverAnnotation = ann
            mapView.addAnnotation(ann)

            RideTrackingService.shared.subscribeToDriverLocation(rideID: ride.id)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleDriverLocationUpdate(_:)),
                name: .rideDriverLocationDidUpdate, object: nil)

            startRideStatusPolling(rideID: ride.id)
        }
    }

    private func stopTracking() {
        NotificationCenter.default.removeObserver(self, name: .rideDriverLocationDidUpdate, object: nil)
        rideStatusPollTimer?.invalidate()
        rideStatusPollTimer = nil

        switch mode! {
        case .driver:
            RideTrackingService.shared.stopBroadcasting()
        case .passenger:
            RideTrackingService.shared.unsubscribeFromDriverLocation()
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Driver location updates (passenger side)
    // ─────────────────────────────────────────────────────────────────

    @objc private func handleDriverLocationUpdate(_ notification: Notification) {
        guard let value = notification.userInfo?["coordinate"] as? NSValue else { return }
        let coord = value.mkCoordinateValue

        UIView.animate(withDuration: 3.5, delay: 0,
                       options: [.curveLinear, .beginFromCurrentState]) { [weak self] in
            self?.driverAnnotation?.coordinate = coord
        }

        // Update ETA from driver's new position to the pickup point
        if case .passenger(let ride, _) = mode {
            calculateETA(from: coord,
                         to: CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon))
        }
    }

    private func calculateETA(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let req = MKDirections.Request()
        req.source      = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        req.transportType = .automobile
        req.requestsAlternateRoutes = false
        MKDirections(request: req).calculate { [weak self] response, _ in
            guard let travel = response?.routes.first?.expectedTravelTime else { return }
            let mins = Int(ceil(travel / 60))
            DispatchQueue.main.async {
                if mins <= 1 {
                    self?.statusLabel.text = "Driver is very close!"
                    self?.etaLabel.text    = "< 1 min"
                } else {
                    self?.statusLabel.text = "Driver is on the way…"
                    self?.etaLabel.text    = "~\(mins) min away"
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Ride status polling (detect when driver ends ride)
    // ─────────────────────────────────────────────────────────────────

    private func startRideStatusPolling(rideID: UUID) {
        rideStatusPollTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task {
                guard let ride = try? await RideRepository.shared.fetchRide(id: rideID) else { return }
                if ride.status == .completed || ride.status == .cancelled {
                    await MainActor.run {
                        self?.showRideEndedBanner()
                    }
                }
            }
        }
    }

    private func showRideEndedBanner() {
        rideStatusPollTimer?.invalidate()
        let alert = UIAlertController(
            title: "Ride Completed",
            message: "Your driver has ended the ride. Hope you had a great trip!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Actions
    // ─────────────────────────────────────────────────────────────────

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func recenterTapped() {
        switch mode! {
        case .driver:
            mapView.userTrackingMode = .follow
        case .passenger:
            if let ann = driverAnnotation {
                let region = MKCoordinateRegion(
                    center: ann.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
                mapView.setRegion(region, animated: true)
            }
        }
    }

    @objc private func endRideTapped() {
        guard case .driver(let ride, _) = mode else { return }
        let alert = UIAlertController(
            title: "End Ride?",
            message: "This completes the ride for all passengers.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End Ride", style: .destructive) { [weak self] _ in
            self?.performEndRide(rideID: ride.id)
        })
        present(alert, animated: true)
    }

    private func performEndRide(rideID: UUID) {
        endRideButton.isEnabled = false
        showAppLoading(message: "Ending ride…")
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.hideAppLoading(); self.endRideButton.isEnabled = true }
            do {
                _ = try await RideDataModel.shared.endRideAsync(id: rideID)
                RideTrackingService.shared.stopBroadcasting()
                self.dismiss(animated: true) { self.onRideEnded?() }
            } catch {
                let alert = UIAlertController(
                    title: "Couldn't End Ride",
                    message: error.localizedDescription,
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - MKMapViewDelegate
// ─────────────────────────────────────────────────────────────────

extension ActiveRideViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = AppDesign.Color.primary
            r.lineWidth   = 5
            r.lineCap     = .round
            r.lineJoin    = .round
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Default blue dot for user's own position
        if annotation is MKUserLocation { return nil }

        // Driver car pin (passenger view)
        if let driverAnn = annotation as? DriverAnnotation {
            let id = "DriverCar"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: driverAnn, reuseIdentifier: id)
            view.annotation     = driverAnn
            view.canShowCallout = false
            let cfg   = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
            view.image = UIImage(systemName: "car.fill", withConfiguration: cfg)?
                .withTintColor(AppDesign.Color.primary, renderingMode: .alwaysOriginal)
            view.centerOffset = CGPoint(x: 0, y: -13)
            return view
        }

        // Pickup / Destination pins
        if let point = annotation as? MKPointAnnotation {
            let id   = "WaypointPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: point, reuseIdentifier: id)
            view.annotation     = point
            view.canShowCallout = true
            view.markerTintColor = point.title?.lowercased().contains("pickup") == true
                ? .systemGreen : AppDesign.Color.primary
            return view
        }

        return nil
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - MKPolyline coordinate helper
// ─────────────────────────────────────────────────────────────────

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&result, range: NSRange(location: 0, length: pointCount))
        return result
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Inline title chip helper
// ─────────────────────────────────────────────────────────────────

private extension ActiveRideViewController {
    // Computed property for the chip title avoids switch in a stored property initialiser
    var modeTitleText: String {
        switch mode! {
        case .driver:    return "  🚗 Ride in Progress  "
        case .passenger: return "  📍 Tracking Driver  "
        }
    }
}
