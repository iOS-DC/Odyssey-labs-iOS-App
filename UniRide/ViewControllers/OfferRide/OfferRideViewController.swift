////
////  OfferRideViewController.swift
////  UniRide
////
////  Created by Krish Bahukhandi on 21/11/25.
////



import UIKit
import MapKit

class OfferRideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate,MKMapViewDelegate {

    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var suggestionsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!

    @IBOutlet weak var routePillsStack: UIStackView!
    @IBOutlet weak var routePillsContainer: UIView!
    private let datePicker = UIDatePicker()
    private let timePicker = UIDatePicker()

    private var fromCoord: CLLocationCoordinate2D?
    private var toCoord: CLLocationCoordinate2D?
    private var activeField: UITextField?

    private var suggestions: [MKLocalSearchCompletion] = []
    private var routes: [MKRoute] = []
    // Persistent Routes Sheet
    

    private var selectedRoute: MKRoute?

    @IBOutlet weak var contentView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultDateAndTime()

        contentView.applyCardStyle()
        setupUI()
        setupAutocomplete()
        setupPickers()
        routePillsContainer.applySmallCard()

    }
    private func setDefaultDateAndTime() {
        // Set default date
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        dateTextField.text = df.string(from: Date())

        // Set default time
        let tf = DateFormatter()
        tf.dateFormat = "hh:mm a"
        timeTextField.text = tf.string(from: Date())
    }

    private func setupUI() {
        suggestionsTable.dataSource = self
        suggestionsTable.delegate = self
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = true
        suggestionsTable.layer.cornerRadius = 12
        suggestionsTable.layer.shadowOpacity = 0.1
        suggestionsTable.layer.shadowRadius = 6
        suggestionsTable.backgroundColor = .lightGray
        mapView.delegate = self
        
        mapView.layer.cornerRadius = 16
        mapView.layer.shadowColor = UIColor.black.cgColor
        mapView.layer.shadowOpacity = 0.08
        mapView.layer.shadowRadius = 10
        mapView.layer.shadowOffset = CGSize(width: 0, height: 4)

    }

    private func setupAutocomplete() {
        

        MapKitManager.shared.onSuggestionsUpdate = { results in
            self.suggestions = results
            self.suggestionsTable.reloadData()
            self.suggestionsTable.isHidden = results.isEmpty
        }

        fromTextField.delegate = self
        toTextField.delegate = self
    }

    // MARK: - Setup Pickers
    private func setupPickers() {

        // DATE PICKER
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        datePicker.date = Date()   // start from today
        
        let dateToolbar = UIToolbar()
        dateToolbar.sizeToFit()
        dateToolbar.setItems([ UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelectingDate))
        ], animated: true)

        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = dateToolbar


        // TIME PICKER
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.date = Date()  // start with current time
        
        let timeToolbar = UIToolbar()
        timeToolbar.sizeToFit()
        timeToolbar.setItems([
            UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelectingTime))
        ], animated: true)

        timeTextField.inputView = timePicker
        timeTextField.inputAccessoryView = timeToolbar
    }

    @objc private func doneSelectingDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: datePicker.date)
        dateTextField.resignFirstResponder()
    }

    @objc private func doneSelectingTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        timeTextField.text = formatter.string(from: timePicker.date)
        timeTextField.resignFirstResponder()
    }


    // MARK: - Text Change
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let updated = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

        activeField = textField
        MapKitManager.shared.updateQuery(updated)
        updateSuggestionTablePosition()

        return true
    }
    private func buildRoutePills() {
        routePillsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
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

            button.addTarget(self, action: #selector(routePillTapped(_:)), for: .touchUpInside)

            routePillsStack.addArrangedSubview(button)
        }

        routePillsContainer.isHidden = false
    }

    
    @objc private func routePillTapped(_ sender: UIButton) {
        selectedRoute = routes[sender.tag]

        drawRoutes()
        mapView.setVisibleRoute(selectedRoute!)
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5) {
            self.mapView.setVisibleRoute(self.selectedRoute!)
        }
            
        // Update pill states
        for case let btn as UIButton in routePillsStack.arrangedSubviews {
            btn.applyRoutePill(selected: btn.tag == sender.tag)
        }
    }

    // MARK: - Suggestion Selected
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
                self.tryFetchRoutes()
            }
        }
    }

    // MARK: - Fetch Routes
    private func tryFetchRoutes() {
        guard let f = fromCoord, let t = toCoord else { return }

        MapKitManager.shared.getRoutes(from: f, to: t) { routes in
            DispatchQueue.main.async {
                self.routes = routes
                self.selectedRoute = routes.first

                self.drawRoutes()
                self.mapView.setVisibleRoute(self.selectedRoute!)

                self.buildRoutePills()
            }
        }
    }



    private func drawRoutes() {
        mapView.isHidden = false
        mapView.removeOverlays(mapView.overlays)

        for route in routes {
            let polyline = route.polyline
            polyline.title = (route == selectedRoute) ? "selected" : "unselected"
            mapView.addOverlay(polyline)
        }
    }

    // MARK: - Renderer
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "sCell")
        let r = suggestions[indexPath.row]
        cell.textLabel?.text = r.title
        cell.detailTextLabel?.text = r.subtitle
        return cell
    }

    private func updateSuggestionTablePosition() {
        guard let tf = activeField else { return }

        let frame = tf.convert(tf.bounds, to: view)

        UIView.animate(withDuration: 0.2) {
            self.suggestionsTable.frame = CGRect( x: frame.minX, y: frame.maxY + 3, width: frame.width, height: 220)
        }

    }

    // MARK: - NEXT BUTTON
    @IBAction func nextTapped(_ sender: Any) {

        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VehicleDetailsViewController") as! VehicleDetailsViewController

        vc.date = datePicker.date
        vc.time = timePicker.date

        vc.source = LocationPoint(lat: fromCoord!.latitude, lon: fromCoord!.longitude, address: fromTextField.text)
        vc.destination = LocationPoint(lat: toCoord!.latitude, lon: toCoord!.longitude, address: toTextField.text)

        if let route = selectedRoute {
            vc.selectedRoute = MapKitManager.shared.convert(route)
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}


