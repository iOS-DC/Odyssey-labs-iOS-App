import UIKit

let courseDurations: [String: Int] = [
    "CSE": 4, "ECE": 4, "Mechanical": 4, "Civil": 4,
    "Electrical": 4, "Chemical Engineering": 4,
    "Arts": 3, "BCA": 3, "BBA": 3, "MBA": 2, "MCA": 2
]

final class ProfileStep1ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var containerCard: UIView!
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var dropDownButton: UIButton!
    @IBOutlet weak var yearDropDownButton: UIButton!

    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var sendOTPButton: UIButton!

    @IBOutlet weak var otpStatusLabel: UILabel!
    @IBOutlet weak var otpTextField: UITextField!

    @IBOutlet weak var continueButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCourseDropDownMenu()
        setupYearDropDownMenu()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update shadow path after layout so it matches the card's bounds
        containerCard.layer.shadowPath = UIBezierPath(
            roundedRect: containerCard.bounds,
            cornerRadius: containerCard.layer.cornerRadius
        ).cgPath
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Card shadow (cornerRadius is set in storyboard)
        containerCard.layer.masksToBounds = false
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.1
        containerCard.layer.shadowRadius = 8
        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        // TextFields (cornerRadius + border set in storyboard)
        fullNameTextField.setLeftPaddingPoints(14)
        phoneTextField.keyboardType = .numberPad

        otpTextField.keyboardType = .numberPad
        otpTextField.setLeftPaddingPoints(14)

        // Buttons
        sendOTPButton.applyOutlineButton()
        continueButton.applyOutlineButton()

        // Continue button starts disabled
        continueButton.isEnabled = false
        continueButton.alpha = 0.5

        // OTP section hidden initially
        otpTextField.isHidden = true
        otpTextField.alpha = 0
        otpStatusLabel.isHidden = true
        otpStatusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        // Stack spacing
        stackView.setCustomSpacing(6, after: otpStatusLabel)
        stackView.setCustomSpacing(12, after: otpTextField)
    }

    // MARK: - Course Dropdown
    private func setupCourseDropDownMenu() {
        let options = Array(courseDurations.keys).sorted() + ["Reset"]

        dropDownButton.menu = UIMenu(
            title: "Select your course",
            children: options.map { option in
                UIAction(title: option) { [weak self] _ in
                    guard let self else { return }
                    if option == "Reset" {
                        self.dropDownButton.setTitle("Select Course", for: .normal)
                        self.setupYearDropDownMenu()
                        return
                    }
                    self.dropDownButton.setTitle(option, for: .normal)
                    if let duration = courseDurations[option] {
                        self.setupYearDropDownMenu(defaultYears: Array(1...duration))
                    }
                }
            }
        )
        dropDownButton.showsMenuAsPrimaryAction = true
    }

    private func setupYearDropDownMenu(defaultYears: [Int] = [1, 2, 3, 4]) {
        yearDropDownButton.menu = UIMenu(
            title: "Select year",
            children: defaultYears.map { year in
                UIAction(title: "\(year)") { [weak self] _ in
                    self?.yearDropDownButton.setTitle("\(year)", for: .normal)
                }
            }
        )
        yearDropDownButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - OTP
    @IBAction func sendOTPPressed(_ sender: UIButton) {
        guard let phone = phoneTextField.text, phone.count >= 10 else {
            showOTPStatus("Enter a valid phone number", color: .systemRed)
            return
        }

        do {
            try UserDataModel.shared.startPhoneVerification(phone: phone)
            showOTPStatus("✓ OTP sent", color: .systemGreen)

            otpTextField.text = ""
            otpTextField.isHidden = false
            UIView.animate(withDuration: 0.35) { self.otpTextField.alpha = 1 }
            otpTextField.becomeFirstResponder()

            continueButton.isEnabled = true
            continueButton.alpha = 1
        } catch {
            showOTPStatus(error.localizedDescription, color: .systemRed)
        }
    }

    // MARK: - Continue
    @IBAction func continuePressed(_ sender: UIButton) {
        guard let phone = phoneTextField.text, phone.count >= 10 else {
            showOTPStatus("Enter a valid phone number", color: .systemRed)
            return
        }
        guard let otp = otpTextField.text, !otp.isEmpty else {
            showOTPStatus("Please enter OTP", color: .systemRed)
            return
        }

        do {
            try UserDataModel.shared.verifyPhoneOTP(phone: phone, code: otp)
            showOTPStatus("✓ Phone number verified", color: .systemGreen)

            UserDataModel.shared.editCurrentUser(
                fullName: fullNameTextField.text,
                courseName: dropDownButton.title(for: .normal),
                year: Int(yearDropDownButton.title(for: .normal) ?? "1")
            )
            goToNextPage()
        } catch {
            showOTPStatus(error.localizedDescription, color: .systemRed)
        }
    }

    // MARK: - Helpers
    private func showOTPStatus(_ text: String, color: UIColor) {
        otpStatusLabel.text = text
        otpStatusLabel.textColor = color
        otpStatusLabel.isHidden = false
    }

    private func goToNextPage() {
        let vc = storyboard?.instantiateViewController(
            identifier: "ProfileStep2ViewController"
        ) as! ProfileStep2ViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
