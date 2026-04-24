//
//  OTPViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 11/11/25.
//


import UIKit

final class OTPViewController: UIViewController, UITextFieldDelegate {
    enum VerificationMode {
        case email
    }

    @IBOutlet weak var otpField1: UITextField!
    @IBOutlet weak var otpField2: UITextField!
    @IBOutlet weak var otpField3: UITextField!
    @IBOutlet weak var otpField4: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var resendLabel: UILabel!

    @IBOutlet weak var containerCard: UIView!
    var verificationMode: VerificationMode = .email
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel?
    private var resendTimer: Timer?
    private var seconds = 30
    private var dynamicOTPFields: [UITextField] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Verify Email"
        applyOnboardingChrome(step: 2, total: 7)
        configureBackButton()
        errorLabel.isHidden = true
        verifyButton.applyPrimaryButton(color: AppDesign.Color.primary, radius: AppDesign.Radius.sm)
        applyPrimaryOnboardingCTAStyle(verifyButton)
        verifyButton.setTitle("Verify & Continue", for: .normal)
        verifyButton.setPrimaryCTAEnabled(false)
        setupCard();
        [otpField1, otpField2, otpField3, otpField4].forEach {
            $0?.delegate = self
            $0?.keyboardType = .numberPad
            $0?.textAlignment = .center
            $0?.borderStyle = .none
            $0?.font = .monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            $0?.layer.cornerRadius = AppDesign.Radius.sm
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = AppDesign.Color.border.cgColor
            $0?.backgroundColor = AppDesign.Color.fieldBackground.withAlphaComponent(0.85)
        }
        ensureSixOTPFields()
        configureSubtitle()
        resendLabel.font = AppDesign.Typography.subheadline
        resendLabel.textColor = AppDesign.Color.primary
        configureAccessibility()

