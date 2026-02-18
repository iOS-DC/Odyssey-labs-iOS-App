////
////  OfferRideViewController.swift
////  UniRide
////
////  Created by Krish Bahukhandi on 21/11/25.
////



import UIKit
import MapKit

class OfferRideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate,MKMapViewDelegate {
    private let minimumLeadTimeSeconds: TimeInterval = 10 * 60

    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var suggestionsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var routePillsStack: UIStackView!
    @IBOutlet weak var routePillsContainer: UIView!
    @IBOutlet weak var chooseRouteLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var dateTimeStack: UIStackView!
    @IBOutlet weak var loadingContainer: UIStackView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fromLabelTitle: UILabel!
    @IBOutlet weak var fromFieldContainer: UIView!
    @IBOutlet weak var toLabelTitle: UILabel!
    @IBOutlet weak var toFieldContainer: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!

    private var fromCoord: CLLocationCoordinate2D?
    private var toCoord: CLLocationCoordinate2D?
    private var activeField: UITextField?

    private var suggestions: [MKLocalSearchCompletion] = []
    private var routes: [MKRoute] = []
    // Persistent Routes Sheet
    

    private var selectedRoute: MKRoute?

    @IBOutlet weak var contentView: UIView!

    private var isLoadingVisible = false

    // Sets up everything when the screen first loads
    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultDateAndTime()

