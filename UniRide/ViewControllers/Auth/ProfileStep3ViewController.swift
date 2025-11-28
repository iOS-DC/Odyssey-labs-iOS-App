//
//  ProfileStep3ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 19/11/25.
//


import UIKit

class ProfileStep3ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var containerCard: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var verificationCard: UIView!
    @IBOutlet weak var completeSetupButton: UIButton!

    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        profileImageView.tintColor = .systemGray3

        uploadButton.layer.cornerRadius = 15
        completeSetupButton.layer.cornerRadius = 20
    }

    // Upload Photo
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true

        present(picker, animated: true)
    }

    // Image Picker Result
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

    
    @IBAction func completeSetupTapped(_ sender: UIButton) {

        if let img = selectedImage {
            // Save temporarily
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

