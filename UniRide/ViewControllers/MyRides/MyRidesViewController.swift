//
//  MyRidesViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit

class MyRidesViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    private var upcomingTrips: [RideDataModel.MyTrip] = []
        private var pastTrips: [RideDataModel.MyTrip] = []
        private var currentTrips: [RideDataModel.MyTrip] = []
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.selectedSegmentIndex = 0
        
        
        
        tableView.register(
            UINib(nibName: "UpcommingTableViewCell", bundle: nil),
            forCellReuseIdentifier: "UpcommingRideCell")
        


        
        tableView.dataSource = self
           tableView.delegate = self
           tableView.separatorStyle = .none
           tableView.rowHeight = 180   // optional, makes card tall enough
              // TEMP: add some fake rides so you can see UI
        reloadTripsFromModel()
              updateForSelectedSegment()

        // Do any additional setup after loading the view.
    }
    
    // When you come back from Offer Ride / other screens
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           reloadTripsFromModel()
           updateForSelectedSegment()
       }
       
       // MARK: - Load real data from RideDataModel
    private func reloadTripsFromModel() {
          // ✅ Use getCurrentUser(), not currentUser
          guard let currentUser = UserDataModel.shared.getCurrentUser() else {
              // No logged-in user, clear arrays
              upcomingTrips = []
              pastTrips = []
              currentTrips = []
              tableView.reloadData()
              print("No current user, clearing trips")
              return
          }
          
          let userID = currentUser.id
          let model = RideDataModel.shared
          
          // Load from local plist store
          upcomingTrips = model.myUpcoming(userID: userID)
          pastTrips    = model.myPast(userID: userID)
          
          print("Loaded upcoming = \(upcomingTrips.count), past = \(pastTrips.count)")
      }
      
      // MARK: - Segment switching
      func updateForSelectedSegment() {
          if segmentedControl.selectedSegmentIndex == 0 {
              currentTrips = upcomingTrips
          } else {
              currentTrips = pastTrips
          }
          print("currentTrips count =", currentTrips.count)
          tableView.reloadData()
      }
      
      @IBAction func segmentChanged(_ sender: UISegmentedControl) {
          updateForSelectedSegment()
      }
  }

  // MARK: - Table View
  extension MyRidesViewController: UITableViewDataSource, UITableViewDelegate {
      
      func tableView(_ tableView: UITableView,
                     numberOfRowsInSection section: Int) -> Int {
          print("numberOfRowsInSection called, rows =", currentTrips.count)
          return currentTrips.count
      }
      
      func tableView(_ tableView: UITableView,
                     cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          print("cellForRowAt called for row", indexPath.row)
          
          guard let cell = tableView.dequeueReusableCell(
              withIdentifier: "UpcommingRideCell",
              for: indexPath
          ) as? UpcommingTableViewCell else {
              return UITableViewCell()
          }
          
          let trip = currentTrips[indexPath.row]
          cell.configure(with: trip)   // make sure this function exists in your cell
          return cell
      }
      
      func tableView(_ tableView: UITableView,
                     didSelectRowAt indexPath: IndexPath) {
          tableView.deselectRow(at: indexPath, animated: true)
          print("Tapped row \(indexPath.row)")
          // later: push ride details screen
      }
  }
