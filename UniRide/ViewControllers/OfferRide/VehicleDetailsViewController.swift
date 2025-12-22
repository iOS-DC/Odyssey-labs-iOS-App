import UIKit

class VehicleDetailsViewController: UIViewController {

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

    enum VehicleType { case car, bike }
    var selectedVehicle: VehicleType = .car {
        didSet { updateVehicleUI() }
    }

    var seats = 0 {
        didSet { updateSeatsUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        updateVehicleUI()
        updateSeatsUI()
    }

    func setupUI() {

        // Main Card
        ContainerView.layer.cornerRadius = 20
        ContainerView.layer.shadowColor = UIColor.black.cgColor
        ContainerView.layer.shadowOpacity = 0.08
        ContainerView.layer.shadowRadius = 12
        ContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)

        // Cost TextField
        costTextField.keyboardType = .numberPad
        costTextField.placeholder = "Enter fare"
        costTextField.layer.cornerRadius = 12
        costTextField.layer.borderWidth = 1
        costTextField.layer.borderColor = UIColor.systemGray4.cgColor

        // Next Button
        nextButton.layer.cornerRadius = 18
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.isEnabled = false
        nextButton.alpha = 0.5

        // Suggested Fare Label
        suggestedFareLabel.text = "Suggested fare: ₹—"
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

        let selectedColor = UIColor.systemBlue
        let selectedBG = UIColor.systemBlue.withAlphaComponent(0.08)
        let normalBorder = UIColor.systemGray5.cgColor

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

        let fare = PricingManager.shared.suggestedFare(
            distanceMeters: route.distanceMeters,
            seats: seats,
            vehicle: selectedVehicle == .car ? "car" : "bike"
        )

        costTextField.text = "\(fare)"
        suggestedFareLabel.text = "Suggested fare: ₹\(fare)"
    }

    // MARK: - Next Button Activation
    func validateNextButton() {
        let cost = Double(costTextField.text ?? "") ?? 0
        let enabled = seats > 0 && cost > 0

        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1 : 0.5
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

        let summary = RideSummary(
            from: source!,
            to: destination!,
            date: date!,
            time: time!,
            route: selectedRoute,
            vehicleType: selectedVehicle == .car ? "Car" : "Bike",
            seats: seats,
            farePerSeat: Double(costTextField.text ?? "") ?? 0
        )

        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ReviewRideViewController") as! ReviewRideViewController
        vc.summary = summary

        navigationController?.pushViewController(vc, animated: true)
    }
}
