//
//  HomeViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var greetingsLabel: UILabel!
    @IBOutlet weak var homeTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = UserDataModel.shared.getCurrentUser()?.fullName ?? "User"
        greetingsLabel.text = "Hey, \(name)"
        homeTableView.layer.backgroundColor = UIColor(named: "#F6FAFB")?.cgColor
        setupTable()
    }

    func setupTable() {
        homeTableView.delegate = self
        homeTableView.dataSource = self
        homeTableView.separatorStyle = .none

        homeTableView.register(
            UINib(nibName: "RideTableViewCell", bundle: nil),
            forCellReuseIdentifier: "RideCell"
        )

        homeTableView.register(
            UINib(nibName: "EventTableViewCell", bundle: nil),
            forCellReuseIdentifier: "EventCell"
        )
    }
    
}
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Nearby Rides" : "Top Events"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return MockData.sampleRides.count }
        return MockData.sampleEvents.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RideCell", for: indexPath) as! RideTableViewCell
            cell.configure(with: MockData.sampleRides[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
            cell.configure(with: MockData.sampleEvents[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 180 : 160
    }
}

