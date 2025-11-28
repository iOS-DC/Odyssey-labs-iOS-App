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
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.isHidden = true

        
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
        emailTextField.layer.cornerRadius = 14
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1).cgColor
        emailTextField.backgroundColor = UIColor(white: 0.97, alpha: 1)

        // Padding
        emailTextField.setLeftPaddingPoints(16)
    }

    
    func setupButton() {
        continueButton.layer.cornerRadius = 24
        continueButton.backgroundColor = UIColor(red: 0/255, green: 197/255, blue: 142/255, alpha: 1)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
    }
    
    
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
