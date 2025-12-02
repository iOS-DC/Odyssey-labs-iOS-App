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

        setupNavBar()
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

        // TEMP — you can replace this once you add 'createdAt'
        memberSinceLabel.text = "Member Since 2025"

        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"

        // MARK: CONTACT INFO
        emailLabel.text = profile.email
        phoneLabel.text = profile.phone ?? "Not added"

        // MARK: PROFILE IMAGE
        if let url = profile.photoURL {
            loadImageAsync(from: url)
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

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

        guard let editVC = storyboard.instantiateViewController(
            withIdentifier: "EditProfileViewController"
        ) as? EditProfileViewController else {
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
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")

        // 3. Reset root controller → prevents going back
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            let nav = UINavigationController(rootViewController: onboardingVC)
            sceneDelegate.window?.rootViewController = nav
            sceneDelegate.window?.makeKeyAndVisible()
        }

        print("🚪 User logged out → moved to Onboarding")
    }
}

