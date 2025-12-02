import UIKit

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private var newPhotoURL: URL? = nil   // Store selected image temporarily

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        setupUI()
        loadExistingData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Setup UI
    private func setupUI() {

        // Tap on image
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tap)
    }

    // MARK: - Load Existing Profile Data
    private func loadExistingData() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        nameTextField.text = user.fullName
        mailTextField.text = user.email
        phoneTextField.text = user.phone
        yearTextField.text = user.year != nil ? "\(user.year!)" : ""

        if let url = user.photoURL,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

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

        navigationController?.popViewController(animated: true)
    }
}

