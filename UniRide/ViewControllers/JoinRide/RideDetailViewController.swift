import UIKit
import MapKit

/// Full-screen detail page shown before a passenger requests to join a ride.
/// Displays: MapKit route preview · driver profile + rating · ride chips · notes · request button.
final class RideDetailViewController: UIViewController {

    // MARK: - Input
    var ride: Ride!
    var driver: UserProfile?
    /// Called after a successful join request — parent can pop or reload
    var onRequested: (() -> Void)?

    // MARK: - UI
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()  // vertical, everything inside

    private let mapView      = MKMapView()
    private let driverCard   = UIView()
    private let infoGrid     = UIView()
    private let notesCard    = UIView()
    private let bottomBar    = UIView()       // fixed at screen bottom
    private let requestBtn   = UIButton(type: .system)

    private var alreadyRequested = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Ride Details"
        navigationItem.largeTitleDisplayMode = .never
        buildLayout()
        populate()
        drawRoute()
        checkExistingRequest()
    }

    // MARK: - Layout

    private func buildLayout() {
        // ── Scroll + stack ──
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // ── Bottom bar (fixed) ──
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        // subtle top shadow
        bottomBar.layer.shadowColor   = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.07
        bottomBar.layer.shadowOffset  = CGSize(width: 0, height: -3)
        bottomBar.layer.shadowRadius  = 8
        view.addSubview(bottomBar)

        var btnCfg = UIButton.Configuration.filled()
        btnCfg.title             = "Request to Join"
        btnCfg.image             = UIImage(systemName: "arrow.right.circle.fill")
        btnCfg.imagePlacement    = .trailing
        btnCfg.imagePadding      = 8
        btnCfg.baseBackgroundColor = .systemGreen
        btnCfg.baseForegroundColor = .white
        btnCfg.cornerStyle       = .capsule
        btnCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var b = a; b.font = .systemFont(ofSize: 16, weight: .semibold); return b
        }
        requestBtn.configuration = btnCfg
        requestBtn.translatesAutoresizingMaskIntoConstraints = false
        requestBtn.addTarget(self, action: #selector(requestTapped), for: .touchUpInside)
        bottomBar.addSubview(requestBtn)

        // ── Map ──
        mapView.layer.cornerRadius = 0
        mapView.isZoomEnabled   = true
        mapView.isScrollEnabled = true
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false

        // ── Cards ──
        [driverCard, infoGrid, notesCard].forEach {
            $0.backgroundColor = .systemBackground
            $0.layer.cornerRadius = 18
            $0.layer.shadowColor  = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.06
            $0.layer.shadowOffset  = CGSize(width: 0, height: 4)
            $0.layer.shadowRadius  = 10
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Add to scrollable stack (wrapped in horizontal padding container)
        contentStack.addArrangedSubview(mapView)
        contentStack.addArrangedSubview(horizontalPad(driverCard))
        contentStack.addArrangedSubview(horizontalPad(infoGrid))
        contentStack.addArrangedSubview(horizontalPad(notesCard))
        // spacer so content clears the fixed button bar
        let spacer = UIView(); spacer.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(spacer)

        NSLayoutConstraint.activate([
            // ScrollView fills view above bottom bar
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Map: full width, fixed height
            mapView.heightAnchor.constraint(equalToConstant: 220),

            // Spacer so last card clears the fixed button bar (safe area + button + padding)
            spacer.heightAnchor.constraint(equalToConstant: 100),

            // ── Bottom bar: fills from button top to screen edge (covers home indicator area) ──
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ── Request button sits ABOVE the tab bar (safe area) ──
            requestBtn.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            requestBtn.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            requestBtn.heightAnchor.constraint(equalToConstant: 52),
            requestBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            // Button top determines the bar's top
            requestBtn.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
        ])
    }

    /// Wraps a card view in a container with 16pt horizontal padding
    private func horizontalPad(_ card: UIView) -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrap.topAnchor),
            card.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
        ])
        return wrap
    }

    // MARK: - Populate

    private func populate() {
        buildDriverCard()
        buildInfoGrid()
        buildNotesCard()
    }

    // ── Driver Card ──────────────────────────────────────────────────────────
    private func buildDriverCard() {
        let avatar = UIImageView()
        avatar.layer.cornerRadius = 30
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.backgroundColor = .systemGray5
        avatar.layer.borderWidth  = 2.5
        avatar.layer.borderColor  = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        avatar.loadAndFallback(from: driver?.photoURL, name: driver?.fullName ?? "D")
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = driver?.fullName ?? "Unknown Driver"
        nameLabel.font = .systemFont(ofSize: 17, weight: .bold)

        let subLabel = UILabel()
        subLabel.textColor = .secondaryLabel
        subLabel.font = .systemFont(ofSize: 13)
        if let d = driver {
            if d.role == .student {
                let y = d.year.map { ordinal($0) + " Year" } ?? "Student"
                subLabel.text = "\(y) · \(d.courseName ?? "")"
            } else {
                subLabel.text = "Faculty · \(d.courseName ?? "")"
            }
        } else {
            subLabel.text = "Driver"
        }

        // Star rating
        let ratingRow = buildStarRow(for: driver?.id)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subLabel, ratingRow])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let sectionLabel = makeSectionLabel("YOUR DRIVER")
        [sectionLabel, avatar, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            driverCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: driverCard.topAnchor, constant: 14),
            sectionLabel.leadingAnchor.constraint(equalTo: driverCard.leadingAnchor, constant: 16),

            avatar.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 12),
            avatar.leadingAnchor.constraint(equalTo: driverCard.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 60),
            avatar.heightAnchor.constraint(equalToConstant: 60),
            avatar.bottomAnchor.constraint(lessThanOrEqualTo: driverCard.bottomAnchor, constant: -16),

            textStack.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: driverCard.trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: driverCard.bottomAnchor, constant: -16),
        ])
    }

    private func buildStarRow(for userID: UUID?) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center

        let avg = userID.flatMap { ReviewDataModel.shared.averageRating(for: $0) }
        let filled = avg.map { Int($0.rounded()) } ?? 0

        for i in 1...5 {
            let img = UIImageView(image: UIImage(systemName: i <= filled ? "star.fill" : "star"))
            img.tintColor = i <= filled ? .systemYellow : .systemGray3
            img.widthAnchor.constraint(equalToConstant: 14).isActive = true
            img.heightAnchor.constraint(equalToConstant: 14).isActive = true
            stack.addArrangedSubview(img)
        }

        if let avg = avg {
            let lbl = UILabel()
            lbl.text = String(format: " %.1f", avg)
            lbl.font = .systemFont(ofSize: 12, weight: .medium)
            lbl.textColor = .secondaryLabel
            stack.addArrangedSubview(lbl)
        } else {
            let lbl = UILabel()
            lbl.text = "  No ratings yet"
            lbl.font = .systemFont(ofSize: 12)
            lbl.textColor = .tertiaryLabel
            stack.addArrangedSubview(lbl)
        }
        return stack
    }

    // ── Info Grid ────────────────────────────────────────────────────────────
    private func buildInfoGrid() {
        let sectionLabel = makeSectionLabel("RIDE INFO")

        let tf = DateFormatter(); tf.dateFormat = "EEE, MMM d  ·  h:mm a"
        let dateChip  = makeChip(icon: "clock.fill",     color: .systemBlue,   text: tf.string(from: ride.departureTime))
        let seatsChip = makeChip(icon: "person.2.fill",  color: .systemGreen,  text: "\(ride.seatsAvailable) seats left")
        let fareChip  = makeChip(icon: "indianrupeesign.circle.fill", color: .systemOrange, text: "₹\(Int(ride.farePerSeat)) per seat")

        let vehicleText: String
        if let v = driver?.vehicle {
            vehicleText = "\(v.type.rawValue.capitalized)  ·  \(v.model)"
        } else {
            vehicleText = "Car"
        }
        let vehicleChip = makeChip(icon: "car.fill", color: .systemPurple, text: vehicleText)

        let chipStack = UIStackView(arrangedSubviews: [dateChip, seatsChip, fareChip, vehicleChip])
        chipStack.axis = .vertical
        chipStack.spacing = 10
        chipStack.translatesAutoresizingMaskIntoConstraints = false

        [sectionLabel, chipStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            infoGrid.addSubview($0)
        }

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: infoGrid.topAnchor, constant: 14),
            sectionLabel.leadingAnchor.constraint(equalTo: infoGrid.leadingAnchor, constant: 16),

            chipStack.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 10),
            chipStack.leadingAnchor.constraint(equalTo: infoGrid.leadingAnchor, constant: 16),
            chipStack.trailingAnchor.constraint(equalTo: infoGrid.trailingAnchor, constant: -16),
            chipStack.bottomAnchor.constraint(equalTo: infoGrid.bottomAnchor, constant: -16),
        ])
    }

    // ── Notes Card ───────────────────────────────────────────────────────────
    private func buildNotesCard() {
        let notes = ride.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if notes.isEmpty {
            notesCard.isHidden = true
            return
        }
        let sectionLabel = makeSectionLabel("DRIVER NOTES")
        let body = UILabel()
        body.text = notes
        body.font = .systemFont(ofSize: 14)
        body.textColor = .secondaryLabel
        body.numberOfLines = 0
        [sectionLabel, body].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            notesCard.addSubview($0)
        }
        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: notesCard.topAnchor, constant: 14),
            sectionLabel.leadingAnchor.constraint(equalTo: notesCard.leadingAnchor, constant: 16),
            body.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: notesCard.leadingAnchor, constant: 16),
            body.trailingAnchor.constraint(equalTo: notesCard.trailingAnchor, constant: -16),
            body.bottomAnchor.constraint(equalTo: notesCard.bottomAnchor, constant: -16),
        ])
    }

    // ── Chip factory ─────────────────────────────────────────────────────────
    private func makeChip(icon: String, color: UIColor, text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center

        let iconWrap = UIView()
        iconWrap.backgroundColor = color.withAlphaComponent(0.12)
        iconWrap.layer.cornerRadius = 10
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconWrap.widthAnchor.constraint(equalToConstant: 36),
            iconWrap.heightAnchor.constraint(equalToConstant: 36),
        ])

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = color
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(img)
        NSLayoutConstraint.activate([
            img.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            img.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            img.widthAnchor.constraint(equalToConstant: 18),
            img.heightAnchor.constraint(equalToConstant: 18),
        ])

        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .label

        row.addArrangedSubview(iconWrap)
        row.addArrangedSubview(lbl)
        return row
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .tertiaryLabel
        l.letterSpacing(1.2)
        return l
    }

    // MARK: - Map Route

    private func drawRoute() {
        let src = CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon)
        let dst = CLLocationCoordinate2D(latitude: ride.destination.lat, longitude: ride.destination.lon)

        // Place pins
        let srcPin = MKPointAnnotation(); srcPin.coordinate = src
        srcPin.title = ride.source.address ?? "Pickup"
        let dstPin = MKPointAnnotation(); dstPin.coordinate = dst
        dstPin.title = ride.destination.address ?? "Drop-off"
        mapView.addAnnotations([srcPin, dstPin])

        // Request directions polyline
        let srcItem = MKMapItem(placemark: MKPlacemark(coordinate: src))
        let dstItem = MKMapItem(placemark: MKPlacemark(coordinate: dst))
        let req = MKDirections.Request()
        req.source = srcItem; req.destination = dstItem
        req.transportType = .automobile
        MKDirections(request: req).calculate { [weak self] resp, _ in
            guard let self, let route = resp?.routes.first else {
                // fallback: just show both pins
                self?.mapView.showAnnotations([srcPin, dstPin], animated: true)
                return
            }
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            let padded = route.polyline.boundingMapRect.insetBy(dx: -5000, dy: -5000)
            self.mapView.setVisibleMapRect(padded, animated: false)
        }
    }

    // MARK: - Join Logic

    private func checkExistingRequest() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        let existing = RideDataModel.shared.listRequests(for: ride.id)
            .first { $0.passengerUserID == user.id }
        if existing != nil {
            alreadyRequested = true
            updateButtonState()
        }
    }

    private func updateButtonState() {
        var cfg = requestBtn.configuration ?? UIButton.Configuration.filled()
        if alreadyRequested {
            cfg.title = "Request Sent ✓"
            cfg.baseBackgroundColor = .systemGray4
            cfg.image = nil
            requestBtn.isEnabled = false
        } else if ride.seatsAvailable <= 0 {
            cfg.title = "Ride Full"
            cfg.baseBackgroundColor = .systemGray4
            cfg.image = nil
            requestBtn.isEnabled = false
        } else {
            cfg.title = "Request to Join"
            cfg.baseBackgroundColor = .systemGreen
            cfg.image = UIImage(systemName: "arrow.right.circle.fill")
            requestBtn.isEnabled = true
        }
        requestBtn.configuration = cfg
    }

    @objc private func requestTapped() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        let req = RideRequest(
            rideID: ride.id,
            passengerUserID: user.id,
            pickupPoint: ride.source,
            seats: 1
        )
        RideDataModel.shared.createJoinRequest(req)
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)

        alreadyRequested = true
        updateButtonState()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let alert = UIAlertController(
            title: "Request Sent! 🎉",
            message: "The driver will approve your request. Check My Rides → Upcoming.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onRequested?()
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(n)th"
        }
    }
}

// MARK: - MapView Delegate
extension RideDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        r.strokeColor = UIColor.systemGreen
        r.lineWidth   = 4
        r.lineDashPattern = nil
        return r
    }
}

// MARK: - UILabel letterSpacing helper
private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }
        let attrs = NSAttributedString(
            string: text,
            attributes: [.kern: spacing, .font: font as Any, .foregroundColor: textColor as Any]
        )
        attributedText = attrs
    }
}