        contentView.applyCardStyle()
        setupAutocomplete()
        setupPickers()
        routePillsContainer.applySmallCard()
        setInitialRouteUIState()
        updateNextButtonState()

    }
    // Sets the date to today and time to 10 minutes from now (minimum lead time)
    private func setDefaultDateAndTime() {
        datePicker.date = Date()
        timePicker.date = minimumRideDateTime()
    }

    // Hides the map and route options until user enters locations
    private func setInitialRouteUIState() {
        chooseRouteLabel.alpha = 0
        chooseRouteLabel.isHidden = true
        mapView.alpha = 0
        mapView.isHidden = true
        routePillsContainer.alpha = 0
        routePillsContainer.isHidden = true

        emptyStateLabel.alpha = 1
        emptyStateLabel.isHidden = false
        loadingContainer.alpha = 0
        loadingContainer.isHidden = true
        loadingSpinner.stopAnimating()
    }

    // Hooks up location autocomplete so suggestions appear when user types
    private func setupAutocomplete() {
        MapKitManager.shared.onSuggestionsUpdate = { results in
            self.suggestions = results
            self.suggestionsTable.reloadData()
            self.suggestionsTable.isHidden = results.isEmpty
        }
    }

    // MARK: - Setup Pickers
    // Makes sure user can't pick dates/times in the past.
    private func setupPickers() {
        datePicker.minimumDate = Date()
        if datePicker.date < Date() { datePicker.date = Date() }
        if timePicker.date < minimumRideDateTime() { timePicker.date = minimumRideDateTime() }
        refreshTimeConstraintIfNeeded()

        // The compact UIDatePicker has internal left padding (~6pt) that makes the
        // clock icon appear further from the picker than in JoinRide.
        // Shift the picker left to cancel that internal inset.
        timePicker.transform = CGAffineTransform(translationX: -6, y: 0)
    }



    // When user picks a different date, update the time constraints
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        refreshTimeConstraintIfNeeded()
    }

    // When user picks a different time, update the constraints
    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) {
        refreshTimeConstraintIfNeeded()
    }

    // Returns the earliest time a ride can be scheduled (10 minutes from now)
    private func minimumRideDateTime() -> Date {
        Date().addingTimeInterval(minimumLeadTimeSeconds)
    }

    // If they pick today, enforce the 10-minute minimum. For future dates, no time restrictions
    private func refreshTimeConstraintIfNeeded() {
        let minDateTime = minimumRideDateTime()
        var didAdjustTime = false
        if Calendar.current.isDateInToday(datePicker.date) {
            timePicker.minimumDate = minDateTime
            if timePicker.date < minDateTime {
                timePicker.date = minDateTime
                didAdjustTime = true
            }
        } else {
            timePicker.minimumDate = nil
        }

        if didAdjustTime {
            // keep picker value in valid range for same-day rides
        }
    }


    // MARK: - Text Change
    // Called whenever user types in the from/to field - triggers location suggestions
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updated = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

        activeField = textField
        MapKitManager.shared.updateQuery(updated)
        updateSuggestionTablePosition()

        return true
    }

    // Always allow user to edit the text fields
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { true }

    @IBAction private func locationFieldEditingChanged(_ sender: UITextField) {
        updateNextButtonState()
    }
    // Creates those pill buttons showing different route options (Fastest, Shortest, etc.)
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

            let title: String
            if index == 0 {
                title = "Fastest\n\(km) km • \(minutes) min"
            } else if index == 1 {
                title = "Shortest\n\(km) km • \(minutes) min"
            } else {
                title = "Alternative\n\(km) km • \(minutes) min"
            }

            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)

            let isSelected = (route == selectedRoute)
            button.applyRoutePill(selected: isSelected)

            let capturedIndex = index
            button.addAction(UIAction { [weak self] _ in
                guard let self, self.routes.indices.contains(capturedIndex) else { return }
                self.selectedRoute = self.routes[capturedIndex]
                self.drawRoutes()
                if let route = self.selectedRoute {
                    self.mapView.setVisibleRoute(route)
                }
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    if let route = self.selectedRoute {
                        self.mapView.setVisibleRoute(route)
                    }
                }
                for case let btn as UIButton in self.routePillsStack.arrangedSubviews {
                    btn.applyRoutePill(selected: btn.tag == capturedIndex)
                }
            }, for: .touchUpInside)

            routePillsStack.addArrangedSubview(button)
        }

        routePillsContainer.isHidden = false
    }



    // MARK: - Suggestion Selected
    // When user taps a location from the autocomplete dropdown
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
                self.updateNextButtonState()
                self.tryFetchRoutes()
            }
        }
    }

    // MARK: - Fetch Routes
    // Grabs route options from MapKit once both locations are selected
    private func tryFetchRoutes() {
        guard let f = fromCoord, let t = toCoord else { return }

        showLoading()
        MapKitManager.shared.getRoutes(from: f, to: t) { routes in
            DispatchQueue.main.async {
                self.routes = routes
                self.selectedRoute = routes.first
                guard let selected = self.selectedRoute else {
                    self.hideLoading()
                    self.emptyStateLabel.text = "No routes available for this trip"
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
            }
        }
    }



    // Draws all the route lines on the map, highlighting the selected one
    private func drawRoutes() {
        mapView.isHidden = false
        mapView.removeOverlays(mapView.overlays)

        for route in routes {
            let polyline = route.polyline
            polyline.title = (route == selectedRoute) ? "selected" : "unselected"
            mapView.addOverlay(polyline)
        }
    }

    // Shows the loading spinner while fetching routes
    private func showLoading() {
        guard !isLoadingVisible else { return }
        isLoadingVisible = true
        loadingContainer.isHidden = false
        loadingSpinner.startAnimating()
        emptyStateLabel.alpha = 0
        emptyStateLabel.isHidden = true

        if UIAccessibility.isReduceMotionEnabled {
            loadingContainer.alpha = 1
            return
        }

        loadingContainer.transform = CGAffineTransform(translationX: 0, y: 6)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.loadingContainer.alpha = 1
            self.loadingContainer.transform = .identity
        }
    }

    // Hides the loading spinner once routes are loaded
    private func hideLoading() {
        guard isLoadingVisible else { return }
        isLoadingVisible = false

        let finish = {
            self.loadingContainer.alpha = 0
            self.loadingContainer.isHidden = true
            self.loadingSpinner.stopAnimating()
        }

        if UIAccessibility.isReduceMotionEnabled {
            finish()
            return
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            self.loadingContainer.alpha = 0
        } completion: { _ in
            self.loadingSpinner.stopAnimating()
        }
    }

    // Smoothly animates in the map and route options after routes load
    private func revealRouteUI() {
        chooseRouteLabel.isHidden = false
        mapView.isHidden = false
        routePillsContainer.isHidden = false

        loadingContainer.isHidden = true

        if UIAccessibility.isReduceMotionEnabled {
            chooseRouteLabel.alpha = 1
            mapView.alpha = 1
            routePillsContainer.alpha = 1
            emptyStateLabel.alpha = 0
            emptyStateLabel.isHidden = true
            self.view.layoutIfNeeded()
            return
        }

        chooseRouteLabel.transform = CGAffineTransform(translationX: 0, y: 8)
        mapView.transform = CGAffineTransform(translationX: 0, y: 8)
        routePillsContainer.transform = CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.chooseRouteLabel.alpha = 1
            self.mapView.alpha = 1
            self.routePillsContainer.alpha = 1
            self.emptyStateLabel.alpha = 0
            self.chooseRouteLabel.transform = .identity
            self.mapView.transform = .identity
            self.routePillsContainer.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.emptyStateLabel.isHidden = true
        }
    }

    // Enables next button only when both from and to fields have values
    private func updateNextButtonState() {
        let hasFrom = !(fromTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTo = !(toTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let enabled = hasFrom && hasTo
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.4
    }



    // MARK: - Renderer
    // Styles the route lines - selected route is thick blue, others are thin gray
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay)

        if overlay.title == "selected" {
            //  Hero route
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 9
            renderer.alpha = 1.0
        } else {
            //  Background suggestions
            renderer.strokeColor = UIColor.systemGray4
            renderer.lineWidth = 4
            renderer.alpha = 0.5
        }

        renderer.lineCap = .round
        renderer.lineJoin = .round

        return renderer
    }

    // MARK: - Table DataSource
    // Returns how many location suggestions to show
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    // Fills each suggestion cell with location name and address
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "sCell")
        let r = suggestions[indexPath.row]
        cell.textLabel?.text = r.title
        cell.detailTextLabel?.text = r.subtitle
        return cell
    }

    // Positions the suggestions dropdown right below whichever text field is active
    private func updateSuggestionTablePosition() {
        guard let tf = activeField else { return }

        let frame = tf.convert(tf.bounds, to: view)

        UIView.animate(withDuration: 0.2) {
            self.suggestionsTable.frame = CGRect( x: frame.minX, y: frame.maxY + 3, width: frame.width, height: 220)
        }

    }

    // MARK: - NEXT BUTTON
    // Moves to vehicle details screen with all the route info
    @IBAction func nextTapped(_ sender: Any) {
        guard let from = fromCoord, let to = toCoord else { return }

        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VehicleDetailsViewController") as! VehicleDetailsViewController

        vc.date = datePicker.date
        vc.time = timePicker.date

        vc.source = LocationPoint(lat: from.latitude, lon: from.longitude, address: fromTextField.text)
        vc.destination = LocationPoint(lat: to.latitude, lon: to.longitude, address: toTextField.text)

        if let route = selectedRoute {
            vc.selectedRoute = MapKitManager.shared.convert(route)
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}
