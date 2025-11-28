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
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar title
        self.title = "Profile"

        // Right → Edit
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )

        // Left → Logout
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

        loadProfile()
    }
<<<<<<< Updated upstream
    
=======

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()  // refresh after editing
    }

>>>>>>> Stashed changes
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Load Profile Data
    private func loadProfile() {

        guard let profile = UserDataModel.shared.getCurrentUser() else {
            print("❌ No logged-in user found")
            return
        }

        // BASIC INFO
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName
        departmentLabel.text = profile.courseName ?? "Not set"
        yearLabel.text = profile.year != nil ? "Year \(profile.year!)" : "Not set"
        memberSinceLabel.text = "Member Since \(profile.id.uuidString.prefix(4))"

        // TEMPORARY STATIC VALUES
        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"

        // CONTACT
        emailLabel.text = profile.email
        phoneLabel.text = profile.phone ?? "Not added"

        // PROFILE IMAGE
        if let url = profile.photoURL {
            DispatchQueue.global(qos: .background).async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.profileImageView.image = image }
                } else {
                    DispatchQueue.main.async { self.profileImageView.image = UIImage(named: "defaultProfile") }
                }
            }
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }
    
    // MARK: - Edit Button
<<<<<<< Updated upstream
    @IBAction func editButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
            navigationController?.pushViewController(editVC, animated: true)
        }
=======
    @objc func editTapped() {
        let storyboard = UIStoryboard(name: "EditProfile", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
            navigationController?.pushViewController(editVC, animated: true)
        } else {
            print(" ERROR: No ViewController with Storyboard ID 'EditProfileViewController'")
        }
    }

    // MARK: - Logout
    @objc func logoutTapped() {
        let alert = UIAlertController(
            title: "Logout?",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            UserDataModel.shared.logout()
            self.navigateToLogin()
        }))

        present(alert, animated: true)
    }

    private func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? UIViewController else {
            print("⚠️ Login screen not found. Check Storyboard ID.")
            return
        }

        let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate

        sceneDelegate?.window?.rootViewController = UINavigationController(rootViewController: loginVC)
>>>>>>> Stashed changes
    }
}

