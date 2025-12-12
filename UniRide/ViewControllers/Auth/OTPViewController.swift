//
//  OTPViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 11/11/25.
//


import UIKit

final class OTPViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var otpField1: UITextField!
    @IBOutlet weak var otpField2: UITextField!
    @IBOutlet weak var otpField3: UITextField!
    @IBOutlet weak var otpField4: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var resendLabel: UILabel!

    @IBOutlet weak var containerCard: UIView!
    private var resendTimer: Timer?
    private var seconds = 30
    private var currentEmail: String? {
        return nil // we’ll request it from last OTP map key in a moment (see below).
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Enter OTP"
        errorLabel.isHidden = true
        verifyButton.layer.cornerRadius = 12
        setupCard();
        [otpField1, otpField2, otpField3, otpField4].forEach {
            $0?.delegate = self
            $0?.keyboardType = .numberPad
            $0?.textAlignment = .center
            $0?.layer.cornerRadius = 12
        }

        startResendTimer()
        otpField1.becomeFirstResponder() // Focuses on otpField1 and brings up the keyboard when the screen appears
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
        // Only 1 char per box
        if s.count > 1 { return false }
        textField.text = s

        switch textField {
        case otpField1: otpField2.becomeFirstResponder()
        case otpField2: otpField3.becomeFirstResponder()
        case otpField3: otpField4.becomeFirstResponder()
        case otpField4: otpField4.resignFirstResponder()
        default: break
        }
        return false
    }

    @IBAction func verifyTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let code = (otpField1.text ?? "") + (otpField2.text ?? "") + (otpField3.text ?? "") + (otpField4.text ?? "")

        guard code.count == 6 || code.count == 4 else {
            errorLabel.text = "Please enter the full OTP"
            errorLabel.isHidden = false
            return
        }

        let email = UserDefaults.standard.string(forKey: "lastEmailForOTP") ?? ""

        do {
            let user = try UserDataModel.shared.verifyEmailOTP(email: email, code: code)

            if user.fullName.isEmpty {
                // New or incomplete profile Proceed to profile setup
                let vc = storyboard!.instantiateViewController(withIdentifier: "ProfileStep1ViewController")
                navigationController?.pushViewController(vc, animated: true)
            } else {
                // If Existing user Go directly to Home
                let homeVC = storyboard!.instantiateViewController(withIdentifier: "MainTabBarController")
                homeVC.modalPresentationStyle = .fullScreen
                self.present(homeVC, animated: true)
            }

        } catch {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
        }

    }

    private func startResendTimer() {
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
}
