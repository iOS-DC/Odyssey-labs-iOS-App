//
//  VehicleDetailsViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//


import UIKit

class VehicleDetailsViewController: UIViewController {

    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var bikeButton: UIButton!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var maxSeatsLabel: UILabel!
    @IBOutlet weak var costTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    enum VehicleType {
        case car, bike
    }

    var selectedVehicle: VehicleType = .car {
        didSet { updateVehicleUI() }
    }

    var seats = 0 {
        didSet { seatsLabel.text = "\(seats)" }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        costTextField.keyboardType = .numberPad
        selectVehicle(.car)
    }

    func selectVehicle(_ type: VehicleType) {
        selectedVehicle = type
        seats = 0
    }

    func updateVehicleUI() {
        if selectedVehicle == .car {
            carButton.backgroundColor = .systemTeal
            bikeButton.backgroundColor = .clear
            maxSeatsLabel.text = "Maximum 4 seats"
        } else {
            bikeButton.backgroundColor = .systemTeal
            carButton.backgroundColor = .clear
            maxSeatsLabel.text = "Maximum 1 seat"
        }
    }

    @IBAction func carTapped(_ sender: UITapGestureRecognizer) { selectVehicle(.car) }
    @IBAction func bikeTapped(_ sender: UITapGestureRecognizer) { selectVehicle(.bike) }

    @IBAction func minusTapped(_ sender: UIButton) {
        if seats > 0 { seats -= 1 }
    }

    @IBAction func plusTapped(_ sender: UIButton) {
        if selectedVehicle == .car && seats < 4 { seats += 1 }
        if selectedVehicle == .bike && seats < 1 { seats += 1 }
    }

    @IBAction func nextTapped(_ sender: UIButton) {
        // Move to Step 3
    }
}
