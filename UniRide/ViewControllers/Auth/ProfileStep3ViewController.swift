
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

        applyStyles()
        
    }

    private func applyStyles() {
            containerCard.applyCardStyle()
            verificationCard.applySmallCard()

            uploadButton.applyPrimaryButton(color: .systemBlue)
            completeSetupButton.applyPrimaryButton()

            // Circular profile image
            profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
            profileImageView.clipsToBounds = true
        }


    
    @IBAction func uploadPhotoTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

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
            let filename = UUID().uuidString + ".png"
            
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = documents.appendingPathComponent(filename)


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
