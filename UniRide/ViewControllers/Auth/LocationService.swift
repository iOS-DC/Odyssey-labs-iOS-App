import Foundation
import CoreLocation

extension Notification.Name {
    static let LocationServiceDidUpdate = Notification.Name("LocationServiceDidUpdate")
}

final class LocationService: NSObject {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private(set) var lastLocation: CLLocation?

    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone {
        didSet { manager.distanceFilter = distanceFilter }
    }
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest {
        didSet { manager.desiredAccuracy = desiredAccuracy }
    }

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
    }

    // MARK: - Permissions

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startLiveUpdates() {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func stopLiveUpdates() {
        manager.stopUpdatingLocation()
    }

    private func handleNewLocation(_ location: CLLocation) {
        lastLocation = location

        let point = LocationPoint(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            address: nil
        )

        print("📍 SAVED LOCATION:", point.lat, point.lon)

        UserDataModel.shared.updateUserLocation(point)

        NotificationCenter.default.post(
            name: .LocationServiceDidUpdate,
            object: self,
            userInfo: ["location": location]
        )
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()

        case .denied, .restricted:
            print("⚠️ Location permission denied.")
            NotificationCenter.default.post(name: .LocationServiceDidUpdate, object: nil)

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        handleNewLocation(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService error:", error.localizedDescription)
    }
}
