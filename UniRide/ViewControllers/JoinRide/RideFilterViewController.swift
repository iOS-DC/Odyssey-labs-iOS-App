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

    // MARK: UI
    private let grabber      = UIView()
    private let titleLabel   = UILabel()

    // Sort
    private let sortLabel    = UILabel()
    private let sortControl  = UISegmentedControl(
        items: RideFilter.SortOption.allCases.map { $0.label }
    )

    // Fare
    private let fareLabel    = UILabel()
    private let fareSlider   = UISlider()
    private let fareValueLbl = UILabel()

    // Seats
    private let seatsLabel   = UILabel()
    private let seatsStepper = UIStepper()
    private let seatsValueLbl = UILabel()

    // Time slot
    private let timeLabel    = UILabel()
    private var timeChips: [UIButton] = []

    // Buttons
    private let applyBtn     = UIButton(type: .system)
    private let resetBtn     = UIButton(type: .system)

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        applyCurrentFilter()
    }

    // MARK: - Build UI

    private func buildUI() {
        // Grabber
        grabber.backgroundColor = AppDesign.Color.border
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabber)

        // Title
        titleLabel.text = "Filter Rides"
        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ── Sort ──
        sortLabel.text = "SORT BY"
        styleSection(sortLabel)
        sortControl.selectedSegmentIndex = 0
        sortControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        sortControl.translatesAutoresizingMaskIntoConstraints = false

        // ── Fare ──
        fareLabel.text = "MAX FARE"
        styleSection(fareLabel)
        fareSlider.minimumValue = 0
        fareSlider.maximumValue = 500
        fareSlider.tintColor    = AppDesign.Color.primary
        fareSlider.addTarget(self, action: #selector(fareChanged), for: .valueChanged)
        fareSlider.translatesAutoresizingMaskIntoConstraints = false
        fareValueLbl.font = AppDesign.Typography.subheadline
        fareValueLbl.textAlignment = .right
        fareValueLbl.setContentHuggingPriority(.required, for: .horizontal)
        fareValueLbl.translatesAutoresizingMaskIntoConstraints = false

        let fareRow = UIStackView(arrangedSubviews: [fareSlider, fareValueLbl])
        fareRow.axis = .horizontal; fareRow.spacing = 10; fareRow.alignment = .center
        fareRow.translatesAutoresizingMaskIntoConstraints = false

        // ── Seats ──
        seatsLabel.text = "MIN SEATS"
        styleSection(seatsLabel)
        seatsStepper.minimumValue = 1; seatsStepper.maximumValue = 6
        seatsStepper.stepValue = 1; seatsStepper.value = 1
        seatsStepper.addTarget(self, action: #selector(seatsChanged), for: .valueChanged)
        seatsStepper.translatesAutoresizingMaskIntoConstraints = false
        seatsValueLbl.font = AppDesign.Typography.bodyStrong
        seatsValueLbl.text = "1"
        seatsValueLbl.setContentHuggingPriority(.required, for: .horizontal)
        seatsValueLbl.translatesAutoresizingMaskIntoConstraints = false

        let seatsRow = UIStackView(arrangedSubviews: [seatsValueLbl, seatsStepper])
        seatsRow.axis = .horizontal; seatsRow.spacing = 12; seatsRow.alignment = .center
        seatsRow.translatesAutoresizingMaskIntoConstraints = false

        // ── Time slot chips ──
        timeLabel.text = "TIME OF DAY"
        styleSection(timeLabel)
        let chipStack = UIStackView()
        chipStack.axis = .horizontal; chipStack.spacing = 8; chipStack.distribution = .fillEqually
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        for slot in RideFilter.TimeSlot.allCases {
            let btn = makeChipButton(slot.label, tag: slot.rawValue)
            timeChips.append(btn)
            chipStack.addArrangedSubview(btn)
        }

        // ── Apply / Reset ──
        applyBtn.applyProminentPrimaryCTA(title: "Apply Filters", corner: AppDesign.Radius.md)
        applyBtn.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        applyBtn.translatesAutoresizingMaskIntoConstraints = false

        resetBtn.applyTextActionStyle(color: .secondaryLabel, font: AppDesign.Typography.action)
        resetBtn.setTitle("Reset", for: .normal)
        resetBtn.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        resetBtn.translatesAutoresizingMaskIntoConstraints = false

        let btnRow = UIStackView(arrangedSubviews: [resetBtn, applyBtn])
        btnRow.axis = .horizontal; btnRow.spacing = 12; btnRow.distribution = .fill
        btnRow.translatesAutoresizingMaskIntoConstraints = false

        // Main stack
        let divider1 = separator()
        let divider2 = separator()
        let divider3 = separator()

        let mainStack = UIStackView(arrangedSubviews: [
            sortLabel, sortControl, divider1,
            fareLabel, fareRow, divider2,
            seatsLabel, seatsRow, divider3,
            timeLabel, chipStack,
        ])
        mainStack.axis = .vertical
        mainStack.spacing = AppDesign.Spacing.sm - AppDesign.Spacing.xxs / 2
        mainStack.setCustomSpacing(16, after: sortControl)
        mainStack.setCustomSpacing(16, after: fareRow)
        mainStack.setCustomSpacing(16, after: seatsRow)
        mainStack.setCustomSpacing(16, after: timeLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        [mainStack, btnRow].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),

            mainStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppDesign.Spacing.lg),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),

            chipStack.heightAnchor.constraint(equalToConstant: 40),

            btnRow.topAnchor.constraint(equalTo: mainStack.bottomAnchor, constant: AppDesign.Spacing.xl),
            btnRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            btnRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),
            btnRow.heightAnchor.constraint(equalToConstant: 48),

            applyBtn.widthAnchor.constraint(equalTo: btnRow.widthAnchor, multiplier: 0.68),
        ])
    }

    // MARK: - Helpers

    private func styleSection(_ label: UILabel) {
        label.font = AppDesign.Typography.captionStrong
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    private func separator() -> UIView {
        let v = UIView()
        v.backgroundColor = AppDesign.Color.border
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

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
        btn.translatesAutoresizingMaskIntoConstraints = false
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

    @objc private func sortChanged() {
        currentFilter.sortBy = RideFilter.SortOption(rawValue: sortControl.selectedSegmentIndex) ?? .departureTime
    }

    @objc private func fareChanged() {
        // Snap to nearest 10
        let snapped = (fareSlider.value / 10).rounded() * 10
        fareSlider.value = snapped
        currentFilter.maxFare = Double(snapped)
        fareValueLbl.text = snapped >= 500 ? "Any" : "≤ ₹\(Int(snapped))"
    }

    @objc private func seatsChanged() {
        let v = Int(seatsStepper.value)
        currentFilter.minSeats = v
        seatsValueLbl.text = "\(v)"
    }

    @objc private func timeChipTapped(_ sender: UIButton) {
        AppHaptics.selection()
        currentFilter.timeSlot = RideFilter.TimeSlot(rawValue: sender.tag) ?? .any
        updateChipSelection(selected: sender.tag)
    }

    @objc private func applyTapped() {
        onApply?(currentFilter)
        dismiss(animated: true)
    }

    @objc private func resetTapped() {
        currentFilter = RideFilter()
        applyCurrentFilter()
        onApply?(currentFilter)
        dismiss(animated: true)
    }
}
