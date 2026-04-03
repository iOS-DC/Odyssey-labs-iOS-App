


import Foundation
import MapKit

final class MapKitManager: NSObject {

    static let shared = MapKitManager()
    static let indiaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.9734, longitude: 78.6569),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )

    private let completer = MKLocalSearchCompleter()

    // Autocomplete callback
    var onSuggestionsUpdate: (([MKLocalSearchCompletion]) -> Void)?

    private override init() {
        super.init()
        completer.delegate = self
        completer.region = Self.indiaRegion
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ text: String) {
        completer.queryFragment = text /// queryFragment triggers autocomplete.
    }

    /// Converting  Suggestion → Actual Coordinate
    func resolveCompletion(_ completion: MKLocalSearchCompletion, completionHandler: @escaping (MKMapItem?) -> Void) {

        let request = MKLocalSearch.Request(completion: completion)
        request.region = Self.indiaRegion
        request.resultTypes = [.address, .pointOfInterest]
        request.pointOfInterestFilter = .includingAll

        MKLocalSearch(request: request).start {
            response, _ in
            let itemInIndia = response?.mapItems.first(where: Self.isInIndia)
            completionHandler(itemInIndia)
        }
    }

    func filterCompletionsToIndia(_ completions: [MKLocalSearchCompletion], completion: @escaping ([MKLocalSearchCompletion]) -> Void) {
        guard !completions.isEmpty else {
            completion([])
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var filtered: [(index: Int, completion: MKLocalSearchCompletion)] = []

        for (index, item) in completions.enumerated() {
            group.enter()
            resolveCompletion(item) { resolved in
                defer { group.leave() }
                guard resolved != nil else { return }
                lock.lock()
                filtered.append((index, item))
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            completion(filtered.sorted { $0.index < $1.index }.map(\.completion))
        }
    }

    static func isInIndia(_ item: MKMapItem) -> Bool {
        item.placemark.isoCountryCode == "IN"
    }

    /// Finding ROUTES between the two points
    func getRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: @escaping ([MKRoute]) -> Void) { /// @escaping means that we will call this function later we dont need it rn & ([MKRoute]) -> Void means a function (closure) that takes a list of routes ([MKRoute]) and doesn’t return anything

        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        req.transportType = .automobile
        req.requestsAlternateRoutes = true

        MKDirections(request: req).calculate {
            response, error in completion(response?.routes ?? [])
        }
    }

    /// Convert MKRoute → RideRoute
    func convert(_ route: MKRoute) -> RideRoute {
        let coords = route.polyline.coordinatesArray
        let points = coords.map {
            LocationPoint(lat: $0.latitude, lon: $0.longitude, address: nil)
        }

        return RideRoute(
            coordinates: points,
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
    }
}

/// Completer Delegate. This is called automatically when suggestions refresh.
extension MapKitManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onSuggestionsUpdate?(completer.results)
    }
}
/// MKPolyline Helper ->
extension MKPolyline {
    /// Returns an array of CLLocationCoordinate2D for the route
    var coordinatesArray: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid, //this constant is used when we want to indicate that a coordinate is invalid.
            count: self.pointCount
        )
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

extension MKMapView {
    func setVisibleRoute(_ route: MKRoute, edge: UIEdgeInsets = UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)) {

        let rect = route.polyline.boundingMapRect
        let limitedRect = rect.insetBy(dx: -5000, dy: -5000)  // prevents extreme zoom-out

        self.setVisibleMapRect(
            limitedRect,
            edgePadding: edge,
            animated: true
        )
    }
}
