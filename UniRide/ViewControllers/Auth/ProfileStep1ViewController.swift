//
//  ProfileStep1ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 16/11/25.
//

import UIKit

let courseDurations: [String: Int] = [
    "CSE": 4, "ECE": 4, "Mechanical": 4, "Civil": 4, "Electrical": 4,
    "Chemical Engineering": 4, "Arts": 3, "BCA": 3, "BBA": 3, "MBA": 2,"MCA": 2,
]

class ProfileStep1ViewController: UIViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet var containerCard: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var dropDownButton: UIButton! 

    @IBOutlet weak var otpStatusLabel: UILabel!
    
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var otpTextField: UITextField!
    @IBOutlet weak var sendOTPButton: UIButton!
    @IBOutlet weak var yearDropDownButton: UIButton!
    
    @IBOutlet weak var continueButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCourseDropDownMenu()
        setupYearDropDownMenu()
        
        containerCard.applyCardStyle()
        fullNameTextField.applyRoundedField()
        continueButton.applyPrimaryButton()
        ///The stackView does NOT automatically fix the spacing around it. SO we are telling the stackView That when these two textField is appearing set them closesly Otherwise the textfield was not appearing.
        stackView.setCustomSpacing(0, after: otpStatusLabel)
        stackView.setCustomSpacing(2, after: otpTextField)
    }
    
    func setupCourseDropDownMenu() {
        let options = Array(courseDurations.keys).sorted() + ["Reset"]

        let menuActions = options.map { option in
            return UIAction(title: option) { action in
                
                if action.title == "Reset" {
                    self.dropDownButton.setTitle("Select Course", for: .normal)
                    self.setupYearDropDownMenu(defaultYears: [1,2,3,4])
                    return
                }

                self.dropDownButton.setTitle(action.title, for: .normal)

                if let duration = courseDurations[action.title] {
                    let years = Array(1...duration)
                    self.setupYearDropDownMenu(defaultYears: years)
                }
            }
        }

        dropDownButton.menu = UIMenu(title: "Select your course", children: menuActions)
        dropDownButton.changesSelectionAsPrimaryAction = true
    }

        
    func setupYearDropDownMenu(defaultYears: [Int] = [1,2,3,4]) {
        
        let menuActions = defaultYears.map { year in
            return UIAction(title: "\(year)") { action in
                self.yearDropDownButton.setTitle(action.title, for: .normal)
            }
        }

        yearDropDownButton.menu = UIMenu(title: "Select your year", children: menuActions)
        yearDropDownButton.changesSelectionAsPrimaryAction = true
    }

    @IBAction func sendOTPPressed(_ sender: UIButton) {
        guard let phone = phoneTextField.text, !phone.isEmpty else {
               otpStatusLabel.text = "Enter phone number first"
               otpStatusLabel.textColor = .red
               otpStatusLabel.isHidden = false
               return
           }

           do {
               try UserDataModel.shared.startPhoneVerification(phone: phone)

               otpStatusLabel.text = "OTP sent! Check console"
               otpStatusLabel.textColor = .systemGreen
               otpStatusLabel.isHidden = false

               // Show OTP text field
               otpTextField.text = ""
               otpTextField.isHidden = false

               UIView.animate(withDuration: 0.3) {
                   self.view.layoutIfNeeded()
               }

           } catch {
               otpStatusLabel.text = error.localizedDescription
               otpStatusLabel.textColor = .red
               otpStatusLabel.isHidden = false
           }
       }
    
    @IBAction func continuePressed(_ sender: UIButton) {
           if !otpTextField.isHidden {
               guard let phone = phoneTextField.text, let otp = otpTextField.text, !otp.isEmpty else {
                   return
               }

               do {
                   // Verify phone for the EXISTING current user
                   try UserDataModel.shared.verifyPhoneOTP(phone: phone, code: otp)
                   print("Phone verified")

                   //  Update (edit) the same user with profile details
                   UserDataModel.shared.editCurrentUser(
                       fullName: fullNameTextField.text,
                       courseName: dropDownButton.title(for: .normal),
                       year: Int(yearDropDownButton.title(for: .normal) ?? "1")
                       
                   )

                   goToNextPage()

               } catch {
                   otpStatusLabel.text = error.localizedDescription
                   otpStatusLabel.textColor = .red
                   otpStatusLabel.isHidden = false
               }
               return
           }

           // If OTP field is hidden -> user never requested OTP
           otpStatusLabel.text = "Please verify your phone number first"
           otpStatusLabel.textColor = .red
           otpStatusLabel.isHidden = false
       }
    func goToNextPage() {
        let vc = storyboard?.instantiateViewController(identifier: "ProfileStep2ViewController") as! ProfileStep2ViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
