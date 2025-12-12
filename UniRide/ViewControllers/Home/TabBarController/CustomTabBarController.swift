//
//  CustomTabBarController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 25/11/25.
//


import UIKit

final class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            // Trigger location permission when screen is fully visible
            LocationService.shared.requestWhenInUse()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        //live location tracking globally
        
    }

    // When switching tabs, always reset the navigation stack
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        // If the selected tab has a navigation controller, reset to root
        if let nav = viewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }
}