        let resendTap = UITapGestureRecognizer(target: self, action: #selector(resendTapped))
        resendLabel.addGestureRecognizer(resendTap)
        resendLabel.isUserInteractionEnabled = false

        startResendTimer()
        otpField1.becomeFirstResponder()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, titleLabel, verifyButton, resendLabel])
    }

    deinit {
        resendTimer?.invalidate()
    }
    
    func setupCard() {
        containerCard.applyCardStyle()
    }
    // Auto-advance fields
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString s: String) -> Bool {
        let fields = otpFields()
        if s.isEmpty {
            textField.text = ""
            if let idx = fields.firstIndex(of: textField), idx > 0 {
                fields[idx - 1].becomeFirstResponder()
            }
            updateVerifyButtonState()
            return false
        }

        // Only 1 char per box
        if s.count > 1 { return false }
        textField.text = s

        if let idx = fields.firstIndex(of: textField) {
            let next = idx + 1
            if next < fields.count {
                fields[next].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        updateVerifyButtonState()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        otpFields().forEach {
            $0.layer.borderColor = AppDesign.Color.border.cgColor
            $0.layer.borderWidth = 1
        }
        textField.layer.borderColor = AppDesign.Color.primary.cgColor
        textField.layer.borderWidth = 2
    }

    private func updateVerifyButtonState() {
        let code = otpFields().map { $0.text ?? "" }.joined()
        let ready = code.count == 6
        verifyButton.setPrimaryCTAEnabled(ready)
    }

    @IBAction func verifyTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let code = otpFields().map { $0.text ?? "" }.joined()

        guard code.count == 6 else {
            errorLabel.text = "Please enter all 6 digits"
            errorLabel.isHidden = false
            return
        }
        verifyButton.setPrimaryCTAEnabled(false)
        showAppLoading(message: "Verifying code...")

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { 
                self.hideAppLoading()
                self.updateVerifyButtonState() 
            }

            do {
                switch verificationMode {
                case .email:
                    let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    guard !email.isEmpty else {
                        errorLabel.text = "Code expired. Tap 'Resend code' to get a new one."
                        errorLabel.isHidden = false
                        return
                    }

                    let user = try await UserDataModel.shared.verifyEmailOTPAsync(email: email, code: code)

                    if let returningUser = user {
                        if UserDataModel.shared.isProfileSetupComplete(for: returningUser) {
                            goToTabBar()
                        } else {
                            // User exists but hasn't completed setup (legacy edge case)
                            RegistrationBuilder.shared.email = email
                            RegistrationBuilder.shared.isEmailVerified = true
                            let roleStoryboard = UIStoryboard(name: "RoleSelection", bundle: nil)
                            let vc = roleStoryboard.instantiateViewController(withIdentifier: "RoleSelectionViewController")
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        RegistrationBuilder.shared.email = email
                        RegistrationBuilder.shared.isEmailVerified = true
                        let roleStoryboard = UIStoryboard(name: "RoleSelection", bundle: nil)
                        let vc = roleStoryboard.instantiateViewController(withIdentifier: "RoleSelectionViewController")
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                errorLabel.text = error.localizedDescription
                errorLabel.isHidden = false
            }
        }

    }

    private func startResendTimer() {
        seconds = 30
        resendLabel.text = "Resend code in \(seconds)s"
        resendLabel.isUserInteractionEnabled = false
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in // prevents retain cycle between Timer and ViewController
            guard let self = self else { return }
            self.seconds -= 1
            if self.seconds <= 0 {
                self.resendTimer?.invalidate()
                self.resendLabel.text = "Resend code"
                self.resendLabel.isUserInteractionEnabled = true
                self.resendLabel.accessibilityTraits.insert(.button)
            } else {
                self.resendLabel.text = "Resend code in \(self.seconds)s"
                self.resendLabel.accessibilityTraits.remove(.button)
            }
        }
    }

    @objc private func resendTapped() {
        guard seconds <= 0 else { return }
        resendLabel.isUserInteractionEnabled = false
        showAppLoading(message: "Resending code...")

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.hideAppLoading() }
            do {
                switch verificationMode {
                case .email:
                    let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    guard !email.isEmpty else {
                        errorLabel.text = "Something went wrong. Go back and re-enter your email."
                        errorLabel.isHidden = false
                        return
                    }
                    try await UserDataModel.shared.startEmailVerificationAsync(email: email)
                }
                clearOTPFields()
                errorLabel.isHidden = true
                startResendTimer()
                otpFields().first?.becomeFirstResponder()
            } catch {
                errorLabel.text = error.localizedDescription
                errorLabel.isHidden = false
                resendLabel.isUserInteractionEnabled = true
            }
        }
    }

    private func clearOTPFields() {
        otpFields().forEach { $0.text = "" }
        updateVerifyButtonState()
    }

    private func otpFields() -> [UITextField] {
        let base = [otpField1, otpField2, otpField3, otpField4] + dynamicOTPFields
        return base.compactMap { $0 }
    }

    private func ensureSixOTPFields() {
        guard let stack = otpField1.superview as? UIStackView else { return }
        stack.spacing = AppDesign.Spacing.xs
        otpFields().forEach {
            if !$0.constraints.contains(where: { $0.firstAttribute == .width }) {
                $0.widthAnchor.constraint(equalToConstant: 44).isActive = true
            }
        }
        let missing = max(0, 6 - stack.arrangedSubviews.count)
        guard missing > 0 else { return }

        for _ in 0..<missing {
            let tf = UITextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.borderStyle = .none
            tf.textAlignment = .center
            tf.font = .monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            tf.keyboardType = .numberPad
            tf.layer.cornerRadius = AppDesign.Radius.sm
            tf.layer.borderWidth = 1
            tf.layer.borderColor = AppDesign.Color.border.cgColor
            tf.backgroundColor = AppDesign.Color.fieldBackground.withAlphaComponent(0.85)
            tf.delegate = self
            tf.heightAnchor.constraint(equalToConstant: 56).isActive = true
            tf.widthAnchor.constraint(equalToConstant: 44).isActive = true
            dynamicOTPFields.append(tf)
            stack.addArrangedSubview(tf)
        }
    }

    private func configureSubtitle() {
        titleLabel.text = "Verify your email"
        let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "").lowercased()
        subtitleLabel?.text = "We sent a 6-digit code to \(maskedEmail(email)). It expires in 10 minutes."
    }

    private func maskedEmail(_ email: String) -> String {
        guard let at = email.firstIndex(of: "@") else { return email }
        let name = String(email[..<at])
        let domain = String(email[at...])
        guard name.count > 2 else { return email }
        return "\(name.prefix(2))***\(domain)"
    }

    private func maskedPhone(_ phone: String) -> String {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4 else { return trimmed }
        return "••••\(trimmed.suffix(4))"
    }

    private func goToTabBar() {
        // Request APNs permission right after login so iOS shows the
        // "Allow Notifications?" prompt in a natural, logged-in context.
        PushNotificationService.shared.requestPermission()
        LiveNotificationService.shared.startIfPossible()

        let tabBar = storyboard?.instantiateViewController(identifier: "MainTabBarController") as! UITabBarController
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()

            // Optional transition animation
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }

    private func configureAccessibility() {
        titleLabel.accessibilityTraits.insert(.header)
        subtitleLabel?.accessibilityLabel = "One time password instructions"
        verifyButton.accessibilityLabel = "Verify and continue"
        resendLabel.accessibilityLabel = "Resend one time password"
        resendLabel.accessibilityTraits.remove(.button)

        for (idx, field) in otpFields().enumerated() {
            field.accessibilityLabel = "OTP digit \(idx + 1)"
            field.accessibilityHint = "Enter digit \(idx + 1) of 6"
        }
    }

    private func configureBackButton() {
        let image = UIImage(systemName: "chevron.left")
        let backButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(backTapped))
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func backTapped() {
        if let navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else if let navigationController {
            navigationController.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
