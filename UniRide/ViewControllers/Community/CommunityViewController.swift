//
//  CommunityViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sementedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    var showNewPostCell = false

      override func viewDidLoad() {
          super.viewDidLoad()
          
          title = "Community"
          
          navigationItem.rightBarButtonItem =
              UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddPost))
          
          tableView.delegate = self
          tableView.dataSource = self
      }

    @objc func didTapAddPost() {
        showNewPostCell = true
               tableView.reloadData()
    }


    
 

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sementedControl.selectedSegmentIndex == 0 { // Feed
            return showNewPostCell ? 3 : 2   // 1 new post + 2 feed items
        } else { // Events
            return 2 // Or event count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if sementedControl.selectedSegmentIndex == 0 { // Feed section
            if showNewPostCell && indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NewPostCell", for: indexPath)
                if let textView = cell.viewWithTag(1) as? UITextView {
                    textView.text = "What's on your mind? Need a ride or offering one?"
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
                
                if let username = cell.viewWithTag(2) as? UILabel {
                    username.text = "Rehan Khan"
                }
                if let time = cell.viewWithTag(4) as? UILabel {
                    time.text = "2 hours ago"
                }
                if let message = cell.viewWithTag(5) as? UILabel {
                    message.text = "Planning a weekend trip to Kasauli!"
                }
                return cell
            }
            
        } else { // Event cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
            
            if let title = cell.viewWithTag(2) as? UILabel {
                title.text = "Rangrez 2025"
            }
            if let date = cell.viewWithTag(3) as? UILabel {
                date.text = "Nov 6, 2025 at 14:00"
            }
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sementedControl.selectedSegmentIndex == 0 {
            if showNewPostCell && indexPath.row == 0 { return 200 }
            return 160
        }
        return 150
    }
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showNewPostCell = false
        tableView.reloadData()
    }


}
