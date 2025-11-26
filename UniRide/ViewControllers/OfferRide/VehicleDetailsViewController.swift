//
//  VehicleDetailsViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//


import UIKit

class VehicleDetailsViewController: UIViewController {

    @IBOutlet weak var carView: UIView!
    @IBOutlet weak var bikeView: UIView!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var maxSeatsLabel: UILabel!
    @IBOutlet weak var costTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    var source: LocationPoint?
    var destination: LocationPoint?
    var date: Date?
    var time: Date?
    var selectedRoute: RideRoute?


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
            carView.layer.borderWidth = 2
            carView.layer.borderColor = UIColor.systemTeal.cgColor
            
            bikeView.layer.borderWidth = 0
            bikeView.layer.borderColor = UIColor.clear.cgColor
            
            maxSeatsLabel.text = "Maximum 4 seats"
        } else {
            bikeView.layer.borderWidth = 2
            bikeView.layer.borderColor = UIColor.systemTeal.cgColor
            
            carView.layer.borderWidth = 0
            carView.layer.borderColor = UIColor.clear.cgColor
            
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
        let sb = UIStoryboard(name: "OfferRide", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "ReviewRideViewController") as! ReviewRideViewController
            
            // Pass Step 1 data
            vc.source = self.source
            vc.destination = self.destination
            vc.date = self.date
            vc.time = self.time

            // Pass route
            vc.selectedRoute = self.selectedRoute

            // Pass Step 2 data
            vc.vehicleType = (self.selectedVehicle == .car ? "Car" : "Bike")
            vc.seats = self.seats
            vc.farePerSeat = Double(self.costTextField.text ?? "0") ?? 0

            navigationController?.pushViewController(vc, animated: true)
    }
}
