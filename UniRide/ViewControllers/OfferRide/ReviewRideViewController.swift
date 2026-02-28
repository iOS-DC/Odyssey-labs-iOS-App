import UIKit
import MapKit
struct RideSummary {
    let from: LocationPoint
    let to: LocationPoint
    let date: Date
    let time: Date
    let route: RideRoute?
    let vehicleType: String
    let seats: Int
    let farePerSeat: Double

    var totalFare: Double {
        return farePerSeat * Double(seats)
    }
}
struct DateFormatterHelper {

    static let shared = DateFormatterHelper()

    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
    }

    func formattedDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}


class ReviewRideViewController: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var vehicleLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var fareLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var offerButton: UIButton!

    var summary: RideSummary!

    override func viewDidLoad() {
        super.viewDidLoad()
        cardView.applyCardStyle()
        let offerTitle = offerButton.currentTitle ?? "Offer Ride"
        offerButton.applyProminentPrimaryCTA(title: offerTitle, corner: AppDesign.Radius.md)
        fromLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 0)
        toLabel.applyTextStyle(AppDesign.Typography.body, color: .secondaryLabel, lines: 0)
        dateLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        timeLabel.applyTextStyle(AppDesign.Typography.body)
        vehicleLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        seatsLabel.applyTextStyle(AppDesign.Typography.body)
        fareLabel.applyTextStyle(AppDesign.Typography.body, lines: 0)
        totalLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 0)
        
        fillSummary()
    }


    func fillSummary() {
        // Only fare/total labels need multi-line wrapping
        fareLabel.numberOfLines = 0
        fareLabel.lineBreakMode = .byWordWrapping
        totalLabel.numberOfLines = 0
        totalLabel.lineBreakMode = .byWordWrapping

        // Ensure the "To" subtitle is always visible
        toLabel.isHidden = false

        fromLabel.text = "From \(summary.from.address ?? "")"
        toLabel.text = "To \(summary.to.address ?? "")"

        dateLabel.text = DateFormatterHelper.shared.formattedDate(summary.date)
        timeLabel.text = DateFormatterHelper.shared.formattedTime(summary.time)

        vehicleLabel.text = summary.vehicleType
        seatsLabel.text = "\(summary.seats) seat\(summary.seats == 1 ? "" : "s") available"

        fareLabel.text = "₹\(Int(summary.farePerSeat)) per person"
        totalLabel.text = "Total: ₹\(Int(summary.totalFare))"
    }

 
    @IBAction func offerTapped(_ sender: UIButton) {

         guard let user = UserDataModel.shared.getCurrentUser() else {
             print("[ReviewRide] no current user; cannot create ride")
             return
         }

         let finalDeparture = merge(summary.date, summary.time)

         // Use route waypoints if available; sample if too many points
         let rawWaypoints = summary.route?.coordinates ?? []
         let waypoints: [LocationPoint]
         if rawWaypoints.count > 120 {
             // sample roughly 80-120 points max for storage efficiency
             let step = max(1, rawWaypoints.count / 100)
             waypoints = stride(from: 0, to: rawWaypoints.count, by: step).map { rawWaypoints[$0] }
         } else {
             waypoints = rawWaypoints
         }

         let ride = Ride(
             driverUserID: user.id,
             source: summary.from,
             destination: summary.to,
             waypoints: waypoints,
             selectedRoute: summary.route,
             departureTime: finalDeparture,
             seatsTotal: summary.seats,
             farePerSeat: summary.farePerSeat,
             status: .published,
             notes: ""
         )

         // Save + publish
         RideDataModel.shared.createRide(ride)
         // Ensure model helper marks it published (redundant because we set status .published,
         // but calling publishRide keeps logic consistent if you have checks there)
         RideDataModel.shared.publishRide(id: ride.id)

         // Notify observers so lists refresh immediately
         NotificationCenter.default.post(name: .ridesUpdated, object: nil)
         AppHaptics.success()

         // Debug logs to confirm times present
         if let rt = ride.selectedRoute {
             print("[ReviewRide] created ride id:", ride.id.uuidString,
                   "expectedTravelTime(s):", rt.expectedTravelTime,
                   "distance(m):", rt.distanceMeters,
                   "waypoints:", waypoints.count)
         } else {
             print("[ReviewRide] created ride WITHOUT selectedRoute (fallback travel time will be used).")
         }

         // Navigate back to MyRides tab
         tabBarController?.selectedIndex = 1
         navigationController?.popToRootViewController(animated: true)
     }
    func merge(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current

        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let t = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = d.year
        components.month = d.month
        components.day = d.day
        components.hour = t.hour
        components.minute = t.minute

        return calendar.date(from: components) ?? date
    }

}
