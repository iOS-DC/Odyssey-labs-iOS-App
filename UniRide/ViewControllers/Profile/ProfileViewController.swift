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

    // These two are only TITLES ("Email", "Phone")
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!

    // Actual text fields to show values
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        loadProfile()
    }

    // 🔥 Automatically refresh profile when returning from Edit Profile
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Navigation Bar Setup
    private func setupNavBar() {
        title = "Profile"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
    }

    // MARK: - Load Profile Data
    private func loadProfile() {

        guard let profile = UserDataModel.shared.getCurrentUser() else {
            print("❌ No current user found.")
            return
        }

        // MARK: BASIC INFO
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName
        departmentLabel.text = profile.courseName ?? "Not set"

        if let year = profile.year {
            yearLabel.text = "Year \(year)"
        } else {
            yearLabel.text = "Not set"
        }

        memberSinceLabel.text = "Member Since 2025"
        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"

        // MARK: CONTACT INFO
        emailTextField.text = profile.email
        phoneTextField.text = profile.phone ?? ""

        // MARK: PROFILE IMAGE
        if let url = profile.photoURL {
            loadImageAsync(from: url)
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

    // MARK: - Async Image Loader
    private func loadImageAsync(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }

            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            } else {
                DispatchQueue.main.async {
                    self.profileImageView.image = UIImage(named: "defaultProfile")
                }
            }
        }.resume()
    }

    // MARK: - Edit Button Action
    @objc private func editButtonTapped() {

        let storyboard = UIStoryboard(name: "EditProfile", bundle: nil)

        guard let editVC = storyboard.instantiateViewController(
            withIdentifier: "EditProfileViewController"
        ) as? EditProfileViewController else {
            print("❌ EditProfileViewController not found in EditProfile.storyboard")
            return
        }

        navigationController?.pushViewController(editVC, animated: true)
    }

    // MARK: - Logout Button Action (WITH CONFIRMATION)
    @objc private func logoutTapped() {

        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })

        present(alert, animated: true)
    }

    // MARK: - Perform Logout (GO TO EMAIL LOGIN)
    private func performLogout() {

        UserDataModel.shared.logout()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let emailVC = storyboard.instantiateViewController(
            withIdentifier: "EmailViewController"
        )

        let nav = UINavigationController(rootViewController: emailVC)

        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = nav
            sceneDelegate.window?.makeKeyAndVisible()
        }

        print("🚪 User logged out → moved to EmailViewController")
    }
}

