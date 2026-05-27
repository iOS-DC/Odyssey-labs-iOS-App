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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, studentButton, facultyButton, continueButton])
    }

    private func setupUI() {
        containerCard.applyCardStyle()

        configureRoleButton(
            studentButton,
            icon: "graduationcap.fill",
            title: "Student",
            subtitle: "Student at Chitkara University"
        )
        configureRoleButton(
            facultyButton,
            icon: "briefcase.fill",
            title: "Faculty",
            subtitle: "Faculty or staff at Chitkara"
        )

        continueButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(continueButton)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setPrimaryCTAEnabled(false)
        configureAccessibility()
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
            out.font = AppDesign.Typography.bodyStrong
            return out
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.subheadline
            out.foregroundColor = UIColor.secondaryLabel
            return out
        }

        button.configuration = config
        button.layer.cornerRadius = AppDesign.Radius.md
        button.layer.borderWidth = 1
        button.layer.borderColor = AppDesign.Color.border.cgColor
        button.backgroundColor = .systemBackground
    }

    private func updateSelectionUI() {
        let selectedBG = AppDesign.Color.primary.withAlphaComponent(0.1)
        let selectedBorder = AppDesign.Color.primary.cgColor
        let normalBorder = AppDesign.Color.border.cgColor

        for (button, role) in [(studentButton, UserRole.student), (facultyButton, UserRole.faculty)] {
            let isSelected = selectedRole == role
            button?.backgroundColor = isSelected ? selectedBG : .systemBackground
            button?.layer.borderColor = isSelected ? selectedBorder : normalBorder
            button?.layer.borderWidth = isSelected ? 2 : 1
            if isSelected {
                button?.accessibilityTraits.insert(.selected)
            } else {
                button?.accessibilityTraits.remove(.selected)
            }

            guard var cfg = button?.configuration else { continue }
            cfg.image = UIImage(systemName: role == .student ? "graduationcap.fill" : "briefcase.fill")
            button?.configuration = cfg
        }

        continueButton.setPrimaryCTAEnabled(selectedRole != nil)
    }

    @IBAction private func studentTapped(_ sender: UIButton) {
        AppHaptics.selection()
        selectedRole = .student
        updateSelectionUI()
    }

    @IBAction private func facultyTapped(_ sender: UIButton) {
        AppHaptics.selection()
        selectedRole = .faculty
        updateSelectionUI()
    }

    private func configureAccessibility() {
        studentButton.accessibilityLabel = "Student role"
        studentButton.accessibilityHint = "Select if you are enrolled as a student"
        facultyButton.accessibilityLabel = "Faculty role"
        facultyButton.accessibilityHint = "Select if you are faculty or staff"
        continueButton.accessibilityLabel = "Continue"
        continueButton.accessibilityHint = "Go to profile details step"
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
