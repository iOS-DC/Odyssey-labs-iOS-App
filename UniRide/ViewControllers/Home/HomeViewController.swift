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
    @IBAction func offerRideTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "OfferRide", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OfferRideViewController") as! OfferRideViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @IBAction func joinRide(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "JoinRide", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "JoinRideViewController") as! JoinRideViewController
        navigationController?.pushViewController(vc, animated: true)
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
        return indexPath.section == 0 ? 200 : 180  // +20
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = UIColor.black
        label.text = section == 0 ? "Nearby Rides" : "Top Events"
        return label
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let space = UIView()
        space.backgroundColor = .clear
        return space
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }


}

