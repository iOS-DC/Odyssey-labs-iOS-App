


import UIKit

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

            containerCard.applyCardStyle()
            emailTextField.applyRoundedField()
            
    }
    @IBOutlet weak var containerCard: UIView!
    
    
    @IBAction func continueTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let raw = emailTextField.text ?? ""
        
        do {
            try UserDataModel.shared.startEmailVerification(email: raw)
            
            // Storing email for OTP screen
            UserDefaults.standard.set(raw, forKey: "lastEmailForOTP")


            let otpVC = storyboard!.instantiateViewController(withIdentifier: "OTPViewController")
     
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
