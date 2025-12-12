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
        didSet {
            manager.distanceFilter = distanceFilter
        }
    }/// we are using this so that we can set the minimum movement before next update
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest {
        didSet {
            manager.desiredAccuracy = desiredAccuracy
        }
    }

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
    }

    

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization() ///This triggers the iOS system popup for permission
    }

    func startLiveUpdates() {
        let status = manager.authorizationStatus
        /// If the user did not got the pop up or the status for permission is not set yet it will ask again.
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation() ///We are asking  iOS to start giving us location continuously
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
        print(point.lat)
        print(point.lon)
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
            print("Location permission denied.")
            
            /// Sends the nil value for location
            NotificationCenter.default.post(name: .LocationServiceDidUpdate, object: nil)

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // iOS sends an array of locations but we want the newest one so we will just take last
        guard let loc = locations.last else {
            return
        }
        handleNewLocation(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService error:", error.localizedDescription)
    }
}
