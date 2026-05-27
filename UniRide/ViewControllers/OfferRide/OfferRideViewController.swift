import UIKit
import MapKit

// MARK: - OfferRideViewController (Step 1)
// Route + datetime + vehicle selection + seats + fare in a single screen.
// Layout lives in OfferRide.storyboard (Step 1 scene). This file holds the
// dynamic state, behaviour, and the per-vehicle row builder that populates
// the storyboard-defined vehicleCardsStack.
class OfferRideViewController: UIViewController,
                                UITableViewDelegate, UITableViewDataSource,
                                UITextFieldDelegate, MKMapViewDelegate {

    // MARK: - Storyboard outlets (layout is in IB)

    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var suggestionsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routePillsStack: UIStackView!
    @IBOutlet weak var routePillsContainer: UIView!
    @IBOutlet weak var chooseRouteLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingContainer: UIStackView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!

    // Cards (styled via applyCardStyle in viewDidLoad)
    @IBOutlet weak var routeCard: UIView!
    @IBOutlet weak var whenCard: UIView!
    @IBOutlet weak var vehicleCard: UIView!
    @IBOutlet weak var seatsCard: UIView!
    @IBOutlet weak var fareCard: UIView!

    // Vehicle list (rows added dynamically)
    @IBOutlet weak var vehicleCardsStack: UIStackView!

    // Seat controls
    @IBOutlet weak var minusSeat: UIButton!
    @IBOutlet weak var plusSeat: UIButton!
    @IBOutlet weak var seatCountLbl: UILabel!
    @IBOutlet weak var seatsHintLabel: UILabel!

    // Fare controls
    @IBOutlet weak var fareField: UITextField!
    @IBOutlet weak var suggestedLbl: UILabel!

    // MARK: - Optional route handoff
    var prefilledFrom: LocationPoint?
    var prefilledTo: LocationPoint?
    var prefilledDate: Date?
    var prefilledTime: Date?

    // MARK: - Route state
    private let minimumLeadTimeSeconds: TimeInterval = 10 * 60
    private var fromCoord: CLLocationCoordinate2D?
    private var toCoord: CLLocationCoordinate2D?
    private var activeField: UITextField?
    private var suggestions: [MKLocalSearchCompletion] = []
    private var routes: [MKRoute] = []
    private var selectedRoute: MKRoute?
    private var isLoadingVisible = false

    // MARK: - Vehicle / seat / fare state
    private var vehicles: [Vehicle] = []
    private var selectedVehicle: Vehicle? {
        didSet { refreshVehicleCards(); updateSeatsMax(); calculateSuggestedFare(); updateNextButtonState() }
    }
    private var seatCount: Int = 0 {
        didSet { updateSeatsUI(); calculateSuggestedFare(); updateNextButtonState() }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Plan Your Ride"
        styleCards()
        styleHeaderTextFields()
        styleSeatButtons()
        applyDynamicTypography()
        nextButton.applyProminentPrimaryCTA(title: nextButton.currentTitle ?? "Continue",
                                            corner: AppDesign.Radius.md)

        // Map gets a corner radius + clipping (matches former runtime style).
        mapView.layer.cornerRadius = AppDesign.Radius.md
        mapView.clipsToBounds = true
        routePillsContainer.applySmallCard()

        // Seats / fare cards start hidden until the user picks a vehicle.
        seatsCard.isHidden = true
        fareCard.isHidden = true

        // Fare field needs runtime styling.
        fareField.applyRoundedField()
        fareField.setLeftPaddingPoints(12)
        fareField.font = AppDesign.Typography.body
        fareField.delegate = self

        setDefaultDateAndTime()
        setupAutocomplete()
        setupPickers()
        setInitialRouteUIState()
        reloadVehicles()
        prefillLocationsIfPossible()
        updateNextButtonState()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadVehicles()
    }

    // MARK: - Dynamic styling (tokens that can't live in IB)

    private func styleCards() {
        [routeCard, whenCard, vehicleCard, seatsCard, fareCard].forEach {
            $0?.applyCardStyle(corner: AppDesign.Radius.md,
                               shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                               shadowRadius: AppDesign.Shadow.smallCardRadius)
        }
    }

    private func styleHeaderTextFields() {
        fromTextField.borderStyle = .none
        fromTextField.backgroundColor = .clear
        fromTextField.addLeftIcon("smallcircle.filled.circle", tint: AppDesign.Color.success)

        toTextField.borderStyle = .none
        toTextField.backgroundColor = .clear
        toTextField.addLeftIcon("smallcircle.filled.circle", tint: AppDesign.Color.destructive)
    }

    private func styleSeatButtons() {
        // Storyboard sets the minus/plus button images + capsule corner. We
        // tint them at runtime so it picks up the design tokens.
        if var cfg = minusSeat.configuration {
            cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
            cfg.baseForegroundColor = .label
            minusSeat.configuration = cfg
        }
        if var cfg = plusSeat.configuration {
            cfg.baseBackgroundColor = AppDesign.Color.primary
            cfg.baseForegroundColor = .white
            plusSeat.configuration = cfg
        }
        seatCountLbl.font = AppDesign.Typography.display
    }

    private func applyDynamicTypography() {
        loadingLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        emptyStateLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel, lines: 0)
        chooseRouteLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)
        seatsHintLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        suggestedLbl.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
    }

    // MARK: - Vehicle list helpers

    private func reloadVehicles() {
        vehicles = UserDataModel.shared.getCurrentUser()?.vehicles ?? []
        refreshVehicleCards()
    }

    private func refreshVehicleCards() {
        vehicleCardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for vehicle in vehicles {
            let row = makeVehicleRow(vehicle)
            vehicleCardsStack.addArrangedSubview(row)
        }

        let addRow = makeAddVehicleRow()
        vehicleCardsStack.addArrangedSubview(addRow)
    }

    private func makeVehicleRow(_ vehicle: Vehicle) -> UIView {
        let isSelected = selectedVehicle?.registrationNumber == vehicle.registrationNumber

        let container = UIView()
        container.backgroundColor = isSelected
            ? AppDesign.Color.primary.withAlphaComponent(0.08)
            : AppDesign.Color.fieldBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = isSelected ? 2 : 1
        container.layer.borderColor = isSelected
            ? AppDesign.Color.primary.cgColor
            : AppDesign.Color.border.cgColor

        let iconName: String
        switch vehicle.type {
        case .car:   iconName = "car.fill"
        case .bike:  iconName = "bicycle"
        case .other: iconName = "car"
        }
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = isSelected ? AppDesign.Color.primary : .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let nameLabel = UILabel()
        let displayName = vehicle.alias?.isEmpty == false ? vehicle.alias! : vehicle.model
        nameLabel.text = displayName
        nameLabel.font = AppDesign.Typography.bodyStrong
        nameLabel.textColor = isSelected ? AppDesign.Color.primary : .label

        let detailLabel = UILabel()
        detailLabel.text = "\(vehicle.model) • \(vehicle.registrationNumber)"
        detailLabel.font = AppDesign.Typography.caption
        detailLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = AppDesign.Color.primary
        checkmark.alpha = isSelected ? 1 : 0
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.widthAnchor.constraint(equalToConstant: 22).isActive = true
        checkmark.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let row = UIStackView(arrangedSubviews: [icon, textStack, checkmark])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(vehicleRowTapped(_:)))
        container.addGestureRecognizer(tap)
        container.tag = vehicles.firstIndex(where: { $0.registrationNumber == vehicle.registrationNumber }) ?? 0
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func vehicleRowTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, vehicles.indices.contains(view.tag) else { return }
        AppHaptics.selection()
        selectedVehicle = vehicles[view.tag]
        seatsCard.isHidden = false
        fareCard.isHidden = false
    }

    private func makeAddVehicleRow() -> UIView {
        let container = UIView()
        container.backgroundColor = AppDesign.Color.fieldBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = AppDesign.Color.border.cgColor

        let icon = UIImageView(image: UIImage(systemName: "plus.circle.fill"))
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let label = UILabel()
        label.text = "Add New Vehicle"
        label.font = AppDesign.Typography.bodyStrong
        label.textColor = AppDesign.Color.primary

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(addVehicleTapped))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        return container
    }

    @objc private func addVehicleTapped() {
        let sb = UIStoryboard(name: "VehicleRegistration", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "VehicleRegistrationViewController") as? VehicleRegistrationViewController else { return }
        vc.vehicleToEdit = nil
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Seats (wired from storyboard)

    @IBAction private func minusSeatTapped(_ sender: UIButton) { adjustSeats(-1) }
    @IBAction private func plusSeatTapped(_ sender: UIButton)  { adjustSeats(1) }

    private func updateSeatsMax() {
        let maxSeats = maxOfferableSeats()
        if seatCount > maxSeats { seatCount = maxSeats }
        seatsHintLabel.text = "Maximum \(maxSeats) seat\(maxSeats == 1 ? "" : "s")"
    }

    private func adjustSeats(_ delta: Int) {
        let maxSeats = maxOfferableSeats()
        let newVal = seatCount + delta
        guard newVal >= 0, newVal <= maxSeats else { return }
        seatCount = newVal
    }

    private func updateSeatsUI() {
        seatCountLbl.text   = "\(seatCount)"
        let maxSeats        = maxOfferableSeats()
        minusSeat.isEnabled = seatCount > 0
        minusSeat.alpha     = seatCount > 0 ? 1 : 0.4
        plusSeat.isEnabled  = seatCount < maxSeats
        plusSeat.alpha      = seatCount < maxSeats ? 1 : 0.4
    }

    private func maxOfferableSeats() -> Int {
        guard let vehicle = selectedVehicle else { return 0 }
        return max(1, min(vehicle.seats, 6))
    }

    // MARK: - Fare

    @IBAction private func fareChanged() { updateNextButtonState() }

    private func calculateSuggestedFare() {
        guard let route = selectedRoute, seatCount > 0, let vehicle = selectedVehicle else {
            suggestedLbl.text = "Suggested: ₹—"
            fareField.text = ""
            return
        }
        let vehicleStr = vehicle.type == .bike ? "bike" : "car"
        let departure  = datePicker.date
        let rideRoute  = MapKitManager.shared.convert(route)
        let fare = PricingManager.shared.suggestedFare(
            distanceMeters: rideRoute.distanceMeters,
            seats: seatCount,
            vehicle: vehicleStr,
            departureTime: departure
        )
        fareField.text = "\(fare)"
        let peak = PricingManager.shared.isPeakHour(departure) ? " · Peak hours" : ""
        suggestedLbl.text = "Suggested: ₹\(fare)\(peak)"
        updateNextButtonState()
    }

    // MARK: - Pickers & date helpers

    private func setDefaultDateAndTime() {
        datePicker.date = Date()
        timePicker.date = minimumRideDateTime()
    }

    private func setupPickers() {
        datePicker.minimumDate = Date()
        if datePicker.date < Date() { datePicker.date = Date() }
        if timePicker.date < minimumRideDateTime() { timePicker.date = minimumRideDateTime() }
        refreshTimeConstraintIfNeeded()
        timePicker.transform = CGAffineTransform(translationX: -20, y: 0)
    }

    private func minimumRideDateTime() -> Date { Date().addingTimeInterval(minimumLeadTimeSeconds) }

    private func refreshTimeConstraintIfNeeded() {
        let min = minimumRideDateTime()
        if Calendar.current.isDateInToday(datePicker.date) {
            timePicker.minimumDate = min
            if timePicker.date < min { timePicker.date = min }
        } else {
            timePicker.minimumDate = nil
        }
    }

    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) { refreshTimeConstraintIfNeeded() }
    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) { refreshTimeConstraintIfNeeded() }

    // MARK: - Autocomplete

    private func setupAutocomplete() {
        MapKitManager.shared.onSuggestionsUpdate = { [weak self] results in
            guard let self else { return }
            self.suggestions = results
            self.suggestionsTable.reloadData()
            self.suggestionsTable.isHidden = results.isEmpty
        }
    }

    private func prefillLocationsIfPossible() {
        if let prefilledFrom {
            fromTextField.text = prefilledFrom.address ?? "Selected pickup"
            fromCoord = CLLocationCoordinate2D(latitude: prefilledFrom.lat, longitude: prefilledFrom.lon)
        }
        if let prefilledTo {
            toTextField.text = prefilledTo.address ?? "Selected drop-off"
            toCoord = CLLocationCoordinate2D(latitude: prefilledTo.lat, longitude: prefilledTo.lon)
        }
        if let prefilledDate { datePicker.date = prefilledDate }
        if let prefilledTime { timePicker.date = prefilledTime }
        if prefilledFrom != nil || prefilledTo != nil {
            refreshTimeConstraintIfNeeded()
            updateNextButtonState()
            tryFetchRoutes()
            return
        }

        guard let prefill = UserDataModel.shared.suggestedCommutePrefill() else { return }
        fromTextField.text = prefill.from.address ?? "Chitkara University"
        toTextField.text   = prefill.to.address   ?? "Home"
        fromCoord = CLLocationCoordinate2D(latitude: prefill.from.lat, longitude: prefill.from.lon)
        toCoord   = CLLocationCoordinate2D(latitude: prefill.to.lat,   longitude: prefill.to.lon)
        updateNextButtonState()
        tryFetchRoutes()
    }

    // MARK: - TextField delegates (location typing)

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == fromTextField || textField == toTextField {
            let updated = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            activeField = textField
            MapKitManager.shared.updateQuery(updated)
            updateSuggestionTablePosition()
            return true
        }
        if textField == fareField {
            if string.isEmpty { return true }
            let allowed = CharacterSet.decimalDigits
            guard string.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
            let current = (textField.text ?? "") as NSString
            let newText = current.replacingCharacters(in: range, with: string)
            return newText.count <= 5
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { true }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @IBAction private func locationFieldEditingChanged(_ sender: UITextField) { updateNextButtonState() }

    // MARK: - Table (suggestions)

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { suggestions.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "sCell")
        let r = suggestions[indexPath.row]
        cell.textLabel?.text       = r.title
        cell.detailTextLabel?.text = r.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = suggestions[indexPath.row]
        MapKitManager.shared.resolveCompletion(completion) { mapItem in
            guard let item = mapItem else { return }
            DispatchQueue.main.async {
                if self.activeField == self.fromTextField {
                    self.fromTextField.text = item.name
                    self.fromCoord = item.placemark.coordinate
                } else {
                    self.toTextField.text = item.name
                    self.toCoord = item.placemark.coordinate
                }
                self.suggestionsTable.isHidden = true
                self.activeField?.resignFirstResponder()
                self.activeField = nil
                self.updateNextButtonState()
                self.tryFetchRoutes()
            }
        }
    }

    private func updateSuggestionTablePosition() {
        guard let tf = activeField else { return }
        let frame = tf.convert(tf.bounds, to: view)
        UIView.animate(withDuration: 0.2) {
            self.suggestionsTable.frame = CGRect(
                x: frame.minX, y: frame.maxY + AppDesign.Spacing.xxs,
                width: frame.width, height: 220
            )
        }
    }

    // MARK: - Route fetching

    private func setInitialRouteUIState() {
        chooseRouteLabel.alpha = 0;    chooseRouteLabel.isHidden = true
        mapView.alpha = 0;             mapView.isHidden = true
        routePillsContainer.alpha = 0; routePillsContainer.isHidden = true
        emptyStateLabel.alpha = 1;     emptyStateLabel.isHidden = false
        loadingContainer.alpha = 0;    loadingContainer.isHidden = true
        loadingSpinner.stopAnimating()
    }

    private func tryFetchRoutes() {
        guard let f = fromCoord, let t = toCoord else { return }
        showLoading()
        MapKitManager.shared.getRoutes(from: f, to: t) { routes in
            DispatchQueue.main.async {
                self.routes = Array(routes.prefix(2))
                self.selectedRoute = self.routes.first
                guard let selected = self.selectedRoute else {
                    self.hideLoading()
                    self.emptyStateLabel.text = "Couldn't find a route — check your locations and try again"
                    self.emptyStateLabel.alpha = 1
                    self.emptyStateLabel.isHidden = false
                    self.setInitialRouteUIState()
                    return
                }
                self.drawRoutes()
                self.mapView.setVisibleRoute(selected)
                self.buildRoutePills()
                self.hideLoading()
                self.revealRouteUI()
                self.calculateSuggestedFare()
            }
        }
    }

    private func buildRoutePills() {
        routePillsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        routePillsContainer.subviews.compactMap { $0 as? UIVisualEffectView }.forEach { $0.removeFromSuperview() }
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.frame = routePillsContainer.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        routePillsContainer.insertSubview(blur, at: 0)

        for (index, route) in routes.enumerated() {
            let minutes = Int(route.expectedTravelTime / 60)
            let km = String(format: "%.1f", route.distance / 1000)
            let title = "Route \(index + 1)\n\(km) km • \(minutes) min"

            let btn = UIButton(type: .system)
            btn.tag = index
            btn.setTitle(title, for: .normal)
            btn.applyRoutePill(selected: route == selectedRoute)

            let captured = index
            btn.addAction(UIAction { [weak self] _ in
                guard let self, self.routes.indices.contains(captured) else { return }
                self.selectedRoute = self.routes[captured]
                self.drawRoutes()
                if let r = self.selectedRoute { self.mapView.setVisibleRoute(r) }
                for case let b as UIButton in self.routePillsStack.arrangedSubviews {
                    b.applyRoutePill(selected: b.tag == captured)
                }
                self.calculateSuggestedFare()
            }, for: .touchUpInside)

            routePillsStack.addArrangedSubview(btn)
        }
        routePillsContainer.isHidden = false
    }

    private func drawRoutes() {
        mapView.isHidden = false
        mapView.removeOverlays(mapView.overlays)
        for route in routes {
            let poly = route.polyline
            poly.title = (route == selectedRoute) ? "selected" : "unselected"
            mapView.addOverlay(poly)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let r = MKPolylineRenderer(overlay: overlay)
        if overlay.title == "selected" {
            r.strokeColor = AppDesign.Color.primary; r.lineWidth = 9; r.alpha = 1
        } else {
            r.strokeColor = UIColor.systemGray4; r.lineWidth = 4; r.alpha = 0.5
        }
        r.lineCap = .round; r.lineJoin = .round
        return r
    }

    private func showLoading() {
        guard !isLoadingVisible else { return }
        isLoadingVisible = true
        loadingContainer.isHidden = false
        loadingSpinner.startAnimating()
        emptyStateLabel.alpha = 0; emptyStateLabel.isHidden = true
        loadingContainer.transform = CGAffineTransform(translationX: 0, y: 6)
        UIView.animate(withDuration: 0.25) {
            self.loadingContainer.alpha = 1
            self.loadingContainer.transform = .identity
        }
    }

    private func hideLoading() {
        guard isLoadingVisible else { return }
        isLoadingVisible = false
        UIView.animate(withDuration: 0.2) { self.loadingContainer.alpha = 0 } completion: { _ in
            self.loadingContainer.isHidden = true
            self.loadingSpinner.stopAnimating()
        }
    }

    private func revealRouteUI() {
        chooseRouteLabel.isHidden = false
        mapView.isHidden = false
        routePillsContainer.isHidden = false
        loadingContainer.isHidden = true

        chooseRouteLabel.transform = CGAffineTransform(translationX: 0, y: 8)
        mapView.transform          = CGAffineTransform(translationX: 0, y: 8)
        routePillsContainer.transform = CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(withDuration: 0.3) {
            self.chooseRouteLabel.alpha = 1;   self.chooseRouteLabel.transform = .identity
            self.mapView.alpha = 1;            self.mapView.transform = .identity
            self.routePillsContainer.alpha = 1; self.routePillsContainer.transform = .identity
            self.emptyStateLabel.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in self.emptyStateLabel.isHidden = true }
    }

    // MARK: - Validation

    private func updateNextButtonState() {
        let hasFrom    = !(fromTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTo      = !(toTextField.text   ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !SessionManager.shared.isLoggedIn {
            nextButton.setPrimaryCTAEnabled(hasFrom && hasTo)
            return
        }

        let hasVehicle = selectedVehicle != nil
        let hasSeats   = seatCount > 0
        let hasFare    = (Double(fareField.text ?? "") ?? 0) > 0
        nextButton.setPrimaryCTAEnabled(hasFrom && hasTo && hasVehicle && hasSeats && hasFare)
    }

    // MARK: - Next button → ReviewRideViewController

    @IBAction func nextTapped(_ sender: Any) {
        ensureNonGuest { [weak self] in
            guard let self = self else { return }
            let fromText = self.fromTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let toText   = self.toTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !fromText.isEmpty, !toText.isEmpty else {
                self.showAlert("Route Incomplete", message: "Add both a pickup and drop-off to continue.")
                return
            }
            guard let from = self.fromCoord else {
                self.showAlert("Select a Location", message: "Tap a suggestion to confirm your pickup.")
                return
            }
            guard let to = self.toCoord else {
                self.showAlert("Select a Location", message: "Tap a suggestion to confirm your drop-off.")
                return
            }
            guard fromText.lowercased() != toText.lowercased() else {
                self.showAlert("Same Location", message: "Your pickup and drop-off are the same place. Update one to continue.")
                return
            }
            guard let vehicle = self.selectedVehicle else {
                self.showAlert("No Vehicle Selected", message: "Pick a vehicle from your list or add a new one.")
                return
            }
            guard self.seatCount > 0 else {
                self.showAlert("Seats Not Set", message: "Set the number of passengers you can take.")
                return
            }
            let fareValue = Double(self.fareField.text ?? "") ?? 0
            guard fareValue > 0 else {
                self.showAlert("Price Missing", message: "Set a per-seat price to continue.")
                return
            }

            self.view.endEditing(true)

            let summary = RideSummary(
                from: LocationPoint(lat: from.latitude, lon: from.longitude, address: self.fromTextField.text),
                to:   LocationPoint(lat: to.latitude,   lon: to.longitude,   address: self.toTextField.text),
                date: self.datePicker.date,
                time: self.timePicker.date,
                route: self.selectedRoute.map { MapKitManager.shared.convert($0) },
                vehicleType: vehicle.type == .bike ? "Bike" : "Car",
                seats: self.seatCount,
                farePerSeat: fareValue,
                registrationPlate: vehicle.registrationNumber,
                vehicleModel: vehicle.model
            )

            let sb = UIStoryboard(name: "OfferRide", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "ReviewRideViewController") as! ReviewRideViewController
            vc.summary = summary
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
