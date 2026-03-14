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

    // Vehicle identity (added in Offer Ride Step 2)
    var registrationPlate: String = ""
    var vehicleModel: String = ""

    // Recurring support
    var isRecurring: Bool = false
    var recurringDays: [Int] = []  // ISO: 1=Mon … 7=Sun

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

    // MARK: - Recurring ride state
    private var isRecurring: Bool = false
    private var recurringDays: Set<Int> = []   // ISO: 1=Mon … 7=Sun

    // UI references for the recurring card (built programmatically)
    private var recurringCard: UIView?
    private var recurringSwitch: UISwitch?
    private var dayPillsStack: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Step 2"
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
        buildRecurringCard()
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

        // Show: "Car • Maruti Swift • PB-08-AB-1234" (or just "Car" if no extras saved)
        var vehicleText = summary.vehicleType
        if !summary.vehicleModel.isEmpty { vehicleText += " • " + summary.vehicleModel }
        if !summary.registrationPlate.isEmpty { vehicleText += " • " + summary.registrationPlate }
        vehicleLabel.text = vehicleText
        seatsLabel.text = "\(summary.seats) seat\(summary.seats == 1 ? "" : "s") available"

        fareLabel.text = "₹\(Int(summary.farePerSeat)) per person"
        totalLabel.text = "Total: ₹\(Int(summary.totalFare))"
    }

    // MARK: - Recurring Card
    /// Builds a "Repeat this ride" toggle card and places it on self.view
    /// below cardView. A new programmatic Offer Ride button sits below it.
    private func buildRecurringCard() {
        // ── Recurring toggle card ──────────────────────────────────────────
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = AppDesign.Radius.md
        card.layer.borderColor = AppDesign.Color.border.cgColor
        card.layer.borderWidth = 1

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Repeat this ride"
        label.font = AppDesign.Typography.bodyStrong
        label.textColor = .label

        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.onTintColor = AppDesign.Color.primary
        sw.addTarget(self, action: #selector(recurringToggled(_:)), for: .valueChanged)
        self.recurringSwitch = sw

        let days = [(1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"), (5, "Fri"), (6, "Sat"), (7, "Sun")]
        let pillsStack = UIStackView()
        pillsStack.translatesAutoresizingMaskIntoConstraints = false
        pillsStack.axis = .horizontal
        pillsStack.distribution = .fillEqually
        pillsStack.spacing = 6
        pillsStack.alpha = 0
        pillsStack.isHidden = true
        self.dayPillsStack = pillsStack

        for (iso, name) in days {
            let btn = UIButton(type: .system)
            btn.tag = iso
            btn.setTitle(name, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            btn.layer.cornerRadius = 8
            btn.clipsToBounds = true
            btn.addTarget(self, action: #selector(dayPillTapped(_:)), for: .touchUpInside)
            applyDayPillStyle(btn, selected: false)
            pillsStack.addArrangedSubview(btn)
        }

        card.addSubview(label)
        card.addSubview(sw)
        card.addSubview(pillsStack)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: sw.centerYAnchor),

            sw.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            sw.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            pillsStack.topAnchor.constraint(equalTo: sw.bottomAnchor, constant: 12),
            pillsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            pillsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            pillsStack.heightAnchor.constraint(equalToConstant: 36),
            pillsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        // Place the recurring card on self.view below cardView.
        // The storyboard offerButton stays inside cardView untouched.
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])

        self.recurringCard = card
    }



    @objc private func recurringToggled(_ sender: UISwitch) {
        isRecurring = sender.isOn
        AppHaptics.impact(.light)
        guard let stack = dayPillsStack else { return }
        if sender.isOn {
            stack.isHidden = false
            UIView.animate(withDuration: 0.25) { stack.alpha = 1 }
        } else {
            UIView.animate(withDuration: 0.2) { stack.alpha = 0 } completion: { _ in stack.isHidden = true }
            recurringDays.removeAll()
            stack.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { applyDayPillStyle($0, selected: false) }
        }
    }

    @objc private func dayPillTapped(_ sender: UIButton) {
        let iso = sender.tag
        AppHaptics.impact(.light)
        if recurringDays.contains(iso) {
            recurringDays.remove(iso)
            applyDayPillStyle(sender, selected: false)
        } else {
            recurringDays.insert(iso)
            applyDayPillStyle(sender, selected: true)
        }
    }

    private func applyDayPillStyle(_ btn: UIButton, selected: Bool) {
        btn.backgroundColor = selected ? AppDesign.Color.primary : AppDesign.Color.fieldBackground
        btn.setTitleColor(selected ? .white : .label, for: .normal)
        btn.layer.borderWidth = selected ? 0 : 1
        btn.layer.borderColor = AppDesign.Color.border.cgColor
    }

 
    @IBAction func offerTapped(_ sender: UIButton) {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            let alert = UIAlertController(title: "Not Signed In",
                                          message: "Please sign in before offering a ride.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }


        let finalDeparture = merge(summary.date, summary.time)

        let rawWaypoints = summary.route?.coordinates ?? []
        let waypoints: [LocationPoint]
        if rawWaypoints.count > 120 {
            let step = max(1, rawWaypoints.count / 100)
            waypoints = stride(from: 0, to: rawWaypoints.count, by: step).map { rawWaypoints[$0] }
        } else {
            waypoints = rawWaypoints
        }

        if isRecurring && recurringDays.isEmpty {
            let alert = UIAlertController(title: "Select Repeat Days",
                                          message: "Please select at least one weekday for this recurring ride.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
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
            notes: "",
            isRecurring: self.isRecurring,
            recurringDays: Array(self.recurringDays).sorted(),
            vehicleModel: summary.vehicleModel,
            registrationPlate: summary.registrationPlate
        )

        // Show loading state inline on the button
        var loadingCfg = offerButton.configuration ?? UIButton.Configuration.filled()
        loadingCfg.showsActivityIndicator = true
        loadingCfg.title = "Publishing…"
        offerButton.configuration = loadingCfg
        offerButton.isEnabled = false

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                var cfg = self.offerButton.configuration ?? UIButton.Configuration.filled()
                cfg.showsActivityIndicator = false
                cfg.title = "Offer Ride"
                self.offerButton.configuration = cfg
                self.offerButton.isEnabled = true
            }
            do {
                _ = try await RideDataModel.shared.createRideAndPublishAsync(ride)
                NotificationCenter.default.post(name: .ridesUpdated, object: nil)
                AppHaptics.success()
                tabBarController?.selectedIndex = 1
                navigationController?.popToRootViewController(animated: true)
            } catch {
                let alert = UIAlertController(
                    title: "Couldn't publish ride",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
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
