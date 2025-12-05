////
////  ProfileStep3ViewController.swift
////  UniRide
////
////  Created by Krish Bahukhandi on 19/11/25.
////
//
//import UIKit
//import CoreLocation
//
//class ProfileStep3ViewController: UIViewController,
//                                  UIImagePickerControllerDelegate,
//                                  UINavigationControllerDelegate,
//                                  CLLocationManagerDelegate {
//
//    @IBOutlet weak var containerCard: UIView!
//    @IBOutlet weak var profileImageView: UIImageView!
//    @IBOutlet weak var uploadButton: UIButton!
//    @IBOutlet weak var verificationCard: UIView!
//    @IBOutlet weak var completeSetupButton: UIButton!
//
//    private var selectedImage: UIImage?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//
//        // 🔥 Automatically trigger location popup
//        LocationService.shared.requestWhenInUse()
//        LocationService.shared.startLiveUpdates()
//    }
//
//
//    func setupUI() {
//        containerCard.layer.cornerRadius = 20
//        containerCard.layer.shadowColor = UIColor.black.cgColor
//        containerCard.layer.shadowOpacity = 0.08
//        containerCard.layer.shadowRadius = 10
//        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)
//
//        verificationCard.layer.cornerRadius = 15
//        verificationCard.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
//
//        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
//        profileImageView.clipsToBounds = true
//
//        uploadButton.layer.cornerRadius = 15
//        completeSetupButton.layer.cornerRadius = 20
//    }
//
//    // MARK: - LOCATION PERMISSION BUTTON
//    @IBAction func enableLocationTapped(_ sender: UIButton) {
//        LocationService.shared.requestWhenInUse()
//        LocationService.shared.startLiveUpdates()
//    }
//
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//        guard let loc = locations.last else {
//            return
//        }
//
//        let point = LocationPoint(
//            lat: loc.coordinate.latitude,
//            lon: loc.coordinate.longitude,
//            address: nil
//        )
//
//        // Save location to user profile
//        UserDataModel.shared.updateUserLocation(point)
//        print("User location saved:", point)
//
//    }
//
//    // MARK: - IMAGE PICKER
//    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
//        let picker = UIImagePickerController()
//        picker.delegate = self
//        picker.sourceType = .photoLibrary
//        picker.allowsEditing = true
//        present(picker, animated: true)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController,
//                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//        if let edited = info[.editedImage] as? UIImage {
//            selectedImage = edited
//            profileImageView.image = edited
//        } else if let original = info[.originalImage] as? UIImage {
//            selectedImage = original
//            profileImageView.image = original
//        }
//
//        picker.dismiss(animated: true)
//    }
//
//    // MARK: - COMPLETE SETUP
//    @IBAction func completeSetupTapped(_ sender: UIButton) {
//
//        if let img = selectedImage {
//            let filename = UUID().uuidString + ".png"
//            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
//
//            if let data = img.pngData() {
//                try? data.write(to: url)
//                UserDataModel.shared.editCurrentUser(photoURL: url)
//            }
//        }
//
//        goToTabBar()
//    }
//
//    @IBAction func skipTapped(_ sender: UIButton) {
//        goToTabBar()
//    }
//
//    func goToTabBar() {
//        let tabBar = storyboard?.instantiateViewController(identifier: "MainTabBarController") as! UITabBarController
//        navigationController?.setViewControllers([tabBar], animated: true)
//    }
//}

//
//  ProfileStep3ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 19/11/25.
//

import UIKit

class ProfileStep3ViewController: UIViewController,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate {

    @IBOutlet weak var containerCard: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var verificationCard: UIView!
    @IBOutlet weak var completeSetupButton: UIButton!

    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        // 🔥 Automatically show system popup asking for location
        LocationService.shared.requestWhenInUse()
        LocationService.shared.startLiveUpdates()
    }


    func setupUI() {
        containerCard.layer.cornerRadius = 20
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.08
        containerCard.layer.shadowRadius = 10
        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        verificationCard.layer.cornerRadius = 15
        verificationCard.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)

        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true

        uploadButton.layer.cornerRadius = 15
        completeSetupButton.layer.cornerRadius = 20
    }


    // MARK: - IMAGE PICKER
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let edited = info[.editedImage] as? UIImage {
            selectedImage = edited
            profileImageView.image = edited
        } else if let original = info[.originalImage] as? UIImage {
            selectedImage = original
            profileImageView.image = original
        }

        picker.dismiss(animated: true)
    }

    // MARK: - COMPLETE SETUP
    @IBAction func completeSetupTapped(_ sender: UIButton) {

        if let img = selectedImage {
            let filename = UUID().uuidString + ".png"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            if let data = img.pngData() {
                try? data.write(to: url)
                UserDataModel.shared.editCurrentUser(photoURL: url)
            }
        }

        goToTabBar()
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        goToTabBar()
    }

    func goToTabBar() {
        let tabBar = storyboard?.instantiateViewController(identifier: "MainTabBarController") as! UITabBarController
        navigationController?.setViewControllers([tabBar], animated: true)
    }
}
