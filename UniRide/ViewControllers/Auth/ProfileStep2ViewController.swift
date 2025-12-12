//
//  ProfileStep2ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 18/11/25.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()

        vehicleSectionStack.isHidden = true
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        containerCard.applyCardStyle()
        setupVehicleDropdown()
        yesVehicleButton.applyOutlineButton()
        noVehicleButton.applyOutlineButton()
        continueButton.applyPrimaryButton()

    }

        func setupVehicleDropdown() {
            let options = ["Car", "Two-Wheeler"]

            let actions = options.map { option in
                UIAction(title: option) { action in
                    self.selectedVehicleType = option
                    self.vehicleTypeDropdown.setTitle(option, for: .normal)
                    self.validateContinueButton()
                }
            }

            vehicleTypeDropdown.menu = UIMenu(title: "Select type", children: actions)
            vehicleTypeDropdown.showsMenuAsPrimaryAction = true
        }
    
    @IBAction func yesVehicleTapped(_ sender: UIButton) {

        selectedHasVehicle = true

        yesVehicleButton.layer.borderColor = UIColor.systemGreen.cgColor
        yesVehicleButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)

        noVehicleButton.layer.borderColor = UIColor.systemGray4.cgColor
        noVehicleButton.backgroundColor = .clear

        vehicleSectionStack.isHidden = false

        validateContinueButton()
    }
    @IBAction func noVehicleTapped(_ sender: UIButton) {

        selectedHasVehicle = false

        noVehicleButton.layer.borderColor = UIColor.systemGreen.cgColor
        noVehicleButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)

        yesVehicleButton.layer.borderColor = UIColor.systemGray4.cgColor
        yesVehicleButton.backgroundColor = .clear

        vehicleSectionStack.isHidden = true
        selectedVehicleType = nil

        validateContinueButton()
    }
    func validateContinueButton() {
        if selectedHasVehicle == nil {
            continueButton.isEnabled = false
            continueButton.alpha = 0.5
            return
        }

        if selectedHasVehicle == true && selectedVehicleType == nil {
            continueButton.isEnabled = false
            continueButton.alpha = 0.5
            return
        }

        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }
   	 
    @IBAction func continuePressed(_ sender: UIButton) {

        guard let hasVehicle = selectedHasVehicle else { return }

        let vehicle: Vehicle? = {
            if hasVehicle == false { return nil }
            guard let type = selectedVehicleType else { return nil }
            
            return Vehicle(
                type: type.lowercased() == "car" ? .car :
                      type.lowercased() == "motorcycle" ? .bike : .other,
                model: "",
                registrationNumber: "",
                seats: 0
            )
        }()

        UserDataModel.shared.editCurrentUser(vehicle: vehicle)

        // Move to step 3
        let vc = storyboard?.instantiateViewController(identifier: "ProfileStep3ViewController") as! ProfileStep3ViewController
        navigationController?.pushViewController(vc, animated: true)
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
