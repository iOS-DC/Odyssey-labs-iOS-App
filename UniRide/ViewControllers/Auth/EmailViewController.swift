


import UIKit

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "College Verification"
        applyOnboardingChrome(step: 1, total: 7)
        containerCard.applyCardStyle()
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
        setupLogo()
        setupGuestButton()
    }

    private var guestButton: UIButton!
    
    private func setupGuestButton() {
        guestButton = UIButton(type: .system)
        guestButton.setTitle("Continue as Guest", for: .normal)
        guestButton.titleLabel?.font = AppDesign.Typography.subheadline
        guestButton.setTitleColor(.secondaryLabel, for: .normal)
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guestButton)
        
        NSLayoutConstraint.activate([
            guestButton.topAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: 16),
            guestButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guestButton.heightAnchor.constraint(equalToConstant: 44) // Generous touch target
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([logoImageView, containerCard, emailTextField, continueButton, guestButton])
    }
    @IBOutlet weak var containerCard: UIView!
    private var logoImageView: UIImageView!

    private func setupLogo() {
        logoImageView = addOnboardingLogo(above: containerCard)
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
    
    @objc private func guestTapped() {
        AppHaptics.selection()
        SessionManager.shared.setGuestMode(true)
        
        // Match the behavior of completing OTP or SceneDelegate restore
        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        let tabBar = mainSB.instantiateViewController(withIdentifier: "MainTabBarController")
        
        if let window = view.window {
            window.rootViewController = tabBar
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
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
