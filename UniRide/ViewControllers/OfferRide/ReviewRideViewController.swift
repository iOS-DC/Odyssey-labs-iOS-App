//
//  ReviewRideViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//

//
//  ReviewRideViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//

import UIKit
import MapKit

class ReviewRideViewController: UIViewController {

    // MARK: - IBOutlets (connect these in storyboard)
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var vehicleTypeLabel: UILabel!
    @IBOutlet weak var seatsAvailableLabel: UILabel!
    @IBOutlet weak var farePerPersonLabel: UILabel!
    @IBOutlet weak var totalFareLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var offerRideButton: UIButton!

    // MARK: - Data coming from Step 1 + Step 2
    var source: LocationPoint?
    var destination: LocationPoint?

    var date: Date?
    var time: Date?
    var selectedRoute: RideRoute?

    var vehicleType: String!       // "Car" or "Bike"
    var seats: Int!
    var farePerSeat: Double!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fillRideDetails()
    }

    // MARK: - UI Setup
    func configureUI() {
        offerRideButton.layer.cornerRadius = 16

        notesTextView.layer.cornerRadius = 12
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemTeal.cgColor
    }

    // MARK: - Show all ride details on the screen
    func fillRideDetails() {

        guard let src = source,
                  let dst = destination,
                  let dt = date,
                  let tm = time else {
                print("❌ ERROR: Missing data in ReviewRideViewController")
                return
            }

            fromLabel.text = "From \(src.address ?? "Unknown")"
            toLabel.text   = "To \(dst.address ?? "Unknown")"

            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            dateLabel.text = df.string(from: dt)

            let tf = DateFormatter()
            tf.dateFormat = "HH:mm"
            timeLabel.text = tf.string(from: tm)

        vehicleTypeLabel.text = vehicleType
        seatsAvailableLabel.text = "\(seats!) seats available"

        farePerPersonLabel.text = "\(Int(farePerSeat)) per person"

        let total = Double(seats) * farePerSeat
        totalFareLabel.text = "Total: \(Int(total))"
    }

    // MARK: - Offer Ride Action
    @IBAction func offerRideTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "MyRide", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "MyRidesViewController") as! MyRidesViewController
        // Combine date + time into single Date
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year,.month,.day], from: date!)
        let timeComponents = calendar.dateComponents([.hour,.minute], from: time!)
        
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        
        let finalDepartureTime = calendar.date(from: finalComponents) ?? Date()
        
        // Create Ride object
        let ride = Ride(
            driverUserID: UUID(),
            source: source!,
            destination: destination!,
            waypoints: [], // later
            selectedRoute: selectedRoute, // <--- STORE IT
            departureTime: finalDepartureTime,
            seatsTotal: seats,
            farePerSeat: farePerSeat,
            status: .draft,
            notes: notesTextView.text
        )
        
        
        // Save the ride
        RideDataModel.shared.createRide(ride)
        
        print("Ride created successfully:")
        print(ride)
        
        // Navigate to My Rides or Success Screen
        //        let alert = UIAlertController(title: "Success", message: "Your ride has been created!", preferredStyle: .alert)
        //        alert.addAction(UIAlertAction(title: "OK", style: .default))
        //
        //        self.present(alert, animated: true)
        // Step 1: Switch to MyRide tab
        tabBarController?.selectedIndex = 1   // change 3 if MyRide is at another index
        
        // Step 2: Force Upcoming segment selection when opening
        if let tabVCs = tabBarController?.viewControllers,
           let navVC = tabVCs[1] as? UINavigationController,   // MyRide is inside navigation?
           let myRideVC = navVC.topViewController as? MyRidesViewController {
            
            myRideVC.segmentedControl.selectedSegmentIndex = 0
            myRideVC.updateForSelectedSegment()
        }}
}

