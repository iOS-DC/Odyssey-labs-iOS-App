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
        case phone
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
    var phoneNumber: String?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel?
    private var resendTimer: Timer?
    private var seconds = 30
    private var dynamicOTPFields: [UITextField] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = verificationMode == .email ? "Verify Email" : "Verify Phone"
        applyOnboardingChrome(step: verificationMode == .email ? 2 : 5, total: 7)
        errorLabel.isHidden = true
        verifyButton.applyPrimaryButton(color: .systemBlue, radius: 12)
        applyPrimaryOnboardingCTAStyle(verifyButton)
        verifyButton.setTitle("Verify & Continue", for: .normal)
        verifyButton.isEnabled = false
        verifyButton.alpha = 0.5
        setupCard();
        [otpField1, otpField2, otpField3, otpField4].forEach {
            $0?.delegate = self
            $0?.keyboardType = .numberPad
            $0?.textAlignment = .center
            $0?.borderStyle = .none
            $0?.font = .monospacedDigitSystemFont(ofSize: 22, weight: .regular)
            $0?.layer.cornerRadius = 12
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.6)
        }
        ensureSixOTPFields()
        configureSubtitle()
        resendLabel.font = .systemFont(ofSize: 14, weight: .medium)
        resendLabel.textColor = .systemBlue

        let resendTap = UITapGestureRecognizer(target: self, action: #selector(resendTapped))
        resendLabel.addGestureRecognizer(resendTap)
        resendLabel.isUserInteractionEnabled = false

        startResendTimer()
        otpField1.becomeFirstResponder() // Focuses on otpField1 and brings up the keyboard when the screen appears
    }

    deinit {
        resendTimer?.invalidate()
    }
    
    func setupCard() {
        containerCard.layer.cornerRadius = 20
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.08
        containerCard.layer.shadowRadius = 10
        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)
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
            $0.layer.borderColor = UIColor.systemGray4.cgColor
            $0.layer.borderWidth = 1
        }
        textField.layer.borderColor = UIColor.systemBlue.cgColor
        textField.layer.borderWidth = 2
    }

    private func updateVerifyButtonState() {
        let code = otpFields().map { $0.text ?? "" }.joined()
        let ready = code.count == 6
        verifyButton.isEnabled = ready
        verifyButton.alpha = ready ? 1.0 : 0.5
    }

    @IBAction func verifyTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let code = otpFields().map { $0.text ?? "" }.joined()

        guard code.count == 6 else {
            errorLabel.text = "Please enter the full OTP"
            errorLabel.isHidden = false
            return
        }

        do {
            switch verificationMode {
            case .email:
                let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                guard !email.isEmpty else {
                    errorLabel.text = "OTP session expired. Please request OTP again."
                    errorLabel.isHidden = false
                    return
                }

                let user = try UserDataModel.shared.verifyEmailOTP(email: email, code: code)

                if !UserDataModel.shared.isProfileSetupComplete(for: user) {
                    let roleStoryboard = UIStoryboard(name: "RoleSelection", bundle: nil)
                    let vc = roleStoryboard.instantiateViewController(withIdentifier: "RoleSelectionViewController")
                    navigationController?.pushViewController(vc, animated: true)
                } else {
                    goToTabBar()
                }
            case .phone:
                let phone = (phoneNumber ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !phone.isEmpty else {
                    errorLabel.text = "Phone verification session expired. Go back and retry."
                    errorLabel.isHidden = false
                    return
                }
                try UserDataModel.shared.verifyPhoneOTP(phone: phone, code: code)
                
                if let user = UserDataModel.shared.getCurrentUser(), UserDataModel.shared.isProfileSetupComplete(for: user) {
                    goToTabBar()
                } else {
                    let vc = storyboard!.instantiateViewController(withIdentifier: "ProfileStep2ViewController")
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        } catch {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
        }

    }

    private func startResendTimer() {
        seconds = 30
        resendLabel.text = "Resend OTP in \(seconds)s"
        resendLabel.isUserInteractionEnabled = false
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in // prevents retain cycle between Timer and ViewController
            guard let self = self else { return }
            self.seconds -= 1
            if self.seconds <= 0 {
                self.resendTimer?.invalidate()
                self.resendLabel.text = "Resend OTP"
                self.resendLabel.isUserInteractionEnabled = true
            } else {
                self.resendLabel.text = "Resend OTP in \(self.seconds)s"
            }
        }
    }

    @objc private func resendTapped() {
        guard seconds <= 0 else { return }

        do {
            switch verificationMode {
            case .email:
                let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                guard !email.isEmpty else {
                    errorLabel.text = "Email missing. Go back and request OTP again."
                    errorLabel.isHidden = false
                    return
                }
                try UserDataModel.shared.startEmailVerification(email: email)
            case .phone:
                let phone = (phoneNumber ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !phone.isEmpty else {
                    errorLabel.text = "Phone missing. Go back and retry."
                    errorLabel.isHidden = false
                    return
                }
                try UserDataModel.shared.startPhoneVerification(phone: phone)
            }
            clearOTPFields()
            errorLabel.isHidden = true
            startResendTimer()
            otpFields().first?.becomeFirstResponder()
        } catch {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
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
        stack.spacing = 8
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
            tf.layer.cornerRadius = 12
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor.systemGray4.cgColor
            tf.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.6)
            tf.delegate = self
            tf.heightAnchor.constraint(equalToConstant: 56).isActive = true
            tf.widthAnchor.constraint(equalToConstant: 44).isActive = true
            dynamicOTPFields.append(tf)
            stack.addArrangedSubview(tf)
        }
    }

    private func configureSubtitle() {
        switch verificationMode {
        case .email:
            titleLabel.text = "Verify your email"
            let email = (UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? "").lowercased()
            subtitleLabel?.text = "Enter the 6-digit code we sent to\n\(maskedEmail(email))"
        case .phone:
            titleLabel.text = "Verify Phone"
            let phone = phoneNumber ?? ""
            subtitleLabel?.text = "Enter the 6-digit code we sent to\n\(maskedPhone(phone))"
        }
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
        let tabBar = storyboard?.instantiateViewController(identifier: "MainTabBarController") as! UITabBarController
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
            
            // Optional transition animation
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
}
