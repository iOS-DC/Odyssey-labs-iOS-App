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
<<<<<<< Updated upstream
<<<<<<< Updated upstream

        self.title = "Profile"

<<<<<<< Updated upstream
        // Right → Edit
=======
>>>>>>> Stashed changes
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )

<<<<<<< Updated upstream
        // Left → Logout
=======
>>>>>>> Stashed changes
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

=======
        self.title = "Profile"
>>>>>>> Stashed changes
=======

        setupNavBar()
>>>>>>> Stashed changes
        loadProfile()
    }
<<<<<<< Updated upstream
    
=======

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        loadProfile()  // refresh after editing
=======
        loadProfile()
>>>>>>> Stashed changes
=======
        loadProfile()     // Refresh when returning from edit screen
>>>>>>> Stashed changes
    }

>>>>>>> Stashed changes
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

        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName
        departmentLabel.text = profile.courseName ?? "Not set"
<<<<<<< Updated upstream
        yearLabel.text = profile.year != nil ? "Year \(profile.year!)" : "Not set"
        memberSinceLabel.text = "Member Since \(profile.id.uuidString.prefix(4))"

<<<<<<< Updated upstream
<<<<<<< Updated upstream
        // TEMPORARY STATIC VALUES
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======

        if let year = profile.year {
            yearLabel.text = "Year \(year)"
        } else {
            yearLabel.text = "Not set"
        }

        // TEMP — you can replace this once you add 'createdAt'
        memberSinceLabel.text = "Member Since 2025"

>>>>>>> Stashed changes
        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"

        emailLabel.text = profile.email
        phoneLabel.text = profile.phone ?? "Not added"

        if let url = profile.photoURL {
<<<<<<< Updated upstream
            DispatchQueue.global(qos: .background).async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.profileImageView.image = image }
                } else {
                    DispatchQueue.main.async { self.profileImageView.image = UIImage(named: "defaultProfile") }
                }
            }
=======
            loadImageAsync(from: url)
>>>>>>> Stashed changes
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - Edit Button
<<<<<<< Updated upstream
    @IBAction func editButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
<<<<<<< Updated upstream
        
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
=======
=======

    // MARK: - Storyboard Edit Button
    @IBAction func editButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "editprofile", bundle: nil)
>>>>>>> Stashed changes
=======

    // MARK: - Async Image Loader
    private func loadImageAsync(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
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
>>>>>>> Stashed changes

        guard let editVC = storyboard.instantiateViewController(
            withIdentifier: "EditProfileViewController"
        ) as? EditProfileViewController else {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            print("❌ ERROR: 'EditProfileViewController' not found")
=======
            print("❌ ERROR: EditProfileViewController not found in storyboard")
>>>>>>> Stashed changes
            return
>>>>>>> Stashed changes
        }
=======
            print("❌ EditProfileViewController not found in EditProfile.storyboard")
            return
        }

        navigationController?.pushViewController(editVC, animated: true)
    }


    // MARK: - Logout Button Action
    @objc private func logoutTapped() {

        // 1. Clear current user
        UserDataModel.shared.logout()

        // 2. Load Onboarding screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")

        // 3. Reset root controller → prevents going back
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            let nav = UINavigationController(rootViewController: onboardingVC)
            sceneDelegate.window?.rootViewController = nav
            sceneDelegate.window?.makeKeyAndVisible()
        }

        print("🚪 User logged out → moved to Onboarding")
>>>>>>> Stashed changes
    }

<<<<<<< Updated upstream
    // MARK: - Logout (No login navigation)
    @objc func logoutTapped() {
=======
    // MARK: - Storyboard Logout Button
    @IBAction func logoutButtonPressed(_ sender: Any) {
>>>>>>> Stashed changes
        let alert = UIAlertController(
            title: "Logout?",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            UserDataModel.shared.logout()
            self.navigationController?.popViewController(animated: true)
        }))

        present(alert, animated: true)
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream

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
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}

