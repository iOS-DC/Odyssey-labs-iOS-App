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

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private var newPhotoURL: URL? = nil
=======
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private var newPhotoURL: URL? = nil   // Store selected image temporarily
>>>>>>> Stashed changes

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
<<<<<<< Updated upstream
        self.title = "Edit Profile"

        setupUI()
        loadExistingProfile()
    }

    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
=======

        title = "Edit Profile"
        setupUI()
        loadExistingData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
>>>>>>> Stashed changes
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

<<<<<<< Updated upstream

    // MARK: - Load Existing Data

    private func loadExistingProfile() {
=======
    // MARK: - Setup UI
    private func setupUI() {

        // Tap on image
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tap)
    }

    // MARK: - Load Existing Profile Data
    private func loadExistingData() {
>>>>>>> Stashed changes
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        nameTextField.text = user.fullName
        mailTextField.text = user.email
        phoneTextField.text = user.phone
<<<<<<< Updated upstream

        if let yr = user.year {
            yearTextField.text = "\(yr)"
        }
=======
        yearTextField.text = user.year != nil ? "\(user.year!)" : ""
>>>>>>> Stashed changes

        if let url = user.photoURL,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

<<<<<<< Updated upstream
    // MARK: - Change Photo
    @IBAction func changePhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    // MARK: - Picker Result
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {


        if let image = info[.editedImage] as? UIImage ??
                       info[.originalImage] as? UIImage {

            profileImageView.image = image

            // Save image temporarily
            if let data = image.jpegData(compressionQuality: 0.85) {

                let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile_temp.jpg")
                try? data.write(to: url)
                newPhotoURL = url   // store until Save button tapped

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("profile_temp.jpg")
                try? data.write(to: url)
                newPhotoURL = url

            }
        }
        dismiss(animated: true)
    }

    // MARK: - Save Button
    @IBAction func saveButtonTapped(_ sender: Any) {

        guard let user = UserDataModel.shared.getCurrentUser() else { return }


        let updatedFullName = nameTextField.text ?? user.fullName

        let updatedName = nameTextField.text ?? user.fullName

        let updatedEmail = mailTextField.text ?? user.email
        let updatedPhone = phoneTextField.text ?? user.phone
        let updatedYear = Int(yearTextField.text ?? "") ?? user.year

        // Update main fields
        UserDataModel.shared.editCurrentUser(
            fullName: updatedFullName,
            courseName: nil,                 // removed course

        // Update main fields (except phone & email)
        UserDataModel.shared.editCurrentUser(
            fullName: updatedName,
            courseName: nil,

            year: updatedYear,
            photoURL: newPhotoURL ?? user.photoURL,
            vehicle: user.vehicle
        )


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
=======
    // MARK: - Change Photo Button Action
    @IBAction func changePhotoTapped(_ sender: Any) {
        selectImage()  // Button triggers selection too
    }

    // MARK: - Pick Image
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - Image Picker Result
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
            newPhotoURL = saveImageToDocuments(image: editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
            newPhotoURL = saveImageToDocuments(image: originalImage)
        }

        dismiss(animated: true)
    }

    // MARK: - Save Image to Local Storage
    private func saveImageToDocuments(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let fileName = "profile_\(UUID().uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            return url
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
        }
    }

    // MARK: - Save Button
    @IBAction func saveButtonTapped(_ sender: Any) {

        guard var user = UserDataModel.shared.getCurrentUser() else { return }

        // Update fields
        user.fullName = nameTextField.text ?? user.fullName
        user.email = mailTextField.text ?? user.email
        user.phone = phoneTextField.text

        if let yearText = yearTextField.text, let yearInt = Int(yearText) {
            user.year = yearInt
        }

        if let photoURL = newPhotoURL {
            user.photoURL = photoURL
        }

        // Save Updated User
        UserDataModel.shared.saveUserProfile(user)
>>>>>>> Stashed changes

        navigationController?.popViewController(animated: true)
    }
}

