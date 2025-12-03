import Foundation
import CoreLocation

extension Notification.Name {
    static let LocationServiceDidUpdate = Notification.Name("LocationServiceDidUpdate")
}

final class LocationService: NSObject {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private(set) var lastLocation: CLLocation?

    // Configure how live you want updates
    // distanceFilter: minimum movement (meters) to trigger an update
    // desiredAccuracy: choose between bestForNavigation/best/nearestTenMeters, etc.
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

    // Call this if you truly need background updates (also update Info.plist and capabilities)
    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    // MARK: - Live Tracking Controls

    func startLiveUpdates() {
        // If authorization is not yet granted, request it first
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func stopLiveUpdates() {
        manager.stopUpdatingLocation()
    }

    // Lower power alternative (no continuous GPS, wakes on significant changes)
    func startSignificantChangeUpdates() {
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopSignificantChangeUpdates() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - Helper to persist and broadcast

    private func handleNewLocation(_ location: CLLocation) {
        lastLocation = location

        // Persist into your existing user model as savedHomeLocation
        let point = LocationPoint(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            address: nil
        )
        UserDataModel.shared.updateUserLocation(point)

        // Broadcast to interested screens
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
            // Optionally auto-start after auth if desired
            break
        case .denied, .restricted:
            // You can post a notification or handle UI here
            break
        case .notDetermined:
            break
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
