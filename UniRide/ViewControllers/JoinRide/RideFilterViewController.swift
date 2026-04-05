import UIKit

// MARK: - Filter Model

struct RideFilter {
    var sortBy: SortOption    = .departureTime
    var maxFare: Double       = 500
    var minSeats: Int         = 1
    var timeSlot: TimeSlot    = .any

    enum SortOption: Int, CaseIterable {
        case departureTime, fare, seats
        var label: String {
            switch self {
            case .departureTime: return "Earliest"
            case .fare:          return "Cheapest"
            case .seats:         return "Most Seats"
            }
        }
    }

    enum TimeSlot: Int, CaseIterable {
        case any, morning, afternoon, evening
        var label: String {
            switch self {
            case .any:       return "Any"
            case .morning:   return "🌅 Morning"
            case .afternoon: return "☀️ Afternoon"
            case .evening:   return "🌆 Evening"
            }
        }
        /// Hour range (24h) for filtering departure time
        var hourRange: ClosedRange<Int>? {
            switch self {
            case .any:       return nil
            case .morning:   return 5...11
            case .afternoon: return 12...16
            case .evening:   return 17...22
            }
        }
    }

    var isDefault: Bool {
        sortBy == .departureTime && maxFare == 500 && minSeats == 1 && timeSlot == .any
    }

    /// Apply this filter + sort to a rides array
    func apply(to rides: [Ride]) -> [Ride] {
        var result = rides.filter { ride in
            guard ride.farePerSeat <= maxFare else { return false }
            guard ride.seatsAvailable >= minSeats else { return false }
            if let range = timeSlot.hourRange {
                let hour = Calendar.current.component(.hour, from: ride.departureTime)
                guard range.contains(hour) else { return false }
            }
            return true
        }
        switch sortBy {
        case .departureTime: result.sort { $0.departureTime < $1.departureTime }
        case .fare:          result.sort { $0.farePerSeat < $1.farePerSeat }
        case .seats:         result.sort { $0.seatsAvailable > $1.seatsAvailable }
        }
        return result
    }
}

// MARK: - View Controller

final class RideFilterViewController: UIViewController {

    var currentFilter = RideFilter()
    var onApply: ((RideFilter) -> Void)?

    // MARK: IBOutlets (wired in RideFilter.storyboard)
    @IBOutlet private var sortControl: UISegmentedControl!
    @IBOutlet private var fareSlider: UISlider!
    @IBOutlet private var fareValueLbl: UILabel!
    @IBOutlet private var seatsStepper: UIStepper!
    @IBOutlet private var seatsValueLbl: UILabel!
    @IBOutlet private var chipStack: UIStackView!
    @IBOutlet private var applyBtn: UIButton!
    @IBOutlet private var resetBtn: UIButton!

    private var timeChips: [UIButton] = []

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        fareSlider.tintColor = AppDesign.Color.primary
        applyBtn.applyProminentPrimaryCTA(title: "Apply Filters", corner: AppDesign.Radius.md)
        resetBtn.applyTextActionStyle(color: .secondaryLabel, font: AppDesign.Typography.action)
        resetBtn.setTitle("Reset", for: .normal)
        for slot in RideFilter.TimeSlot.allCases {
            let btn = makeChipButton(slot.label, tag: slot.rawValue)
            timeChips.append(btn)
            chipStack.addArrangedSubview(btn)
        }
        applyCurrentFilter()
    }

    // MARK: - Helpers

    private func makeChipButton(_ title: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = AppDesign.Typography.caption
        btn.layer.cornerRadius = AppDesign.Radius.sm
        btn.layer.borderWidth  = 1.5
        btn.layer.borderColor  = AppDesign.Color.border.cgColor
        btn.backgroundColor    = AppDesign.Color.fieldBackground
        btn.setTitleColor(.secondaryLabel, for: .normal)
        btn.tag = tag
        btn.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func applyCurrentFilter() {
        sortControl.selectedSegmentIndex = currentFilter.sortBy.rawValue
        fareSlider.value  = Float(currentFilter.maxFare)
        fareValueLbl.text = "≤ ₹\(Int(currentFilter.maxFare))"
        seatsStepper.value = Double(currentFilter.minSeats)
        seatsValueLbl.text = "\(currentFilter.minSeats)"
        updateChipSelection(selected: currentFilter.timeSlot.rawValue)
    }

    private func updateChipSelection(selected tag: Int) {
        for btn in timeChips {
            let isSelected = btn.tag == tag
            UIView.animate(withDuration: 0.18) {
                if isSelected {
                    btn.backgroundColor    = AppDesign.Color.primary.withAlphaComponent(0.12)
                    btn.layer.borderColor  = AppDesign.Color.primary.cgColor
                    btn.setTitleColor(AppDesign.Color.primary, for: .normal)
                } else {
                    btn.backgroundColor    = AppDesign.Color.fieldBackground
                    btn.layer.borderColor  = AppDesign.Color.border.cgColor
                    btn.setTitleColor(.secondaryLabel, for: .normal)
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction private func sortChanged() {
        currentFilter.sortBy = RideFilter.SortOption(rawValue: sortControl.selectedSegmentIndex) ?? .departureTime
    }

    @IBAction private func fareChanged() {
        // Snap to nearest 10
        let snapped = (fareSlider.value / 10).rounded() * 10
        fareSlider.value = snapped
        currentFilter.maxFare = Double(snapped)
        fareValueLbl.text = snapped >= 500 ? "Any" : "≤ ₹\(Int(snapped))"
    }

    @IBAction private func seatsChanged() {
        let v = Int(seatsStepper.value)
        currentFilter.minSeats = v
        seatsValueLbl.text = "\(v)"
    }

    @objc private func timeChipTapped(_ sender: UIButton) {
        AppHaptics.selection()
        currentFilter.timeSlot = RideFilter.TimeSlot(rawValue: sender.tag) ?? .any
        updateChipSelection(selected: sender.tag)
    }

    @IBAction private func applyTapped() {
        onApply?(currentFilter)
        dismiss(animated: true)
    }

    @IBAction private func resetTapped() {
        currentFilter = RideFilter()
        applyCurrentFilter()
        onApply?(currentFilter)
        dismiss(animated: true)
    }
}
