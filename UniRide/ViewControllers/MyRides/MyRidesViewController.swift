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
    
    
    private var upcomingTrips: [String] = []   // temporary: just titles
       private var pastTrips: [String] = []
       private var currentTrips: [String] = []    // what we show based on segment
       
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.selectedSegmentIndex = 0
        
        
        
        tableView.register(
            UINib(nibName: "UpcommingTableViewCell", bundle: nil),
            forCellReuseIdentifier: "UpcommingRideCell"
        )
        


        
        tableView.dataSource = self
           tableView.delegate = self
           tableView.separatorStyle = .none
           tableView.rowHeight = 180   // optional, makes card tall enough
              // TEMP: add some fake rides so you can see UI
              loadDemoData()
              updateForSelectedSegment()

        // Do any additional setup after loading the view.
    }
    
  
    
    private func loadDemoData() {
            // Just some dummy names; later we use RideDataModel
            upcomingTrips = [
                "Chitkara Campus → Banur",
                "Hostel → Chandigarh"
            ]
            
            pastTrips = [
                "Chandigarh → Chitkara Campus"
            ]
        }
        
        private func updateForSelectedSegment() {
            if segmentedControl.selectedSegmentIndex == 0 {
                // Upcoming selected
                currentTrips = upcomingTrips
            } else {
                // Past selected
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

            
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "UpcommingRideCell",
                for: indexPath
            ) as! UpcommingTableViewCell

            
            // For now, just set some labels manually to see UI
            let title = currentTrips[indexPath.row]
            
            // You can adjust these outlets to whatever you named them
            cell.fromLabel.text = title.components(separatedBy: "→").first?.trimmingCharacters(in: .whitespaces)
            cell.toLabel.text = title.components(separatedBy: "→").last?.trimmingCharacters(in: .whitespaces)
            cell.statusLabel.text = (segmentedControl.selectedSegmentIndex == 0) ? "Published" : "Completed"
            cell.dateLabel.text = "Mon, Jan 16"
            cell.seatsLabel.text = "2/4 seats"
            cell.startTimeLabel.text = "11:00"
            cell.endTimeLabel.text = "13:00"
            cell.durationLabel.text = "2h"
            
            return cell
        }
        
        func tableView(_ tableView: UITableView,
                       didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            print("Tapped row \(indexPath.row)")
        }
    
    
   

}
