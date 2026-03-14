import UIKit

class VehicleDetailsViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Storyboard Outlets (kept so connections don't crash; hidden below)
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var carView: UIView!
    @IBOutlet weak var bikeView: UIView!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var maxSeatsLabel: UILabel!
    @IBOutlet weak var costTextField: UITextField!
    @IBOutlet weak var suggestedFareLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    // MARK: - Programmatic layout (Profile-style)
    private let scrollView   = UIScrollView()
    private let formStack    = UIStackView()

    // Fields
    private let plateField      = UITextField()
    private let modelField      = UITextField()

    // Vehicle type buttons
    private let carButton       = UIButton(type: .system)
    private let bikeButton      = UIButton(type: .system)

    // Seats
    private let minusSeat       = UIButton(type: .system)
    private let seatCountLbl    = UILabel()
    private let plusSeat        = UIButton(type: .system)

    // Fare
    private let fareField       = UITextField()
    private let suggestedLbl    = UILabel()

    // Next
    private let nextBtn         = UIButton(type: .system)

    // MARK: - State
    private var selectedType: VehicleType = .car {
        didSet { updateTypeButtons(); calculateSuggestedFare() }
    }
    private var seatCount: Int = 0 {
        didSet { updateSeatsUI(); calculateSuggestedFare(); validateNext() }
    }

    // Data passed from Step 1
    var source: LocationPoint?
    var destination: LocationPoint?
    var date: Date?
    var time: Date?
    var selectedRoute: RideRoute?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Step 2"
        view.backgroundColor = .systemGroupedBackground

        // Hide the storyboard container — we build our own layout
        ContainerView?.isHidden = true

        buildLayout()
        preloadVehicleIdentity()
    }

    // MARK: - Build Layout (same pattern as VehicleRegistrationViewController)
    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        formStack.axis    = .vertical
        formStack.spacing = AppDesign.Spacing.lg
        formStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(formStack)
        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.xl),
            formStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            formStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            formStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl),
            formStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.xl * 2),
        ])

        // 1. Header
        formStack.addArrangedSubview(makeHeaderLabel("Enter your vehicle information so passengers can recognise your vehicle."))

        // 2. Registration Plate
        formStack.addArrangedSubview(makeCard(title: "Registration Plate", content: makePlateField()))

        // 3. Car Model
        formStack.addArrangedSubview(makeCard(title: "Car Model", content: makeModelField()))

        // 4. Vehicle Type
        formStack.addArrangedSubview(makeCard(title: "Vehicle Type", content: makeTypeSelector()))

        // 5. Seats
        formStack.addArrangedSubview(makeCard(title: "Seats You Can Offer", content: makeSeatsControl()))

        // 6. Fare
        formStack.addArrangedSubview(makeCard(title: "Fare Per Seat (₹)", content: makeFareField()))

        // 7. Next button
        configureNextButton()
        formStack.addArrangedSubview(nextBtn)

        updateTypeButtons()
        updateSeatsUI()
    }

    // MARK: - Field factories

    private func makePlateField() -> UIView {
        plateField.placeholder            = "e.g. PB-08-AB-1234"
        plateField.autocapitalizationType = .allCharacters
        plateField.returnKeyType          = .next
        plateField.clearButtonMode        = .whileEditing
        plateField.applyRoundedField()
        plateField.font = AppDesign.Typography.body
        plateField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        plateField.delegate = self
        plateField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        return plateField
    }

    private func makeModelField() -> UIView {
        modelField.placeholder    = "e.g. Maruti Swift, Honda City"
        modelField.returnKeyType  = .done
        modelField.clearButtonMode = .whileEditing
        modelField.applyRoundedField()
        modelField.font = AppDesign.Typography.body
        modelField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        modelField.delegate = self
        modelField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        return modelField
    }

    private func makeTypeSelector() -> UIView {
        configTypeButton(carButton,  icon: "car.fill", label: "Car",         type: .car)
        configTypeButton(bikeButton, icon: "bicycle",  label: "Two-Wheeler", type: .bike)

        let row           = UIStackView(arrangedSubviews: [carButton, bikeButton])
        row.axis          = .horizontal
        row.spacing       = 12
        row.distribution  = .fillEqually
        return row
    }

    private func configTypeButton(_ btn: UIButton, icon: String, label: String, type: VehicleType) {
        var config = UIButton.Configuration.tinted()
        config.image            = UIImage(systemName: icon)
        config.title            = label
        config.imagePlacement   = .top
        config.imagePadding     = 8
        config.baseBackgroundColor = AppDesign.Color.primary
        config.baseForegroundColor = AppDesign.Color.primary
        config.cornerStyle      = .medium
        btn.configuration       = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.didSelectType(type)
        }, for: .touchUpInside)
    }

    private func makeSeatsControl() -> UIView {
        // Minus
        var minusCfg = UIButton.Configuration.filled()
        minusCfg.image                = UIImage(systemName: "minus")
        minusCfg.baseBackgroundColor  = .systemGray5
        minusCfg.baseForegroundColor  = .label
        minusCfg.cornerStyle          = .capsule
        minusSeat.configuration       = minusCfg
        minusSeat.translatesAutoresizingMaskIntoConstraints = false
        minusSeat.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        minusSeat.heightAnchor.constraint(equalToConstant: 44).isActive = true
        minusSeat.addAction(UIAction { [weak self] _ in self?.adjustSeats(-1) }, for: .touchUpInside)

        // Count label
        seatCountLbl.text          = "\(seatCount)"
        seatCountLbl.font          = AppDesign.Typography.h2
        seatCountLbl.textAlignment = .center
        seatCountLbl.widthAnchor.constraint(equalToConstant: 60).isActive = true

        // Plus
        var plusCfg = UIButton.Configuration.filled()
        plusCfg.image               = UIImage(systemName: "plus")
        plusCfg.baseBackgroundColor = AppDesign.Color.primary
        plusCfg.baseForegroundColor = .white
        plusCfg.cornerStyle         = .capsule
        plusSeat.configuration      = plusCfg
        plusSeat.translatesAutoresizingMaskIntoConstraints = false
        plusSeat.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        plusSeat.heightAnchor.constraint(equalToConstant: 44).isActive = true
        plusSeat.addAction(UIAction { [weak self] _ in self?.adjustSeats(1) }, for: .touchUpInside)

        let maxLabel = selectedType == .car ? "Maximum 4 seats" : "Maximum 1 seat"
        let hint = UILabel()
        hint.text = maxLabel
        hint.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)

        let row       = UIStackView(arrangedSubviews: [minusSeat, seatCountLbl, plusSeat])
        row.axis      = .horizontal
        row.spacing   = 16
        row.alignment = .center

        let container = UIStackView(arrangedSubviews: [row, hint])
        container.axis      = .vertical
        container.spacing   = 6
        container.alignment = .center
        return container
    }

    private func makeFareField() -> UIView {
        fareField.placeholder    = "Enter fare"
        fareField.keyboardType   = .numberPad
        fareField.clearButtonMode = .whileEditing
        fareField.applyRoundedField()
        fareField.setLeftPaddingPoints(12)
        fareField.font = AppDesign.Typography.body
        fareField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        fareField.delegate = self
        fareField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)

        suggestedLbl.text = "Suggested fare: ₹—"
        suggestedLbl.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)

        let container = UIStackView(arrangedSubviews: [fareField, suggestedLbl])
        container.axis    = .vertical
        container.spacing = 6
        return container
    }

    private func configureNextButton() {
        nextBtn.setTitle("Next", for: .normal)
        nextBtn.applyPrimaryButton(color: AppDesign.Color.primary, radius: AppDesign.Radius.sm)
        nextBtn.setPrimaryCTAEnabled(false)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    // MARK: - Card wrapper (same as VehicleRegistrationViewController)
    private func makeCard(title: String, content: UIView) -> UIView {
        let card = UIView()
        card.applyCardStyle(corner: AppDesign.Radius.md,
                            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                            shadowRadius: AppDesign.Shadow.smallCardRadius)

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)

        let stack      = UIStackView(arrangedSubviews: [titleLbl, content])
        stack.axis     = .vertical
        stack.spacing  = AppDesign.Spacing.sm - AppDesign.Spacing.xxs / 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: AppDesign.Spacing.md),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.md),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.md),
        ])
        return card
    }

    private func makeHeaderLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel, lines: 0)
        lbl.numberOfLines = 0
        return lbl
    }

    // MARK: - Actions

    private func didSelectType(_ type: VehicleType) {
        selectedType = type
        // Reset seats when vehicle type changes
        seatCount = 0
    }

    private func updateTypeButtons() {
        let isCarSelected = selectedType == .car
        [carButton, bikeButton].forEach { btn in
            let isSel = (btn == carButton) ? isCarSelected : !isCarSelected
            btn.configuration?.baseBackgroundColor = isSel ? AppDesign.Color.primary : AppDesign.Color.fieldBackground
            btn.configuration?.baseForegroundColor = isSel ? AppDesign.Color.primary : .secondaryLabel
            btn.layer.borderWidth  = isSel ? 2 : 0
            btn.layer.borderColor  = isSel ? AppDesign.Color.primary.cgColor : nil
            btn.layer.cornerRadius = AppDesign.Radius.sm
        }
    }

    private func adjustSeats(_ delta: Int) {
        let maxSeats = selectedType == .car ? 4 : 1
        let newVal = seatCount + delta
        guard newVal >= 0, newVal <= maxSeats else { return }
        seatCount = newVal
    }

    private func updateSeatsUI() {
        seatCountLbl.text = "\(seatCount)"
        minusSeat.isEnabled = seatCount > 0
        minusSeat.alpha     = seatCount > 0 ? 1 : 0.4
        let maxSeats = selectedType == .car ? 4 : 1
        plusSeat.isEnabled = seatCount < maxSeats
        plusSeat.alpha     = seatCount < maxSeats ? 1 : 0.4
    }

    // MARK: - Pricing (unchanged from original)
    private func calculateSuggestedFare() {
        guard let route = selectedRoute else {
            suggestedLbl.text = "Suggested fare: ₹—"
            return
        }
        guard seatCount > 0 else {
            fareField.text    = ""
            suggestedLbl.text = "Suggested fare: ₹—"
            validateNext()
            return
        }

        let departure = date ?? time ?? Date()
        let fare = PricingManager.shared.suggestedFare(
            distanceMeters: route.distanceMeters,
            seats: seatCount,
            vehicle: selectedType == .car ? "car" : "bike",
            departureTime: departure
        )

        fareField.text = "\(fare)"
        let peakNote   = PricingManager.shared.isPeakHour(departure) ? " (peak-hour)" : ""
        suggestedLbl.text = "Suggested fare: ₹\(fare)\(peakNote)"
        validateNext()
    }

    @objc private func fieldsChanged() {
        validateNext()
    }

    private func validateNext() {
        let cost    = Double(fareField.text ?? "") ?? 0
        let plateOK = !(plateField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let modelOK = !(modelField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let enabled = seatCount > 0 && cost > 0 && plateOK && modelOK
        nextBtn.setPrimaryCTAEnabled(enabled)
    }

    // MARK: - Pre-fill from saved vehicle
    private func preloadVehicleIdentity() {
        guard let vehicle = UserDataModel.shared.getCurrentUser()?.vehicle else { return }
        plateField.text = vehicle.registrationNumber
        modelField.text = vehicle.model
        switch vehicle.type {
        case .car:   selectedType = .car
        case .bike:  selectedType = .bike
        case .other: selectedType = .car
        }
        let maxSeats = selectedType == .car ? 4 : 1
        seatCount = min(vehicle.seats, maxSeats)
        seatCountLbl.text = "\(seatCount)"
        updateTypeButtons()
        calculateSuggestedFare()
    }

    // MARK: - Next
    @objc private func handleNext() {
        let plate = plateField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let model = modelField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        let summary = RideSummary(
            from: source!,
            to: destination!,
            date: date!,
            time: time!,
            route: selectedRoute,
            vehicleType: selectedType == .car ? "Car" : "Bike",
            seats: seatCount,
            farePerSeat: Double(fareField.text ?? "") ?? 0,
            registrationPlate: plate,
            vehicleModel: model
        )

        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ReviewRideViewController") as! ReviewRideViewController
        vc.summary = summary
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == plateField {
            modelField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField == fareField else { return true }
        if string.isEmpty { return true }
        let allowedChars = CharacterSet.decimalDigits
        guard string.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else { return false }
        let current = (textField.text ?? "") as NSString
        let newText  = current.replacingCharacters(in: range, with: string)
        return newText.count <= 5
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == fareField { validateNext() }
    }

    // MARK: - Legacy IBAction stubs (storyboard wires these; logic now handled above)
    @IBAction func carTapped(_ sender: UITapGestureRecognizer) {}
    @IBAction func bikeTapped(_ sender: UITapGestureRecognizer) {}
    @IBAction func minusTapped(_ sender: UIButton) {}
    @IBAction func plusTapped(_ sender: UIButton) {}
    @IBAction func nextTapped(_ sender: UIButton) { handleNext() }
}
