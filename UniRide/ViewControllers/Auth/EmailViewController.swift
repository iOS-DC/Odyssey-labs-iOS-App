
import UIKit

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var containerCard: UIView!

    private let guestButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "College Verification"
        applyOnboardingChrome(step: 1, total: 7)
        containerCard.applyCardStyle()
        
        // Remove fixed height constraint from Storyboard to allow dynamic growth
        containerCard.constraints.forEach {
            if $0.firstAttribute == .height {
                $0.isActive = false
            }
        }
        
        emailTextField.applyRoundedField()
        continueButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(continueButton)
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        continueButton.setPrimaryCTAEnabled(false)
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        configureAccessibility()
        setupGuestButton()
        
        // Fix title padding if it's too high
        adjustTitlePadding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, emailTextField, continueButton, guestButton])
    }

    private func setupGuestButton() {
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        guestButton.setTitle("Explore as Guest", for: .normal)
        guestButton.setTitleColor(.secondaryLabel, for: .normal)
        guestButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)
        
        containerCard.addSubview(guestButton)
        NSLayoutConstraint.activate([
            guestButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 16),
            guestButton.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            guestButton.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -24), // More bottom padding
            guestButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func adjustTitlePadding() {
        // Find the title label by checking its text
        for subview in containerCard.subviews {
            if let label = subview as? UILabel, (label.text?.contains("What's your") == true) {
                // Increase top space if it's constrained to the top
                for constraint in containerCard.constraints {
                    if (constraint.firstItem as? UILabel == label || constraint.secondItem as? UILabel == label),
                       (constraint.firstAttribute == .top || constraint.secondAttribute == .top) {
                        constraint.constant = 32 // Increase from 24 to 32
                    }
                }
            }
        }
    }

    @objc private func guestTapped() {
        AppHaptics.selection()
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = sb.instantiateViewController(withIdentifier: "MainTabBarController")
        
        if let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = scene.window {
            window.rootViewController = rootVC
            UIView.transition(with: window, duration: 0.45, options: .transitionCrossDissolve, animations: nil)
        }
    }

    private func configureAccessibility() {
        emailTextField.accessibilityLabel = "University email"
        emailTextField.accessibilityHint = "Enter your Chitkara email address"
        continueButton.accessibilityLabel = "Continue"
        continueButton.accessibilityHint = "Sends a verification code to your email"
        errorLabel.accessibilityLabel = "Email error"
    }
    
    @objc private func emailChanged() {
        let raw = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isValid = raw.hasSuffix("@chitkara.edu.in") || raw.hasSuffix("@chitkarauniversity.edu.in")
        continueButton.setPrimaryCTAEnabled(isValid)
    }
    
    
    @IBAction func continueTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let raw = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        continueButton.setPrimaryCTAEnabled(false)

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.emailChanged() }

            do {
                try await UserDataModel.shared.startEmailVerificationAsync(email: raw)

                // Storing email for OTP screen
                UserDefaults.standard.set(raw, forKey: "lastEmailForOTP")

                let otpVC = storyboard!.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                otpVC.verificationMode = .email

                let nav = UINavigationController(rootViewController: otpVC)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            } catch {
                errorLabel.text = error.localizedDescription
                errorLabel.isHidden = false
            }
        }
    }
    
}

// UITextField padding helper at file scope
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
