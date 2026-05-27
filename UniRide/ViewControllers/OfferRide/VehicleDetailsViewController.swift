import UIKit

class VehicleDetailsViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Storyboard outlets (layout lives in OfferRide.storyboard)

    @IBOutlet weak var plateCard: UIView!
    @IBOutlet weak var modelCard: UIView!
    @IBOutlet weak var typeCard: UIView!
    @IBOutlet weak var seatsCard: UIView!
    @IBOutlet weak var fareCard: UIView!

    @IBOutlet weak var plateField: UITextField!
    @IBOutlet weak var modelField: UITextField!

    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var bikeButton: UIButton!

    @IBOutlet weak var seatsLabel: UILabel!     // big "0" count label
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var maxSeatsLabel: UILabel!  // "Maximum N seats" hint

    @IBOutlet weak var costTextField: UITextField!
    @IBOutlet weak var suggestedFareLabel: UILabel!

    @IBOutlet weak var nextButton: UIButton!

    // MARK: - State

    private var selectedType: VehicleType = .car {
        didSet { updateTypeButtons(); updateMaxSeatsHint(); calculateSuggestedFare() }
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
        styleCards()
        styleFields()
        nextButton.applyPrimaryButton(color: AppDesign.Color.primary, radius: AppDesign.Radius.sm)
        nextButton.setPrimaryCTAEnabled(false)
        updateTypeButtons()
        updateMaxSeatsHint()
        updateSeatsUI()
        preloadVehicleIdentity()
    }

    // MARK: - Styling (dynamic tokens; layout itself is in IB)

    private func styleCards() {
        [plateCard, modelCard, typeCard, seatsCard, fareCard].forEach {
            $0?.applyCardStyle(corner: AppDesign.Radius.md,
                               shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                               shadowRadius: AppDesign.Shadow.smallCardRadius)
        }
    }

    private func styleFields() {
        plateField.applyRoundedField()
        plateField.font = AppDesign.Typography.body
        plateField.delegate = self

        modelField.applyRoundedField()
        modelField.font = AppDesign.Typography.body
        modelField.delegate = self

        costTextField.applyRoundedField()
        costTextField.setLeftPaddingPoints(12)
        costTextField.font = AppDesign.Typography.body
        costTextField.delegate = self
    }

    // MARK: - Vehicle type buttons (wired in storyboard)

    @IBAction private func carButtonTapped(_ sender: UIButton) {
        didSelectType(.car)
    }

    @IBAction private func bikeButtonTapped(_ sender: UIButton) {
        didSelectType(.bike)
    }

    private func didSelectType(_ type: VehicleType) {
        selectedType = type
        // Reset seats when vehicle type changes
        seatCount = 0
    }

    private func updateTypeButtons() {
        let isCarSelected = selectedType == .car
        [carButton, bikeButton].forEach { btn in
            guard let btn else { return }
            let isSel = (btn == carButton) ? isCarSelected : !isCarSelected
            btn.configuration?.baseBackgroundColor = isSel ? AppDesign.Color.primary : AppDesign.Color.fieldBackground
            btn.configuration?.baseForegroundColor = isSel ? AppDesign.Color.primary : .secondaryLabel
            btn.layer.borderWidth  = isSel ? 2 : 0
            btn.layer.borderColor  = isSel ? AppDesign.Color.primary.cgColor : nil
            btn.layer.cornerRadius = AppDesign.Radius.sm
        }
    }

    // MARK: - Seats (wired in storyboard)

    @IBAction private func minusSeatTapped(_ sender: UIButton) { adjustSeats(-1) }
    @IBAction private func plusSeatTapped(_ sender: UIButton)  { adjustSeats(1) }

    private func adjustSeats(_ delta: Int) {
        let maxSeats = selectedType == .car ? 4 : 1
        let newVal = seatCount + delta
        guard newVal >= 0, newVal <= maxSeats else { return }
        seatCount = newVal
    }

    private func updateSeatsUI() {
        seatsLabel.text = "\(seatCount)"
        minusButton.isEnabled = seatCount > 0
        minusButton.alpha     = seatCount > 0 ? 1 : 0.4
        let maxSeats = selectedType == .car ? 4 : 1
        plusButton.isEnabled = seatCount < maxSeats
        plusButton.alpha     = seatCount < maxSeats ? 1 : 0.4
    }

    private func updateMaxSeatsHint() {
        let maxSeats = selectedType == .car ? 4 : 1
        maxSeatsLabel.text = "Maximum \(maxSeats) seat\(maxSeats == 1 ? "" : "s")"
    }

    // MARK: - Pricing

    private func calculateSuggestedFare() {
        guard let route = selectedRoute else {
            suggestedFareLabel.text = "Suggested fare: ₹—"
            return
        }
        guard seatCount > 0 else {
            costTextField.text     = ""
            suggestedFareLabel.text = "Suggested fare: ₹—"
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

        costTextField.text = "\(fare)"
        let peakNote = PricingManager.shared.isPeakHour(departure) ? " (peak-hour)" : ""
        suggestedFareLabel.text = "Suggested fare: ₹\(fare)\(peakNote)"
        validateNext()
    }

    @IBAction private func fieldsChanged() { validateNext() }

    private func validateNext() {
        let cost    = Double(costTextField.text ?? "") ?? 0
        let plateOK = !(plateField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let modelOK = !(modelField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let enabled = seatCount > 0 && cost > 0 && plateOK && modelOK
        nextButton.setPrimaryCTAEnabled(enabled)
    }

    // MARK: - Pre-fill from saved vehicle

    private func preloadVehicleIdentity() {
        guard let vehicle = UserDataModel.shared.getCurrentUser()?.vehicles?.first else { return }
        plateField.text = vehicle.registrationNumber
        modelField.text = vehicle.model
        switch vehicle.type {
        case .car:   selectedType = .car
        case .bike:  selectedType = .bike
        case .other: selectedType = .car
        }
        let maxSeats = selectedType == .car ? 4 : 1
        seatCount = min(vehicle.seats, maxSeats)
        seatsLabel.text = "\(seatCount)"
        updateTypeButtons()
        updateMaxSeatsHint()
        calculateSuggestedFare()
    }

    // MARK: - Next

    @IBAction func nextTapped(_ sender: UIButton) {
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
            farePerSeat: Double(costTextField.text ?? "") ?? 0,
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
        guard textField == costTextField else { return true }
        if string.isEmpty { return true }
        let allowedChars = CharacterSet.decimalDigits
        guard string.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else { return false }
        let current = (textField.text ?? "") as NSString
        let newText  = current.replacingCharacters(in: range, with: string)
        return newText.count <= 5
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == costTextField { validateNext() }
    }
}
