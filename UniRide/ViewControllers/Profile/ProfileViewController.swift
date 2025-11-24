//
//  ProfileViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/11/25.
//

import UIKit

class ProfileViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var memberSinceLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ridesLabel: UILabel!
    @IBOutlet weak var EmailAddress: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var Phonenumber: UITextField!
    @IBOutlet weak var phoneLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfile()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Apply circular image AFTER layout
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
    }

    // MARK: - Load Data from Model
    private func loadProfile() {
        guard let profile = ProfileDataModel.shared.getProfile() else { return }

        nameLabel.text = profile.fullName
        departmentLabel.text = profile.department
        yearLabel.text = profile.year
        memberSinceLabel.text = "Member Since \(profile.memberSince)"

        ratingLabel.text = "\(profile.rating) ★"
        ridesLabel.text = "\(profile.totalRides) rides"

        emailLabel.text = profile.email
        phoneLabel.text = profile.phone

        if let imageName = profile.profileImage {
            profileImageView.image = UIImage(named: imageName)
        }
    }

    // MARK: - Edit Button Action
    @IBAction func editButtonTapped(_ sender: Any) {
        print("Edit button pressed")
        // Navigation to Edit screen will go here
    }
}


