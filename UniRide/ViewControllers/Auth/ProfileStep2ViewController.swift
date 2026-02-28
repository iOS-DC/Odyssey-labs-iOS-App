//
//  ProfileStep2ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 18/11/25.
//

import UIKit
import MapKit

class ProfileStep2ViewController: UIViewController {
    @IBOutlet weak var yesVehicleButton: UIButton!
    @IBOutlet weak var noVehicleButton: UIButton!

    @IBOutlet weak var vehicleTypeLabel: UILabel!
    @IBOutlet weak var vehicleTypeDropdown: UIButton!
    @IBOutlet weak var containerCard: UIView!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var vehicleSectionStack: UIStackView!  // contains label + dropdown

    private var selectedHasVehicle: Bool?
    private var selectedVehicleType: String?
    private var selectedSeatCapacity: Int = 0
    private let modelTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Model"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: AppDesign.Size.fieldHeight).isActive = true
        return tf
    }()
    private let plateTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Plate Number"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: AppDesign.Size.fieldHeight).isActive = true
        return tf
    }()
    private let seatsButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: AppDesign.Size.fieldHeight).isActive = true
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Commute Setup"
        applyOnboardingChrome(step: 6, total: 7)

        vehicleSectionStack.isHidden = true
        continueButton.setPrimaryCTAEnabled(false)
        containerCard.applyCardStyle()
        setupVehicleDropdown()
        yesVehicleButton.applyOutlineButton()
        noVehicleButton.applyOutlineButton()
        vehicleTypeDropdown.applyOutlineButton()
        continueButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(continueButton)
        modelTextField.applyRoundedField()
        plateTextField.applyRoundedField()
        seatsButton.applyOutlineButton()
        seatsButton.setTitle("Seats", for: .normal)
        modelTextField.addTarget(self, action: #selector(vehicleDetailChanged), for: .editingChanged)
        plateTextField.addTarget(self, action: #selector(vehicleDetailChanged), for: .editingChanged)
        setupVehicleDetailFields()
        configureAccessibility()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, yesVehicleButton, noVehicleButton, continueButton])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preloadSavedState()
    }

        func setupVehicleDropdown() {
            let options = ["Car", "Two-Wheeler"]

            let actions = options.map { option in
                UIAction(title: option) { _ in
                    self.selectedVehicleType = option
                    self.vehicleTypeDropdown.setTitle(option, for: .normal)
                    self.updateSeatMenu()
                    self.validateContinueButton()
                }
            }

            vehicleTypeDropdown.menu = UIMenu(title: "Select type", children: actions)
            vehicleTypeDropdown.showsMenuAsPrimaryAction = true
        }
    
    @IBAction func yesVehicleTapped(_ sender: UIButton) {
        AppHaptics.selection()
        selectedHasVehicle = true
        applyVehicleSelectionUI(hasVehicle: true)
        validateContinueButton()
    }
    @IBAction func noVehicleTapped(_ sender: UIButton) {
        AppHaptics.selection()
        selectedHasVehicle = false
        selectedVehicleType = nil
        selectedSeatCapacity = 0
        applyVehicleSelectionUI(hasVehicle: false)
        validateContinueButton()
    }
    func validateContinueButton() {
        if selectedHasVehicle == nil {
            continueButton.setPrimaryCTAEnabled(false)
            return
        }

        if selectedHasVehicle == true && selectedVehicleType == nil {
            continueButton.setPrimaryCTAEnabled(false)
            return
        }
        if selectedHasVehicle == true {
            let hasModel = !(modelTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasPlate = !(plateTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasSeats = selectedSeatCapacity > 0
            let enabled = hasModel && hasPlate && hasSeats
            continueButton.setPrimaryCTAEnabled(enabled)
            return
        }

        continueButton.setPrimaryCTAEnabled(true)
    }
   	 
    @IBAction func continuePressed(_ sender: UIButton) {

        guard let hasVehicle = selectedHasVehicle else { return }

        let vehicle: Vehicle? = {
            if hasVehicle == false { return nil }
            guard let type = selectedVehicleType else { return nil }

            let normalized = type.lowercased()
            let capacity = selectedSeatCapacity > 0 ? selectedSeatCapacity : (normalized == "car" ? 4 : 1)
            return Vehicle(
                type: normalized == "car" ? .car :
                      normalized == "two-wheeler" ? .bike : .other,
                model: modelTextField.text ?? "",
                registrationNumber: plateTextField.text ?? "",
                seats: capacity
            )
        }()

        let proceedToLocationStep: () -> Void = { [weak self] in
            guard let self else { return }
            RegistrationBuilder.shared.vehicle = vehicle
            let vc = storyboard?.instantiateViewController(identifier: "ProfileStep3ViewController") as! ProfileStep3ViewController
            navigationController?.pushViewController(vc, animated: true)
        }

        proceedToLocationStep()
    }

    private func collectHomeLocationsIfNeeded(completion: @escaping ([LocationPoint]) -> Void) {
        let existing = UserDataModel.shared.getHomeLocations()
        if !existing.isEmpty {
            completion(existing)
            return
        }

        promptForHomeLocation(index: 1, collected: [], completion: completion)
    }

    private func promptForHomeLocation(index: Int,
                                       prefillText: String = "",
                                       collected: [LocationPoint],
                                       completion: @escaping ([LocationPoint]) -> Void) {
        let alert = UIAlertController(
            title: "Add Home Location \(index) of 3",
            message: "Enter your area/address to prefill rides later.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "e.g. Sector 17, Chandigarh"
            tf.autocapitalizationType = .words
            tf.text = prefillText
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let query = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !query.isEmpty else {
                self.showSimpleAlert(title: "Location required", message: "Please enter a location.")
                self.promptForHomeLocation(index: index, prefillText: query, collected: collected, completion: completion)
                return
            }

            self.resolveAddress(query) { result in
                switch result {
                case .success(let point):
                    var updated = collected
                    updated.append(point)
                    updated = self.deduplicatedLocations(updated)

                    if updated.count >= 3 {
                        completion(updated)
                        return
                    }

                    self.askAddAnotherLocation(currentCount: updated.count) { shouldAdd in
                        if shouldAdd {
                            self.promptForHomeLocation(index: updated.count + 1, collected: updated, completion: completion)
                        } else {
                            completion(updated)
                        }
                    }

                case .failure(let error):
                    self.showGeocodingFailure(
                        query: query,
                        failureMessage: error.localizedDescription,
                        index: index,
                        collected: collected,
                        completion: completion
                    )
                    return
                }
            }
        })

        if !collected.isEmpty {
            alert.addAction(UIAlertAction(title: "Done", style: .cancel) { _ in
                completion(collected)
            })
        } else {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }

        present(alert, animated: true)
    }

    private func askAddAnotherLocation(currentCount: Int, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Location saved",
            message: "You have added \(currentCount) location(s). Add another?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Add Another", style: .default) { _ in completion(true) })
        present(alert, animated: true)
    }

    private func askSeatCapacity(vehicleType: String, completion: @escaping (Int) -> Void) {
        let maxSeats = vehicleType.lowercased() == "car" ? 4 : 1
        let alert = UIAlertController(
            title: "Seat Capacity",
            message: "How many passengers can travel? (1-\(maxSeats))",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "Enter seats"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let value = Int(alert.textFields?.first?.text ?? "") ?? 0
            if value >= 1 && value <= maxSeats {
                completion(value)
            } else {
                self.showSimpleAlert(title: "Invalid seats", message: "Enter a value between 1 and \(maxSeats).")
                self.askSeatCapacity(vehicleType: vehicleType, completion: completion)
            }
        })
        present(alert, animated: true)
    }

    private func resolveAddress(_ query: String, completion: @escaping (Result<LocationPoint, Error>) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        MKLocalSearch(request: request).start { response, error in
            if let item = response?.mapItems.first {
                let coordinate = item.placemark.coordinate
                DispatchQueue.main.async {
                    completion(.success(LocationPoint(
                        lat: coordinate.latitude,
                        lon: coordinate.longitude,
                        address: item.name ?? query
                    )))
                }
                return
            }

            // Fallback geocoder when MKLocalSearch has no direct map item.
            CLGeocoder().geocodeAddressString(query) { placemarks, geocodeError in
                if let coord = placemarks?.first?.location?.coordinate {
                    DispatchQueue.main.async {
                        completion(.success(LocationPoint(lat: coord.latitude, lon: coord.longitude, address: query)))
                    }
                    return
                }

                let message = geocodeError?.localizedDescription
                    ?? error?.localizedDescription
                    ?? "Location not found. Try a more specific address."
                let wrappedError = NSError(
                    domain: "ProfileStep2Geocoding",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
                DispatchQueue.main.async {
                    completion(.failure(wrappedError))
                }
            }
        }
    }

    private func showGeocodingFailure(query: String,
                                      failureMessage: String,
                                      index: Int,
                                      collected: [LocationPoint],
                                      completion: @escaping ([LocationPoint]) -> Void) {
        let alert = UIAlertController(
            title: "Couldn’t resolve location",
            message: failureMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Edit Address", style: .default) { _ in
            self.promptForHomeLocation(index: index, prefillText: query, collected: collected, completion: completion)
        })

        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.promptForHomeLocation(index: index, prefillText: query, collected: collected, completion: completion)
        })

        if !collected.isEmpty {
            alert.addAction(UIAlertAction(title: "Use Saved Locations", style: .cancel) { _ in
                completion(collected)
            })
        } else {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }

        present(alert, animated: true)
    }

    private func deduplicatedLocations(_ locations: [LocationPoint]) -> [LocationPoint] {
        var seen = Set<String>()
        return locations.filter { point in
            let key = (point.address ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if key.isEmpty { return true }
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func preloadSavedState() {
        let vehicle = RegistrationBuilder.shared.vehicle ?? UserDataModel.shared.getCurrentUser()?.vehicle
        if let vehicle = vehicle {
            selectedHasVehicle = true
            selectedVehicleType = vehicle.type == .bike ? "Two-Wheeler" : "Car"
            selectedSeatCapacity = max(1, vehicle.seats)
            vehicleTypeDropdown.setTitle(selectedVehicleType, for: .normal)
            modelTextField.text = vehicle.model
            plateTextField.text = vehicle.registrationNumber
            seatsButton.setTitle("\(selectedSeatCapacity) Seats", for: .normal)
            applyVehicleSelectionUI(hasVehicle: true)
        } else {
            selectedHasVehicle = false
            selectedVehicleType = nil
            selectedSeatCapacity = 0
            vehicleTypeDropdown.setTitle("Select type", for: .normal)
            modelTextField.text = nil
            plateTextField.text = nil
            seatsButton.setTitle("Seats", for: .normal)
            applyVehicleSelectionUI(hasVehicle: false)
        }
        validateContinueButton()
    }

    private func applyVehicleSelectionUI(hasVehicle: Bool) {
        if hasVehicle {
            yesVehicleButton.layer.borderColor = AppDesign.Color.primary.cgColor
            yesVehicleButton.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.1)
            noVehicleButton.layer.borderColor = AppDesign.Color.border.cgColor
            noVehicleButton.backgroundColor = .clear
            yesVehicleButton.accessibilityTraits.insert(.selected)
            noVehicleButton.accessibilityTraits.remove(.selected)
            vehicleSectionStack.isHidden = false
            modelTextField.isHidden = false
            plateTextField.isHidden = false
            seatsButton.isHidden = false
        } else {
            noVehicleButton.layer.borderColor = AppDesign.Color.primary.cgColor
            noVehicleButton.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.1)
            yesVehicleButton.layer.borderColor = AppDesign.Color.border.cgColor
            yesVehicleButton.backgroundColor = .clear
            noVehicleButton.accessibilityTraits.insert(.selected)
            yesVehicleButton.accessibilityTraits.remove(.selected)
            vehicleSectionStack.isHidden = true
            modelTextField.isHidden = true
            plateTextField.isHidden = true
            seatsButton.isHidden = true
        }
    }

    private func setupVehicleDetailFields() {
        guard !vehicleSectionStack.arrangedSubviews.contains(modelTextField) else { return }
        vehicleSectionStack.addArrangedSubview(modelTextField)
        vehicleSectionStack.addArrangedSubview(plateTextField)
        vehicleSectionStack.addArrangedSubview(seatsButton)
        updateSeatMenu()
    }

    private func updateSeatMenu() {
        let maxSeats = (selectedVehicleType?.lowercased() == "car") ? 4 : 1
        seatsButton.menu = UIMenu(title: "Seats", children: (1...maxSeats).map { seat in
            UIAction(title: "\(seat)") { [weak self] _ in
                self?.selectedSeatCapacity = seat
                self?.seatsButton.setTitle("\(seat) Seats", for: .normal)
                self?.validateContinueButton()
            }
        })
        seatsButton.showsMenuAsPrimaryAction = true
        if selectedSeatCapacity > maxSeats {
            selectedSeatCapacity = 0
            seatsButton.setTitle("Seats", for: .normal)
        }
    }

    @objc private func vehicleDetailChanged() {
        validateContinueButton()
    }

    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func configureAccessibility() {
        yesVehicleButton.accessibilityLabel = "Yes, I have a vehicle"
        noVehicleButton.accessibilityLabel = "No, I do not have a vehicle"
        vehicleTypeDropdown.accessibilityLabel = "Vehicle type"
        modelTextField.accessibilityLabel = "Vehicle model"
        plateTextField.accessibilityLabel = "Vehicle plate number"
        seatsButton.accessibilityLabel = "Seat capacity"
        continueButton.accessibilityLabel = "Continue"
        continueButton.accessibilityHint = "Proceed to set home location"
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
