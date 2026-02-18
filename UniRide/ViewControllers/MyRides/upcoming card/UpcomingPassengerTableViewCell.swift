import UIKit

final class UpcomingPassengerTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rideStatusLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var requestStatusLabel: UILabel!
    @IBOutlet weak var hostImageView: UIImageView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        // Card styling (cornerRadius, background, masksToBounds) is set in XIB.
        // Shadow must stay in code — requires masksToBounds=false on the cell layer.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        // hostImageView appearance set in XIB (contentMode, tintColor, cornerRadius via runtime attrs)
        hostImageView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: cardView.frame,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        let ride = trip.ride

        // Date
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        dateLabel.text = df.string(from: ride.departureTime)

        // Times
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)
        let travelSeconds = ride.selectedRoute?.expectedTravelTime ?? (2 * 3600)
        endTimeLabel.text = tf.string(from: ride.departureTime.addingTimeInterval(travelSeconds))
        durationLabel.text = formatDuration(travelSeconds)

        // Route
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text = ride.destination.address ?? "To"

        // Seats
        seatsLabel.text = "\(ride.seatsTotal - ride.seatsAvailable)/\(ride.seatsTotal) seats"

        // Hide ride status — we show request status instead
        rideStatusLabel.isHidden = true

        // Role badge
        roleLabel.text = "  Passenger  "
        roleLabel.backgroundColor = .systemGray6
        roleLabel.textColor = .secondaryLabel
        roleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        roleLabel.layer.cornerRadius = 13
        roleLabel.layer.masksToBounds = true

        // Request / booking status badge
        let isConfirmed: Bool
        if let status = trip.requestStatus {
            isConfirmed = (status == .approved)
        } else {
            let me = UserDataModel.shared.getCurrentUser()
            let bookings = RideDataModel.shared.listBookings(for: ride.id)
            isConfirmed = me != nil && bookings.contains { $0.passengerUserID == me!.id && $0.status == .confirmed }
        }

        if isConfirmed {
            requestStatusLabel.text = "  ✓ Confirmed  "
            requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
            requestStatusLabel.textColor = .white
            var config = cancelRequestButton.configuration ?? UIButton.Configuration.filled()
            config.title = "Cancel Booking"
            cancelRequestButton.configuration = config
        } else {
            let (text, color): (String, UIColor) = {
                switch trip.requestStatus {
                case .pending:   return ("  Pending  ",   UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0))
                case .denied:    return ("  Denied  ",    UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0))
                case .cancelled: return ("  Cancelled  ", UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0))
                default:         return ("  Pending  ",   UIColor(red: 0.96, green: 0.61, blue: 0.07, alpha: 1.0))
                }
            }()
            requestStatusLabel.text = text
            requestStatusLabel.backgroundColor = color
            requestStatusLabel.textColor = .white
            var config = cancelRequestButton.configuration ?? UIButton.Configuration.filled()
            config.title = "Cancel Request"
            cancelRequestButton.configuration = config
        }

        requestStatusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        requestStatusLabel.layer.cornerRadius = 13
        requestStatusLabel.layer.masksToBounds = true
        requestStatusLabel.textAlignment = .center

        // Host info
        configureHostInfo(driverID: ride.driverUserID)
    }

    // MARK: - Helpers

    private func configureHostInfo(driverID: UUID) {
        guard let host = UserDataModel.shared.getUser(by: driverID) else {
            hostNameLabel.text = "Host"
            hostImageView.loadAndFallback(from: nil, name: "Host")
            return
        }

        let name = host.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = name.isEmpty ? host.email : name
        hostNameLabel.text = display
        hostImageView.loadAndFallback(from: host.photoURL, name: display)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(round(seconds / 60.0))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        else if h > 0      { return "\(h)h" }
        else               { return "\(m)m" }
    }
}
