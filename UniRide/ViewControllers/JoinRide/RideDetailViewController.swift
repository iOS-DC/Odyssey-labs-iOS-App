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

    // MARK: - IBOutlets (wired in RideDetail.storyboard)
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var contentStack: UIStackView!
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var bottomBar: UIView!
    @IBOutlet private var requestBtn: UIButton!

    // MARK: - Runtime card views (built from data, acceptable dynamic subviews)
    private let driverCard   = UIView()
    private let infoGrid     = UIView()
    private let notesCard    = UIView()

    private var alreadyRequested = false
    private var isDriver = false
    private var hasTimeConflict = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupMapView()
        setupCards()
        setupBottomBar()
        populate()
        drawRoute()
        checkExistingRequest()
        if let driverID = driver?.id {
            ReviewDataModel.shared.fetchAndMerge(for: driverID)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup

    private func setupMapView() {
        mapView.layer.cornerRadius = AppDesign.Radius.lg
        mapView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        mapView.clipsToBounds = true
        mapView.isZoomEnabled   = true
        mapView.isScrollEnabled = true
        mapView.delegate = self
    }

    private func setupCards() {
        [driverCard, infoGrid, notesCard].forEach {
            $0.applyCardStyle(corner: AppDesign.Radius.md)
        }
        contentStack.addArrangedSubview(horizontalPad(driverCard))
        contentStack.addArrangedSubview(horizontalPad(infoGrid))
        contentStack.addArrangedSubview(horizontalPad(notesCard))
        // Spacer so last card clears the fixed button bar
        let spacer = UIView()
        spacer.heightAnchor.constraint(
            equalToConstant: AppDesign.Size.buttonHeight + (AppDesign.Spacing.lg * 2)
        ).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.layer.shadowColor   = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        bottomBar.layer.shadowOffset  = CGSize(width: 0, height: -AppDesign.Spacing.xxs)
        bottomBar.layer.shadowRadius  = AppDesign.Shadow.smallCardRadius
        requestBtn.applyProminentPrimaryCTA(
            title: "Request Seat",
            corner: AppDesign.Radius.md,
            imageSystemName: "arrow.right.circle.fill",
            imagePlacement: .trailing
        )
    }

    /// Wraps a card view in a container with 16pt horizontal padding
    private func horizontalPad(_ card: UIView) -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrap.topAnchor),
            card.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: AppDesign.Spacing.md),
            card.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -AppDesign.Spacing.md),
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
        avatar.backgroundColor = AppDesign.Color.borderSubtle
        avatar.layer.borderWidth  = 2.5
        avatar.layer.borderColor  = AppDesign.Color.primary.withAlphaComponent(0.5).cgColor
        avatar.loadAndFallback(from: driver?.photoURL, name: driver?.fullName ?? "D")
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = driver?.fullName ?? "Unknown Driver"
        nameLabel.font = AppDesign.Typography.bodyStrong

        let subLabel = UILabel()
        subLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
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
            img.tintColor = i <= filled ? AppDesign.Color.warning : AppDesign.Color.borderSubtle
            img.widthAnchor.constraint(equalToConstant: 14).isActive = true
            img.heightAnchor.constraint(equalToConstant: 14).isActive = true
            stack.addArrangedSubview(img)
        }

        if let avg = avg {
            let lbl = UILabel()
            lbl.text = String(format: " %.1f", avg)
            lbl.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
            stack.addArrangedSubview(lbl)
        } else {
            let lbl = UILabel()
            lbl.text = "  No ratings yet"
            lbl.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
            stack.addArrangedSubview(lbl)
        }
        return stack
    }

    // ── Info Grid ────────────────────────────────────────────────────────────
    private func buildInfoGrid() {
        let sectionLabel = makeSectionLabel("RIDE INFO")

        let tf = DateFormatter(); tf.dateFormat = "EEE, MMM d  ·  h:mm a"
        let dateChip  = makeChip(icon: "clock.fill",     color: AppDesign.Color.primary,   text: tf.string(from: ride.departureTime))
        let seatsChip = makeChip(icon: "person.2.fill",  color: AppDesign.Color.primary,  text: "\(ride.seatsAvailable) seats left")
        let fareChip  = makeChip(icon: "indianrupeesign.circle.fill", color: .systemOrange, text: "₹\(Int(ride.farePerSeat)) per seat")

        let vehicleText: String
        let model = ride.vehicleModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let plate = ride.registrationPlate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !model.isEmpty && !plate.isEmpty {
            vehicleText = "\(model)  ·  \(plate)"
        } else if !model.isEmpty {
            vehicleText = model
        } else if let v = driver?.vehicles?.first {
            vehicleText = "\(v.type.rawValue.capitalized)  ·  \(v.model)"
        } else {
            vehicleText = "Car"
        }
        let vehicleChip = makeChip(icon: "car.fill", color: AppDesign.Color.primary, text: vehicleText)

        let topRow = UIStackView(arrangedSubviews: [dateChip, seatsChip])
        topRow.axis = .horizontal
        topRow.spacing = AppDesign.Spacing.sm
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [fareChip, vehicleChip])
        bottomRow.axis = .horizontal
        bottomRow.spacing = AppDesign.Spacing.sm
        bottomRow.distribution = .fillEqually

        let chipGrid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        chipGrid.axis = .vertical
        chipGrid.spacing = AppDesign.Spacing.sm
        chipGrid.translatesAutoresizingMaskIntoConstraints = false

        [sectionLabel, chipGrid].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            infoGrid.addSubview($0)
        }

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: infoGrid.topAnchor, constant: 14),
            sectionLabel.leadingAnchor.constraint(equalTo: infoGrid.leadingAnchor, constant: 16),

            chipGrid.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 10),
            chipGrid.leadingAnchor.constraint(equalTo: infoGrid.leadingAnchor, constant: 16),
            chipGrid.trailingAnchor.constraint(equalTo: infoGrid.trailingAnchor, constant: -16),
            chipGrid.bottomAnchor.constraint(equalTo: infoGrid.bottomAnchor, constant: -16),
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
        body.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel, lines: 0)
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
        iconWrap.layer.cornerRadius = AppDesign.Radius.sm
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
        lbl.applyTextStyle(AppDesign.Typography.subheadline)

        row.addArrangedSubview(iconWrap)
        row.addArrangedSubview(lbl)
        return row
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.capitalized
        l.applyTextStyle(AppDesign.Typography.cardTitle)
        return l
    }

    // MARK: - Map Route

    private func drawRoute() {
        let src = CLLocationCoordinate2D(latitude: ride.source.lat, longitude: ride.source.lon)
        let dst = CLLocationCoordinate2D(latitude: ride.destination.lat, longitude: ride.destination.lon)

        let srcPin = MKPointAnnotation(); srcPin.coordinate = src
        srcPin.title = ride.source.address ?? "Pickup"
        let dstPin = MKPointAnnotation(); dstPin.coordinate = dst
        dstPin.title = ride.destination.address ?? "Drop-off"
        mapView.addAnnotations([srcPin, dstPin])

        let srcItem = MKMapItem(placemark: MKPlacemark(coordinate: src))
        let dstItem = MKMapItem(placemark: MKPlacemark(coordinate: dst))
        let req = MKDirections.Request()
        req.source = srcItem; req.destination = dstItem
        req.transportType = .automobile
        MKDirections(request: req).calculate { [weak self] resp, _ in
            guard let self, let route = resp?.routes.first else {
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
        
        // 1. Check if user is the driver
        if ride.driverUserID == user.id {
            isDriver = true
        }

        // 2. Check for overlapping rides in the user's schedule (+/- 2 hours)
        let myUpcoming = RideDataModel.shared.myUpcoming(userID: user.id)
        hasTimeConflict = myUpcoming.contains { trip in
            // Skip the current ride if it's already in our upcoming list
            if trip.ride.id == ride.id { return false }
            
            let timeDiff = abs(trip.ride.departureTime.timeIntervalSince(ride.departureTime))
            return timeDiff < 7200 // 2 hours buffer
        }

        // 3. Check if already requested
        let existing = RideDataModel.shared.listRequests(for: ride.id)
            .first { $0.passengerUserID == user.id }
        if existing != nil {
            alreadyRequested = true
        }
        
        updateButtonState()
    }

    private func updateButtonState() {
        var cfg = requestBtn.configuration ?? UIButton.Configuration.filled()
        
        if isDriver {
            cfg.title = "Your Offered Ride"
            cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
            cfg.baseForegroundColor = AppDesign.Color.textSecondary
            cfg.image = nil
            requestBtn.isEnabled = false
        } else if alreadyRequested {
            cfg.title = "Request Sent"
            cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
            cfg.baseForegroundColor = AppDesign.Color.textSecondary
            cfg.image = nil
            requestBtn.isEnabled = false
        } else if hasTimeConflict {
            cfg.title = "You have a ride at this time"
            cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
            cfg.baseForegroundColor = AppDesign.Color.textSecondary
            cfg.image = nil
            requestBtn.isEnabled = false
        } else if ride.seatsAvailable <= 0 {
            cfg.title = "Fully Booked"
            cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
            cfg.baseForegroundColor = AppDesign.Color.textSecondary
            cfg.image = nil
            requestBtn.isEnabled = false
        } else {
            cfg.title = "Request Seat"
            cfg.baseBackgroundColor = AppDesign.Color.primary
            cfg.image = UIImage(systemName: "arrow.right.circle.fill")
            cfg.imagePlacement = .trailing
            cfg.imagePadding = AppDesign.Spacing.xs
            requestBtn.isEnabled = true
        }
        requestBtn.configuration = cfg
    }

    @IBAction private func requestTapped() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        
        // Final safety checks
        if isDriver { return }
        if hasTimeConflict {
            let alert = UIAlertController(title: "Time Conflict", message: "You've already got a ride around this time. Check My Rides before requesting.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            present(alert, animated: true)
            return
        }

        let req = RideRequest(
            rideID: ride.id,
            passengerUserID: user.id,
            pickupPoint: ride.source,
            seats: 1
        )
        requestBtn.isEnabled = false
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await RideDataModel.shared.createJoinRequestAsync(req)
                NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)

                alreadyRequested = true
                updateButtonState()

                AppHaptics.success()

                let alert = UIAlertController(
                    title: "Request Sent!",
                    message: "The driver will review your request. Check My Rides → Upcoming for updates.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Got It", style: .default) { [weak self] _ in
                    self?.onRequested?()
                    self?.navigationController?.popViewController(animated: true)
                })
                present(alert, animated: true)
            } catch {
                requestBtn.isEnabled = true
                updateButtonState()
                let alert = UIAlertController(
                    title: "Request Failed",
                    message: "Couldn't send your request. Try again or contact the driver.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Got It", style: .default))
                present(alert, animated: true)
            }
        }
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
        r.strokeColor = AppDesign.Color.primary
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
