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
        // ❌ Remove these two lines – you don't need to instantiate it manually
        // let sb = UIStoryboard(name: "MyRide", bundle: nil)
        // let vc = sb.instantiateViewController(withIdentifier: "MyRidesViewController") as! MyRidesViewController
        
        // 1. Get the logged-in user
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("❌ No current user, cannot create ride")
            return
        }
        
        // 2. Combine date + time into single Date
        guard let rideDate = date, let rideTime = time else {
            print("❌ Missing date or time")
            return
        }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year,.month,.day], from: rideDate)
        let timeComponents = calendar.dateComponents([.hour,.minute], from: rideTime)
        
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
                
        var finalDepartureTime = calendar.date(from: finalComponents) ?? Date()

        // ✅ Make sure departure time is not in the past
        let now = Date()
        if finalDepartureTime < now {
            // push it slightly into the future so it's counted as upcoming
            finalDepartureTime = now.addingTimeInterval(60) // 1 minute from now
        }
        
        // 3. Safely unwrap required fields
        guard let src = source,
              let dst = destination,
              let seats = seats,
              let farePerSeat = farePerSeat else {
            print("❌ Missing ride details")
            return
        }
        
        // 4. Create Ride object with REAL user id
        let ride = Ride(
            driverUserID: currentUser.id,
            source: src,
            destination: dst,
            waypoints: [],
            selectedRoute: selectedRoute,
            departureTime: finalDepartureTime,
            seatsTotal: seats,
            farePerSeat: farePerSeat,
            status: .published,
            notes: notesTextView.text
        )


        
        // 5. Save the ride
        RideDataModel.shared.createRide(ride)
        
        print("✅ Ride created successfully:")
        print(ride)
        
        // (Optional) Debug: see what myUpcoming returns right now
        let upcoming = RideDataModel.shared.myUpcoming(userID: currentUser.id)
        print("After create, myUpcoming.count =", upcoming.count)
        
        // 6. Switch to My Rides tab
        tabBarController?.selectedIndex = 1   // make sure index 1 is MyRides tab
        
        // 7. Ensure Upcoming segment is selected & table refreshes
        if let tabVCs = tabBarController?.viewControllers,
           let navVC = tabVCs[1] as? UINavigationController,
           let myRideVC = navVC.topViewController as? MyRidesViewController {
            
            myRideVC.segmentedControl.selectedSegmentIndex = 0
            // viewWillAppear will call reloadTripsFromModel(), but we can force refresh:
            myRideVC.viewWillAppear(true)
        }
    }
}

