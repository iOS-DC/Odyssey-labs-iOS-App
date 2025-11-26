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
        loadProfile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
<<<<<<< Updated upstream
    
    // MARK: - Load Profile Data
    private func loadProfile() {
        
=======

    // MARK: - Load Profile Data
    private func loadProfile() {

>>>>>>> Stashed changes
        guard let profile = UserDataModel.shared.getCurrentUser() else {
            print("❌ No logged-in user found")
            return
        }
<<<<<<< Updated upstream
        
        // MARK: BASIC INFO
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName
        departmentLabel.text = profile.courseName ?? "Not set"
        
=======

        // MARK: BASIC INFO
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName
        departmentLabel.text = profile.courseName ?? "Not set"

>>>>>>> Stashed changes
        if let year = profile.year {
            yearLabel.text = "Year \(year)"
        } else {
            yearLabel.text = "Not set"
        }
<<<<<<< Updated upstream
        
        memberSinceLabel.text = "Member Since \(profile.id.uuidString.prefix(4))"
        
        // Temporary static values until added to model
        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"
        
        // MARK: CONTACT INFO
        emailLabel.text = profile.email
        phoneLabel.text = profile.phone ?? "Not added"
        
=======

        memberSinceLabel.text = "Member Since \(profile.id.uuidString.prefix(4))"

        // Temporary static values until added to model
        ratingLabel.text = "4.9 ★"
        ridesLabel.text = "12 rides"

        // MARK: CONTACT INFO
        emailLabel.text = profile.email
        phoneLabel.text = profile.phone ?? "Not added"

>>>>>>> Stashed changes
        // MARK: PROFILE IMAGE
        if let url = profile.photoURL {
            DispatchQueue.global(qos: .background).async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(named: "defaultProfile")
                    }
                }
            }
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }
<<<<<<< Updated upstream
    
    // MARK: - Edit Button
    @IBAction func editButtonTapped(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
}
=======

    // MARK: - Edit Button
    @IBAction func editButtonTapped(_ sender: Any) {
        print("✏️ Edit button tapped")
        // TODO: Navigate to edit profile screen
    }
}

>>>>>>> Stashed changes
