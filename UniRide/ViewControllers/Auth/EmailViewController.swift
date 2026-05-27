
import UIKit

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var containerCard: UIView!

    private let guestButton = UIButton(type: .system)
    private var errorLabelTopConstraint: NSLayoutConstraint?
    private var errorLabelTrailingConstraint: NSLayoutConstraint?
    private var continueButtonTopConstraint: NSLayoutConstraint?
    private let otpCooldownKey = "emailOTPLastSentAt"
    private let otpCooldownInterval: TimeInterval = 30
    
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
        // Also handle iOS autofill which doesn't always fire .editingChanged
        NotificationCenter.default.addObserver(self, selector: #selector(emailChanged),
                                               name: UITextField.textDidChangeNotification,
                                               object: emailTextField)
        setupErrorLabelLayout()
        configureAccessibility()
        setupGuestButton()
        
        // Fix title padding if it's too high
        adjustTitlePadding()
    }

    private func setupErrorLabelLayout() {
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.font = AppDesign.Typography.captionStrong
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        containerCard.constraints.forEach { constraint in
            let firstView = constraint.firstItem as? UIView
            let secondView = constraint.secondItem as? UIView

            let connectsErrorAndField =
                (firstView == errorLabel && secondView == emailTextField) ||
                (firstView == emailTextField && secondView == errorLabel)
            let connectsErrorAndContinue =
                (firstView == errorLabel && secondView == continueButton) ||
                (firstView == continueButton && secondView == errorLabel)
            let isErrorPositionConstraint =
                firstView == errorLabel || secondView == errorLabel

            if connectsErrorAndField || connectsErrorAndContinue || isErrorPositionConstraint {
                if constraint.firstAttribute == .top || constraint.secondAttribute == .top ||
                    constraint.firstAttribute == .leading || constraint.secondAttribute == .leading ||
                    constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing ||
                    constraint.firstAttribute == .centerX || constraint.secondAttribute == .centerX {
                    constraint.isActive = false
                }
            }

            if connectsErrorAndContinue,
               constraint.firstAttribute == .top || constraint.secondAttribute == .top {
                constraint.isActive = false
            }
        }

        errorLabelTopConstraint = errorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 12)
        errorLabelTrailingConstraint = errorLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -20)
        continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16)

        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),
            errorLabelTopConstraint!,
            errorLabelTrailingConstraint!,
            continueButtonTopConstraint!
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailChanged() // catch any pre-filled / autofilled text
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, emailTextField, continueButton, guestButton])
    }

    private func setupGuestButton() {
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        guestButton.setTitle("Explore as Guest", for: .normal)
        guestButton.setTitleColor(.secondaryLabel, for: .normal)
        guestButton.titleLabel?.font = AppDesign.Typography.subheadline
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
        let isValid = raw.hasSuffix("@chitkara.edu.in")
            || raw.hasSuffix("@chitkarauniversity.edu.in")
            || EventAdminSession.shared.isAdminEmail(raw)
        continueButton.setPrimaryCTAEnabled(isValid)
    }
    
    
    @IBAction func continueTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        errorLabel.text = nil
        let raw = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let isEventAdminEmail = EventAdminSession.shared.isAdminEmail(raw)

        if !isEventAdminEmail, let remaining = remainingCooldownSeconds(), remaining > 0 {
            let msg = "Too many attempts. Try again in \(remaining)s."
            showError(msg)
            let alert = UIAlertController(title: "Too Many Attempts", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            present(alert, animated: true)
            return
        }

        continueButton.setPrimaryCTAEnabled(false)
        showAppLoading(message: "Verifying your email...")

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { 
                self.hideAppLoading()
                self.emailChanged() 
            }

            do {
                if isEventAdminEmail {
                    UserDefaults.standard.set(raw.lowercased(), forKey: "lastEmailForOTP")
                    let otpVC = storyboard!.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                    otpVC.verificationMode = .email
                    let nav = UINavigationController(rootViewController: otpVC)
                    nav.modalPresentationStyle = .fullScreen
                    present(nav, animated: true, completion: nil)
                    return
                }

                try await UserDataModel.shared.startEmailVerificationAsync(email: raw)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: otpCooldownKey)

                // Storing email for OTP screen
                UserDefaults.standard.set(raw, forKey: "lastEmailForOTP")

                let otpVC = storyboard!.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                otpVC.verificationMode = .email

                let nav = UINavigationController(rootViewController: otpVC)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            } catch {
                let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                let displayMessage = message.isEmpty ? "Couldn't send a code. Double-check your email and try again." : message
                showError(displayMessage)
                let alert = UIAlertController(title: "Sign-In Failed", message: displayMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Got It", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func remainingCooldownSeconds() -> Int? {
        let lastSentAt = UserDefaults.standard.double(forKey: otpCooldownKey)
        guard lastSentAt > 0 else { return nil }

        let elapsed = Date().timeIntervalSince1970 - lastSentAt
        let remaining = otpCooldownInterval - elapsed
        guard remaining > 0 else { return nil }
        return Int(ceil(remaining))
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        view.layoutIfNeeded()
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
