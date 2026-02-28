//
//  RoutesBottomSheetViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 23/11/25.
//

import UIKit
import MapKit

protocol RoutesBottomSheetDelegate: AnyObject {
    /// Called when the user selects one of the presented routes
    func routesBottomSheet(_ sheet: RoutesBottomSheetViewController, didSelectRouteAt index: Int)
}

final class RoutesBottomSheetViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    /// Provided by the presenter (OfferRideViewController)
    var routes: [MKRoute] = []
    var routeLabels: [String] = []      // optional labels like "Fastest", "Shortest"
    weak var delegate: RoutesBottomSheetDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // table view setup
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "routeCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        // Configure as a sheet (iOS 15+)
        if let sheet = self.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = AppDesign.Radius.lg
        }
    }
}

extension RoutesBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Use subtitle style so we can show distance and time
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "routeCell")

        let route = routes[indexPath.row]
        let label = routeLabels.indices.contains(indexPath.row) ? routeLabels[indexPath.row] : "Route \(indexPath.row + 1)"
        cell.textLabel?.text = label

        let distKm = route.distance / 1000.0
        let timeMin = Int(route.expectedTravelTime / 60.0)
        cell.detailTextLabel?.text = String(format: "%.1f km — %d min", distKm, timeMin)

        cell.accessoryType = .none
        cell.selectionStyle = .default

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppHaptics.selection()
        delegate?.routesBottomSheet(self, didSelectRouteAt: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
    }
}
