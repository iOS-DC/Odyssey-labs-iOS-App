////
////  OfferRideViewController.swift
////  UniRide
////
////  Created by Krish Bahukhandi on 21/11/25.
////



import UIKit
import MapKit

class OfferRideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate,MKMapViewDelegate, RoutesBottomSheetDelegate {

    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var suggestionsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!

    private let datePicker = UIDatePicker()
    private let timePicker = UIDatePicker()

    private var fromCoord: CLLocationCoordinate2D?
    private var toCoord: CLLocationCoordinate2D?
    private var activeField: UITextField?

    private var suggestions: [MKLocalSearchCompletion] = []
    private var routes: [MKRoute] = []
    private var selectedRoute: MKRoute?

    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultDateAndTime()
        addIcon("mappin.and.ellipse", to: fromTextField)
        addIcon("mappin.circle", to: toTextField)
        addIcon("calendar", to: dateTextField)
        addIcon("clock", to: timeTextField)

        setupUI()
        setupAutocomplete()
        setupPickers()
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

    func addIcon(_ name: String, to tf: UITextField) {
        let icon = UIImageView(image: UIImage(systemName: name))
        icon.tintColor = .systemGray
        icon.frame = CGRect(x: 8, y: 0, width: 22, height: 22)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 30))
        container.addSubview(icon)
        icon.center = container.center

        tf.leftView = container
        tf.leftViewMode = .always

        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray4.cgColor
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
        guard let f = fromCoord, let t = toCoord else {
            return
        }
        

        MapKitManager.shared.getRoutes(from: f, to: t) { routes in
            DispatchQueue.main.async {
                self.routes = routes
                self.selectedRoute = routes.first
                self.drawRoutes()
                if let firstRoute = routes.first {
                    self.mapView.setVisibleRoute(firstRoute)
                }
                self.presentRouteSheet()
            }
        }
        
    }

    private func drawRoutes() {
        mapView.isHidden = false
        mapView.removeOverlays(mapView.overlays)

        for r in routes {
            mapView.addOverlay(r.polyline)
        }
    }

    // MARK: - Renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay)

        if let route = routes.first(where: { $0.polyline === overlay }) {
            if route === selectedRoute {
                renderer.strokeColor = .systemGreen
                renderer.lineWidth = 6
            } else {
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.4)
                renderer.lineWidth = 4
            }
        }

        return renderer
    }

    // MARK: - Bottom Sheet
    private func presentRouteSheet() {
        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RoutesBottomSheetViewController") as! RoutesBottomSheetViewController

        vc.routes = routes
        vc.delegate = self

        present(vc, animated: true)
    }

    func routesBottomSheet(_ sheet: RoutesBottomSheetViewController, didSelectRouteAt index: Int) {

        selectedRoute = routes[index]
        drawRoutes()
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


