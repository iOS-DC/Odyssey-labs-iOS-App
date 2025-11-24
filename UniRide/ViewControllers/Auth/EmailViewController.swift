//
//  EmailViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 14/11/25.
//



import UIKit

final class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupCard()
        setupTextField()
        setupButton()
    }
    @IBOutlet weak var containerCard: UIView!
    
    func setupCard() {
        containerCard.layer.cornerRadius = 20
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.08
        containerCard.layer.shadowRadius = 10
        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
    
    
    func setupTextField() {
        emailTextField.backgroundColor = .white
        emailTextField.layer.cornerRadius = 12
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor(red:229/255, green:231/255, blue:235/255, alpha:1).cgColor
        
        emailTextField.setLeftPaddingPoints(12)
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter your college email",
            attributes: [.foregroundColor: UIColor.systemGray3]
        )
    }
    
    func setupButton() {
        continueButton.layer.cornerRadius = 26
        continueButton.backgroundColor = UIColor(red: 0/255, green: 197/255, blue: 142/255, alpha: 1)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
    }
    
    
    @IBAction func continueTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        let raw = emailTextField.text ?? ""
        
        do {
            try UserDataModel.shared.startEmailVerification(email: raw)
            
            // Save email for OTP screen
            UserDefaults.standard.set(raw, forKey: "lastEmailForOTP")
            
            // Create OTP VC
            let otpVC = storyboard!.instantiateViewController(withIdentifier: "OTPViewController")
            
            if let nav = navigationController {
                // If we are already in a navigation controller → push normally
                nav.pushViewController(otpVC, animated: true)
            } else {
                // If NOT inside a nav controller → present one modally
                let nav = UINavigationController(rootViewController: otpVC)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            }
            
        } catch {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
        }
    }
    
}


// MARK: - UITextField padding helper at file scope
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
