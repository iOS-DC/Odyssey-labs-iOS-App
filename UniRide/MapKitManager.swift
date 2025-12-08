//
//  MapKitManager.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 08/12/25.
//


import Foundation
import MapKit

final class MapKitManager: NSObject {

    static let shared = MapKitManager()

    private let completer = MKLocalSearchCompleter()

    // Autocomplete callback
    var onSuggestionsUpdate: (([MKLocalSearchCompletion]) -> Void)?

    private override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    // MARK: - AUTOCOMPLETE
    func updateQuery(_ text: String) {
        completer.queryFragment = text
    }

    // MARK: - Convert Suggestion → Coordinate
    func resolveCompletion(_ completion: MKLocalSearchCompletion,
                           completionHandler: @escaping (MKMapItem?) -> Void) {

        let request = MKLocalSearch.Request(completion: completion)

        MKLocalSearch(request: request).start { response, error in
            completionHandler(response?.mapItems.first)
        }
    }

    // MARK: - GET ROUTES
    func getRoutes(from: CLLocationCoordinate2D,
                   to: CLLocationCoordinate2D,
                   completion: @escaping ([MKRoute]) -> Void) {

        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        req.transportType = .automobile
        req.requestsAlternateRoutes = true

        MKDirections(request: req).calculate { response, error in
            completion(response?.routes ?? [])
        }
    }

    // MARK: - Convert MKRoute → RideRoute
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

// MARK: - Completer Delegate
extension MapKitManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onSuggestionsUpdate?(completer.results)
    }
}
// MARK: - MKPolyline Helper
extension MKPolyline {
    /// Returns an array of CLLocationCoordinate2D for this polyline
    var coordinatesArray: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
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
