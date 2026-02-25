import UIKit

final class RoleSelectionViewController: UIViewController {
    @IBOutlet private weak var containerCard: UIView!
    @IBOutlet private weak var studentButton: UIButton!
    @IBOutlet private weak var facultyButton: UIButton!
    @IBOutlet private weak var continueButton: UIButton!

    private var selectedRole: UserRole?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tell us about yourself"
        applyOnboardingChrome(step: 3, total: 7)
        setupUI()
        updateSelectionUI()
    }

    private func setupUI() {
        containerCard.applyCardStyle()

        configureRoleButton(
            studentButton,
            icon: "graduationcap.fill",
            title: "Student",
            subtitle: "I'm currently enrolled as a student"
        )
        configureRoleButton(
            facultyButton,
            icon: "briefcase.fill",
            title: "Faculty",
            subtitle: "I'm a faculty or staff member"
        )

        continueButton.applyPrimaryButton(color: .systemBlue)
        applyPrimaryOnboardingCTAStyle(continueButton)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
    }

    private func configureRoleButton(_ button: UIButton, icon: String, title: String, subtitle: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = subtitle
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .leading
        config.imagePadding = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        config.titleAlignment = .leading
        config.baseForegroundColor = .label

        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = .systemFont(ofSize: 18, weight: .semibold)
            return out
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = .systemFont(ofSize: 14, weight: .regular)
            out.foregroundColor = UIColor.secondaryLabel
            return out
        }

        button.configuration = config
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.backgroundColor = .systemBackground
    }

    private func updateSelectionUI() {
        let selectedBG = UIColor.systemBlue.withAlphaComponent(0.1)
        let selectedBorder = UIColor.systemBlue.cgColor
        let normalBorder = UIColor.systemGray4.cgColor

        for (button, role) in [(studentButton, UserRole.student), (facultyButton, UserRole.faculty)] {
            let isSelected = selectedRole == role
            button?.backgroundColor = isSelected ? selectedBG : .systemBackground
            button?.layer.borderColor = isSelected ? selectedBorder : normalBorder
            button?.layer.borderWidth = isSelected ? 2 : 1

            guard var cfg = button?.configuration else { continue }
            cfg.image = UIImage(systemName: role == .student ? "graduationcap.fill" : "briefcase.fill")
            button?.configuration = cfg
        }

        continueButton.isEnabled = (selectedRole != nil)
        continueButton.alpha = selectedRole == nil ? 0.5 : 1.0
    }

    @IBAction private func studentTapped(_ sender: UIButton) {
        selectedRole = .student
        updateSelectionUI()
    }

    @IBAction private func facultyTapped(_ sender: UIButton) {
        selectedRole = .faculty
        updateSelectionUI()
    }

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard let selectedRole else { return }
        RegistrationBuilder.shared.role = selectedRole

        let main = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = main.instantiateViewController(withIdentifier: "ProfileStep1ViewController") as? ProfileStep1ViewController else { return }
        vc.lockedRole = selectedRole
        navigationController?.pushViewController(vc, animated: true)
    }
}
