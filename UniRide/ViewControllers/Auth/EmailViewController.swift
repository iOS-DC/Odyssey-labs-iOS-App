


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
        continueButton.applyPrimaryButton(color: .systemBlue)
        applyPrimaryOnboardingCTAStyle(continueButton)
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
    }
    @IBOutlet weak var containerCard: UIView!
    
    @objc private func emailChanged() {
        let raw = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isValid = raw.hasSuffix("@chitkara.edu.in") || raw.hasSuffix("@chitkarauniversity.edu.in")
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.5
    }
    
    
    @IBAction func continueTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let raw = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try UserDataModel.shared.startEmailVerification(email: raw)
            
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

// UITextField padding helper at file scope
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
