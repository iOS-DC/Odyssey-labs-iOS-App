//
//  CustomTabBarController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 25/11/25.
//


import UIKit

final class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    // When switching tabs, always reset the navigation stack
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        // If the selected tab has a navigation controller, reset to root
        if let nav = viewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }
}
