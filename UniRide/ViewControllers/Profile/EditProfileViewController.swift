<<<<<<< Updated upstream
//
//  EditProfileViewController.swift
//  UniRide
//
//  Created by Student on 25/11/25.
//

=======
>>>>>>> Stashed changes
import UIKit

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

<<<<<<< Updated upstream
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private var newPhotoURL: URL? = nil   // store new photo until saving

    override func viewDidLoad() {
        super.viewDidLoad()
=======
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private var newPhotoURL: URL? = nil   // store new image temporarily

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Profile"
>>>>>>> Stashed changes
        setupUI()
        loadExistingProfile()
    }

    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

<<<<<<< Updated upstream
=======
    // MARK: - Load Existing Data
>>>>>>> Stashed changes
    private func loadExistingProfile() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        nameTextField.text = user.fullName
        mailTextField.text = user.email
        phoneTextField.text = user.phone

        if let yr = user.year {
            yearTextField.text = "\(yr)"
        }

        if let url = user.photoURL,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

    // MARK: - Change Photo
    @IBAction func changePhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

<<<<<<< Updated upstream
    // MARK: - Picker Result
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
=======
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
>>>>>>> Stashed changes

        if let image = info[.editedImage] as? UIImage ??
                       info[.originalImage] as? UIImage {

            profileImageView.image = image

            // Save image temporarily
            if let data = image.jpegData(compressionQuality: 0.85) {
<<<<<<< Updated upstream
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile_temp.jpg")
                try? data.write(to: url)
                newPhotoURL = url   // store until Save button tapped
=======
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("profile_temp.jpg")
                try? data.write(to: url)
                newPhotoURL = url
>>>>>>> Stashed changes
            }
        }
        dismiss(animated: true)
    }

    // MARK: - Save Button
    @IBAction func saveButtonTapped(_ sender: Any) {

        guard let user = UserDataModel.shared.getCurrentUser() else { return }

<<<<<<< Updated upstream
        let updatedFullName = nameTextField.text ?? user.fullName
=======
        let updatedName = nameTextField.text ?? user.fullName
>>>>>>> Stashed changes
        let updatedEmail = mailTextField.text ?? user.email
        let updatedPhone = phoneTextField.text ?? user.phone
        let updatedYear = Int(yearTextField.text ?? "") ?? user.year

<<<<<<< Updated upstream
        // Update main fields
        UserDataModel.shared.editCurrentUser(
            fullName: updatedFullName,
            courseName: nil,                 // removed course
=======
        // Update main fields (except phone & email)
        UserDataModel.shared.editCurrentUser(
            fullName: updatedName,
            courseName: nil,
>>>>>>> Stashed changes
            year: updatedYear,
            photoURL: newPhotoURL ?? user.photoURL,
            vehicle: user.vehicle
        )

<<<<<<< Updated upstream
        // Update phone manually
        if let phone = updatedPhone, !phone.isEmpty {
            if var updatedUser = UserDataModel.shared.getCurrentUser() {
                updatedUser.phone = phone
                UserDataModel.shared.editCurrentUser(
                    fullName: updatedUser.fullName,
                    courseName: nil,
                    year: updatedUser.year,
                    photoURL: updatedUser.photoURL,
                    vehicle: updatedUser.vehicle
                )
            }
        }

        // Email is part of UserProfile struct, but editCurrentUser doesn't update it.
        // If you want to update email too inside the model, tell me and I’ll add it.

=======
        // Now update phone + email inside the struct
        if var updatedUser = UserDataModel.shared.getCurrentUser() {
            updatedUser.phone = updatedPhone
            updatedUser.email = updatedEmail

            UserDataModel.shared.editCurrentUser(
                fullName: updatedUser.fullName,
                courseName: nil,
                year: updatedUser.year,
                photoURL: updatedUser.photoURL,
                vehicle: updatedUser.vehicle
            )
        }

        // Return to Profile screen
>>>>>>> Stashed changes
        navigationController?.popViewController(animated: true)
    }
}

