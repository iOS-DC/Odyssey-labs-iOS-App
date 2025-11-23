//
//  OfferRideViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 21/11/25.
//


import UIKit
import MapKit

class OfferRideViewController: UIViewController,UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, MKLocalSearchCompleterDelegate {
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    let datePicker = UIDatePicker()
    let timePicker = UIDatePicker()
    let searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    // at top of OfferRideViewController class
    var availableRoutes: [MKRoute] = []
    var chosenRoute: MKRoute?

    var fromCoordinate: CLLocationCoordinate2D?
    var toCoordinate: CLLocationCoordinate2D?
    var activeTextField: UITextField?
    @IBOutlet weak var suggestionsTable: UITableView!

    override func viewDidLoad() {
            super.viewDidLoad()
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = true
            fromTextField.delegate = self
            toTextField.delegate = self

            searchCompleter.delegate = self
            mapView.delegate = self
            suggestionsTable.delegate = self
            suggestionsTable.dataSource = self
            suggestionsTable.isHidden = true
            mapView.isHidden = true

            setupDatePicker()
            setupTimePicker()
        }

        // MARK: - Date Picker
        func setupDatePicker() {
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.minimumDate = Date()

            dateTextField.inputView = datePicker

            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.setItems([UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelectingDate))], animated: true)

            dateTextField.inputAccessoryView = toolbar
        }

        @objc func doneSelectingDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            dateTextField.text = formatter.string(from: datePicker.date)
            dateTextField.resignFirstResponder()
        }

    @IBAction func nextButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "VehicleDetailsViewController") as! VehicleDetailsViewController

        vc.source = LocationPoint(lat: fromCoordinate!.latitude,
                                   lon: fromCoordinate!.longitude,
                                   address: fromTextField.text)

        vc.destination = LocationPoint(lat: toCoordinate!.latitude,
                                       lon: toCoordinate!.longitude,
                                       address: toTextField.text)

        vc.date = datePicker.date
        vc.time = timePicker.date

        if let chosen = chosenRoute {
            vc.selectedRoute = convertMKRouteToRideRoute(chosen)
        }

        navigationController?.pushViewController(vc, animated: true)

    }
    // MARK: - Time Picker
        func setupTimePicker() {
            timePicker.datePickerMode = .time
            timePicker.preferredDatePickerStyle = .wheels

            timeTextField.inputView = timePicker

            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.setItems([UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelectingTime))], animated: true)

            timeTextField.inputAccessoryView = toolbar
        }

        @objc func doneSelectingTime() {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            timeTextField.text = formatter.string(from: timePicker.date)
            timeTextField.resignFirstResponder()
        }

        // MARK: - TextField Autocomplete
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let updated = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            searchCompleter.queryFragment = updated
            activeTextField = textField
            updateSuggestionTablePosition()
            return true
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            searchResults = completer.results
            suggestionsTable.reloadData()
            suggestionsTable.isHidden = searchResults.isEmpty
        }

        // MARK: - TableView
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return searchResults.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "suggestCell")

            let result = searchResults[indexPath.row]
            cell.textLabel?.text = result.title
            cell.detailTextLabel?.text = result.subtitle

            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let result = searchResults[indexPath.row]
            let request = MKLocalSearch.Request(completion: result)

            MKLocalSearch(request: request).start { response, error in
                guard let item = response?.mapItems.first else { return }

                if self.activeTextField == self.fromTextField {
                    self.fromTextField.text = item.name
                    self.fromCoordinate = item.placemark.coordinate
                } else {
                    self.toTextField.text = item.name
                    self.toCoordinate = item.placemark.coordinate
                }

                self.suggestionsTable.isHidden = true
                self.drawRoutesIfPossible()
            }
        }

        // MARK: - Draw Routes
        func drawRoutesIfPossible() {
            guard let from = fromCoordinate, let to = toCoordinate else { return }

            mapView.isHidden = false
            mapView.removeOverlays(mapView.overlays)

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
            request.transportType = .automobile
            request.requestsAlternateRoutes = true

            MKDirections(request: request).calculate { response, error in
                guard let routes = response?.routes, !routes.isEmpty else {
                    print("No routes found or error:", error ?? "unknown")
                    return
                }

                // keep up to 4
                self.availableRoutes = Array(routes.prefix(4))

                DispatchQueue.main.async {
                    // render overlays
                    self.mapView.removeOverlays(self.mapView.overlays)
                    for route in self.availableRoutes {
                        self.mapView.addOverlay(route.polyline)
                    }

                    // default selection -> first
                    self.chosenRoute = self.availableRoutes.first

                    // zoom to first
                    if let first = self.availableRoutes.first {
                        self.mapView.setVisibleMapRect(first.polyline.boundingMapRect,
                                                       edgePadding: UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20),
                                                       animated: true)
                    }

                    // PRESENT the bottom sheet to let user choose
                    self.presentRoutesBottomSheet()
                }
            }


        }

        // MARK: - Route Renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }

        let renderer = MKPolylineRenderer(overlay: poly)

        // identify index for this polyline
        if let idx = availableRoutes.firstIndex(where: { $0.polyline === poly }) {
            // is this the chosen route?
            if let chosen = chosenRoute, availableRoutes.indices.contains(idx) && availableRoutes[idx].polyline === chosen.polyline {
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 7
            } else {
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.4)
                renderer.lineWidth = 4
            }
        } else {
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 4
        }

        return renderer
    }
    
    func convertMKRouteToRideRoute(_ route: MKRoute) -> RideRoute {
        let coords = route.polyline.coordinatesArray
        let pts = coords.map { LocationPoint(lat: $0.latitude, lon: $0.longitude, address: nil) }
        return RideRoute(coordinates: pts, distanceMeters: route.distance, expectedTravelTime: route.expectedTravelTime)
    }

    func presentRoutesBottomSheet() {
        let sb = UIStoryboard(name: "OfferRide", bundle: nil) // change if your storyboard name is different
        guard let routesVC = sb.instantiateViewController(withIdentifier: "RoutesBottomSheetViewController") as? RoutesBottomSheetViewController else {
            return
        }

        // create human labels: mark fastest (by ETA) and shortest (by distance)
        let fastestIndex = availableRoutes.enumerated().min(by: { $0.element.expectedTravelTime < $1.element.expectedTravelTime })?.offset
        let shortestIndex = availableRoutes.enumerated().min(by: { $0.element.distance < $1.element.distance })?.offset

        var labels = [String]()
        for (i, _) in availableRoutes.enumerated() {
            if i == fastestIndex { labels.append("Fastest") }
            else if i == shortestIndex { labels.append("Shortest") }
            else { labels.append("Option \(i+1)") }
        }

        routesVC.routes = availableRoutes
        routesVC.routeLabels = labels
        routesVC.delegate = self

        routesVC.modalPresentationStyle = .pageSheet
        if let sheet = routesVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(routesVC, animated: true, completion: nil)
    }

    func updateSuggestionTablePosition() {
        guard let tf = activeTextField else { return }

        // Make sure the table is front-most
        view.bringSubviewToFront(suggestionsTable)

        // Convert textfield frame into the main view coordinate system
        let frameInView = tf.convert(tf.bounds, to: self.view)

        // Place suggestion table EXACTLY under the text field
        suggestionsTable.frame = CGRect(
            x: frameInView.minX,
            y: frameInView.maxY + 4,
            width: frameInView.width,
            height: 220
        )
    }
    func highlightChosenRoute() {
        // re-add overlays so renderer can color selected vs others
        mapView.removeOverlays(mapView.overlays)
        for route in availableRoutes {
            mapView.addOverlay(route.polyline)
        }
        mapView.setNeedsDisplay()
    }


}

extension MKPolyline {
    /// Returns coordinates array for the polyline
    var coordinatesArray: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

extension OfferRideViewController: RoutesBottomSheetDelegate {
    func routesBottomSheet(_ sheet: RoutesBottomSheetViewController, didSelectRouteAt index: Int) {
        guard availableRoutes.indices.contains(index) else { return }
        chosenRoute = availableRoutes[index]
        highlightChosenRoute()
    }
}
