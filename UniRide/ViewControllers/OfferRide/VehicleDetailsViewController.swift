import UIKit

class VehicleDetailsViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
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

    // Data passed from Step 1
    var source: LocationPoint?
    var destination: LocationPoint?
    var date: Date?
    var time: Date?
    var selectedRoute: RideRoute?

    // Recurring fields passed from OfferRideViewController
    var isRecurring: Bool = false
    var recurringDays: [Int] = []

    enum VehicleType { case car, bike }
    var selectedVehicle: VehicleType = .car {
        didSet { updateVehicleUI() }
    }

    var seats = 0 {
        didSet { updateSeatsUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ContainerView.applyCardStyle()
        let nextTitle = nextButton.currentTitle ?? "Next"
        nextButton.applyProminentPrimaryCTA(title: nextTitle, corner: AppDesign.Radius.md)
        carView.applySmallCard()
        bikeView.applySmallCard()
        seatsLabel.applyTextStyle(AppDesign.Typography.h2)
        maxSeatsLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        suggestedFareLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        updateVehicleUI()
        updateSeatsUI()

        // Fare field: numbers only, max 5 digits (₹99,999)
        costTextField.delegate = self
        costTextField.keyboardType = .numberPad
        costTextField.applyRoundedField()
        costTextField.setLeftPaddingPoints(12)
    }

    // MARK: - Animate Selection
    func animateSelection(_ view: UIView) {
        UIView.animate(withDuration: 0.15, animations: {
            view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                view.transform = .identity
            }
        }
    }

    // MARK: - Update UI for Vehicle Cards
    func updateVehicleUI() {

        let selectedColor = AppDesign.Color.primary
        let selectedBG = AppDesign.Color.primary.withAlphaComponent(0.08)
        let normalBorder = AppDesign.Color.border.cgColor

        if selectedVehicle == .car {
            animateSelection(carView)
            carView.layer.borderColor = selectedColor.cgColor
            carView.layer.borderWidth = 2
            carView.backgroundColor = selectedBG

            bikeView.layer.borderColor = normalBorder
            bikeView.layer.borderWidth = 1
            bikeView.backgroundColor = .clear

            maxSeatsLabel.text = "Maximum 4 Seats"
        } else {
            animateSelection(bikeView)
            bikeView.layer.borderColor = selectedColor.cgColor
            bikeView.layer.borderWidth = 2
            bikeView.backgroundColor = selectedBG

            carView.layer.borderColor = normalBorder
            carView.layer.borderWidth = 1
            carView.backgroundColor = .clear

            maxSeatsLabel.text = "Maximum 1 Seat"
        }

        seats = 0
        calculateSuggestedFare()
    }

    // MARK: - Seats UI
    func updateSeatsUI() {

        seatsLabel.text = "\(seats)"

        minusButton.isEnabled = seats > 0

        plusButton.isEnabled = selectedVehicle == .car ? seats < 4 : seats < 1

        calculateSuggestedFare()
        validateNextButton()
    }

    // MARK: - Pricing
    func calculateSuggestedFare() {

        guard let route = selectedRoute else {
            suggestedFareLabel.text = "Suggested fare: ₹—"
            return
        }

        guard seats > 0 else {
            costTextField.text = ""
            suggestedFareLabel.text = "Suggested fare: ₹—"
            return
        }

        // Combine date + time pickers into the departure timestamp
        let departure = date ?? time ?? Date()

        let fare = PricingManager.shared.suggestedFare(
            distanceMeters: route.distanceMeters,
            seats: seats,
            vehicle: selectedVehicle == .car ? "car" : "bike",
            departureTime: departure
        )

        costTextField.text = "\(fare)"
        let peakNote = PricingManager.shared.isPeakHour(departure) ? " (peak-hour)" : ""
        suggestedFareLabel.text = "Suggested fare: ₹\(fare)\(peakNote)"
    }

    // MARK: - Fare TextField Delegate
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField == costTextField else { return true }

        // Allow deletions
        if string.isEmpty { return true }

        // Only digits allowed
        let allowedChars = CharacterSet.decimalDigits
        guard string.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else { return false }

        // Cap at 5 digits (max ₹99,999)
        let current = (textField.text ?? "") as NSString
        let newText = current.replacingCharacters(in: range, with: string)
        return newText.count <= 5
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == costTextField { validateNextButton() }
    }

    // MARK: - Next Button Activation
    func validateNextButton() {
        let cost = Double(costTextField.text ?? "") ?? 0
        let enabled = seats > 0 && cost > 0

        nextButton.setPrimaryCTAEnabled(enabled)
    }

    // MARK: - Actions
    @IBAction func carTapped(_ sender: UITapGestureRecognizer) {
        selectedVehicle = .car
    }

    @IBAction func bikeTapped(_ sender: UITapGestureRecognizer) {
        selectedVehicle = .bike
    }

    @IBAction func minusTapped(_ sender: UIButton) {
        if seats > 0 { seats -= 1 }
    }

    @IBAction func plusTapped(_ sender: UIButton) {
        if selectedVehicle == .car && seats < 4 { seats += 1 }
        if selectedVehicle == .bike && seats < 1 { seats += 1 }
    }

    @IBAction func nextTapped(_ sender: UIButton) {

        var summary = RideSummary(
            from: source!,
            to: destination!,
            date: date!,
            time: time!,
            route: selectedRoute,
            vehicleType: selectedVehicle == .car ? "Car" : "Bike",
            seats: seats,
            farePerSeat: Double(costTextField.text ?? "") ?? 0
        )
        summary.isRecurring   = isRecurring
        summary.recurringDays = recurringDays

        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ReviewRideViewController") as! ReviewRideViewController
        vc.summary = summary

        navigationController?.pushViewController(vc, animated: true)
    }
}
