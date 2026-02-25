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

        // Cell itself is transparent — cardView is the visual card
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Shadow on cardView (XIB already sets cornerRadius=20, masksToBounds=NO)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.10
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 10

        // hostImageView appearance set in XIB
        hostImageView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Shadow path hugs the rounded card edges
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
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

        let cancelTitle: String
        if isConfirmed {
            if ride.status == .ongoing {
                // Trip is live — show trip started badge, disable cancel
                requestStatusLabel.text = "  🚗 Trip Started  "
                requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                requestStatusLabel.textColor = .white
                cancelTitle = "Cancel Booking"
                cancelRequestButton.isEnabled = false
                cancelRequestButton.alpha = 0.4
            } else {
                requestStatusLabel.text = "  ✓ Confirmed  "
                requestStatusLabel.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
                requestStatusLabel.textColor = .white
                cancelTitle = "Cancel Booking"
                cancelRequestButton.isEnabled = true
                cancelRequestButton.alpha = 1.0
            }
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
            cancelTitle = "Cancel Request"
        }

        requestStatusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        requestStatusLabel.layer.cornerRadius = 13
        requestStatusLabel.layer.masksToBounds = true
        requestStatusLabel.textAlignment = .center

        // Host info
        configureHostInfo(driverID: ride.driverUserID)

        // MARK: - Button Styles (matching Hosting card)

        // Message — tinted blue with chat icon
        messageButton.backgroundColor = .clear
        var msgConfig = UIButton.Configuration.tinted()
        msgConfig.title = "Message"
        msgConfig.image = UIImage(systemName: "message.fill")
        msgConfig.imagePlacement = .leading
        msgConfig.imagePadding = 4
        msgConfig.baseBackgroundColor = .systemBlue
        msgConfig.baseForegroundColor = .systemBlue
        msgConfig.cornerStyle = .capsule
        messageButton.configuration = msgConfig

        // ── Unread badge on Chat button
        applyUnreadBadge(to: messageButton, rideID: ride.id.uuidString)

        // Call — tinted blue with phone icon
        callButton.backgroundColor = .clear
        var callConfig = UIButton.Configuration.tinted()
        callConfig.title = "Call"
        callConfig.image = UIImage(systemName: "phone.fill")
        callConfig.imagePlacement = .leading
        callConfig.imagePadding = 4
        callConfig.baseBackgroundColor = .systemBlue
        callConfig.baseForegroundColor = .systemBlue
        callConfig.cornerStyle = .capsule
        callButton.configuration = callConfig

        // Cancel — tinted red (soft pink background)
        cancelRequestButton.backgroundColor = .clear
        var cancelConfig = UIButton.Configuration.tinted()
        cancelConfig.title = cancelTitle
        cancelConfig.baseBackgroundColor = .systemRed
        cancelConfig.baseForegroundColor = .systemRed
        cancelConfig.cornerStyle = .capsule
        cancelRequestButton.configuration = cancelConfig
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

    // MARK: - Unread Badge
    private func applyUnreadBadge(to button: UIButton, rideID: String) {
        let tag = 9901
        button.subviews.first(where: { $0.tag == tag })?.removeFromSuperview()
        let count = ChatDataModel.shared.unreadCount(for: rideID)
        guard count > 0 else { return }
        let badge = UILabel()
        badge.tag = tag
        badge.text = count > 99 ? "99+" : "\(count)"
        badge.font = .boldSystemFont(ofSize: 10)
        badge.textColor = .white
        badge.backgroundColor = .systemRed
        badge.textAlignment = .center
        badge.layer.cornerRadius = 9
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: button.topAnchor, constant: -5),
            badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 5),
            badge.heightAnchor.constraint(equalToConstant: 18),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])
    }
}
