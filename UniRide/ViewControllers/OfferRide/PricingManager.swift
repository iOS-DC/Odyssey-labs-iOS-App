import Foundation

final class PricingManager {

    static let shared = PricingManager()
    private init() {}

    // MARK: - Suggested Fare

    /// Returns a suggested per-seat fare (rounded to nearest ₹5).
    /// - Parameters:
    ///   - distanceMeters: Route distance in metres.
    ///   - seats: Number of seats the driver is offering.
    ///   - vehicle: "car" or "bike" (case-insensitive).
    ///   - departureTime: Used to apply a peak-hour surcharge.
    func suggestedFare(distanceMeters: Double,
                       seats: Int,
                       vehicle: String,
                       departureTime: Date = Date()) -> Int {

        let distanceKm = max(distanceMeters / 1000, 1)   // minimum 1 km
        let isCarType  = vehicle.lowercased() == "car"

        // Base rate per km
        var ratePerKm: Double = isCarType ? 9.5 : 6.0

        // Peak-hour surcharge (+20%) — morning 7-9 am, evening 4-7 pm
        if isPeakHour(departureTime) {
            ratePerKm *= 1.20
        }

        // Raw total fare (driver covers whole ride cost)
        var total = distanceKm * ratePerKm

        // Minimum fares
        total = max(total, isCarType ? 40.0 : 25.0)

        // Split across seats
        let perSeat = total / Double(max(seats, 1))

        // Round to nearest ₹5
        return Int((perSeat / 5).rounded() * 5)
    }

    // MARK: - Helpers

    func isPeakHour(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return (hour >= 7 && hour < 9) || (hour >= 16 && hour < 19)
    }
}
