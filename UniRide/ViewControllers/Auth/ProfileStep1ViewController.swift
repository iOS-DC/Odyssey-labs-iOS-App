import UIKit

let departmentOptions = [
    "CSE", "ECE", "Mechanical", "Civil",
    "Electrical", "Chemical Engineering",
    "Arts", "BCA", "BBA", "MBA", "MCA"
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
    @IBOutlet private weak var headerTitleLabel: UILabel!
    @IBOutlet private weak var headerSubtitleLabel: UILabel!
    
    @IBOutlet weak var courseLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!

    // Set by RoleSelectionViewController
    var lockedRole: UserRole?

    private let employeeIDTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Employee ID"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return tf
    }()

    private var activeRole: UserRole {
        if let lockedRole { return lockedRole }
        if let saved = UserDataModel.shared.getCurrentUser()?.role { return saved }
        return .student
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tell us about yourself"
        applyOnboardingChrome(step: 4, total: 7)

        setupUI()
        setupDepartmentDropDownMenu()
        setupYearDropDownMenu()
        updateFormForRole()
        preloadSavedState()
        validateContinueAvailability()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerCard.layer.shadowPath = UIBezierPath(
            roundedRect: containerCard.bounds,
            cornerRadius: containerCard.layer.cornerRadius
        ).cgPath
    }

    // MARK: - UI Setup
    private func setupUI() {
        containerCard.layer.masksToBounds = false
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.1
        containerCard.layer.shadowRadius = 8
        containerCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        fullNameTextField.applyRoundedField()
        phoneTextField.keyboardType = .numberPad
        phoneTextField.applyRoundedField()
        employeeIDTextField.applyRoundedField()

        otpTextField.keyboardType = .numberPad
        otpTextField.applyRoundedField()

        sendOTPButton.applyOutlineButton()
        continueButton.applyPrimaryButton(color: .systemBlue)
        applyPrimaryOnboardingCTAStyle(continueButton)

        continueButton.isEnabled = false
        continueButton.alpha = 0.5

        fullNameTextField.addTarget(self, action: #selector(formDidChange), for: .editingChanged)
        phoneTextField.addTarget(self, action: #selector(formDidChange), for: .editingChanged)

        // OTP is handled by dedicated OTP screen.
        sendOTPButton.isHidden = true
        sendOTPButton.isEnabled = false
        otpTextField.isHidden = true
        otpTextField.alpha = 0
        otpTextField.isEnabled = false
        otpStatusLabel.isHidden = true
        otpStatusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        if !stackView.arrangedSubviews.contains(employeeIDTextField),
           let phoneIndex = stackView.arrangedSubviews.firstIndex(of: phoneTextField) {
            stackView.insertArrangedSubview(employeeIDTextField, at: phoneIndex)
        }
        employeeIDTextField.addTarget(self, action: #selector(formDidChange), for: .editingChanged)
    }

    private func updateFormForRole() {
        let isStudent = activeRole == .student
        headerTitleLabel.text = "Tell us about yourself"
        headerSubtitleLabel.text = isStudent
            ? "Help us create your student profile"
            : "Help us create your faculty profile"

        courseLabel.text = isStudent ? "Course" : "Department"
        dropDownButton.setTitle(isStudent ? "Select Course" : "Select Department", for: .normal)
        
        yearLabel.isHidden = !isStudent
        yearDropDownButton.isHidden = !isStudent
        employeeIDTextField.isHidden = true // Hidden for both student and faculty
    }

    @objc private func formDidChange() {
        validateContinueAvailability()
    }

    // MARK: - Department Dropdown
    private func setupDepartmentDropDownMenu() {
        let options = departmentOptions.sorted() + ["Reset"]

        dropDownButton.menu = UIMenu(
            title: "Select department",
            children: options.map { option in
                UIAction(title: option) { [weak self] _ in
                    guard let self else { return }
                    if option == "Reset" {
                        self.dropDownButton.setTitle("Select Department", for: .normal)
                    } else {
                        self.dropDownButton.setTitle(option, for: .normal)
                    }
                    self.validateContinueAvailability()
                }
            }
        )
        dropDownButton.showsMenuAsPrimaryAction = true
    }

    private func setupYearDropDownMenu() {
        let years = [1, 2, 3, 4]
        yearDropDownButton.menu = UIMenu(
            title: "Select year",
            children: years.map { year in
                UIAction(title: "\(year)") { [weak self] _ in
                    self?.yearDropDownButton.setTitle("\(year)", for: .normal)
                    self?.validateContinueAvailability()
                }
            }
        )
        yearDropDownButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - OTP (legacy hidden on this screen)
    @IBAction func sendOTPPressed(_ sender: UIButton) {
        // intentionally unused: phone verification is handled on dedicated OTP screen
    }

    // MARK: - Continue
    @IBAction func continuePressed(_ sender: UIButton) {
        let phone = (phoneTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count >= 10 else {
            showOTPStatus("Enter a valid phone number", color: .systemRed)
            return
        }

        let role = activeRole
        let yearText = yearDropDownButton.title(for: .normal)
        let year = role == .student ? Int(yearText ?? "") : nil

        UserDataModel.shared.editCurrentUser(
            fullName: fullNameTextField.text,
            role: role,
            courseName: role == .student ? dropDownButton.title(for: .normal) : nil,
            year: year,
            employeeID: role == .faculty ? employeeIDTextField.text : nil
        )

        do {
            try UserDataModel.shared.startPhoneVerification(phone: phone)
            showOTPStatus("OTP sent. Verify phone on next step.", color: .systemGreen)

            let vc = storyboard?.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
            vc.verificationMode = .phone
            vc.phoneNumber = phone
            navigationController?.pushViewController(vc, animated: true)
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

    private func validateContinueAvailability() {
        let name = (fullNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = (phoneTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPhone = phone.count >= 10
        let dept = dropDownButton.title(for: .normal) ?? ""
        let hasDepartment = dept != "Select Department" && dept != "Select Course"

        if activeRole == .student {
            let hasYear = Int(yearDropDownButton.title(for: .normal) ?? "") != nil
            let enabled = !name.isEmpty && hasDepartment && hasYear && hasPhone
            continueButton.isEnabled = enabled
            continueButton.alpha = enabled ? 1.0 : 0.5
            return
        }

        let enabled = !name.isEmpty && hasDepartment && hasPhone
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.5
    }

    private func preloadSavedState() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }

        if !(user.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            fullNameTextField.text = user.fullName
        }
        if let phone = user.phone, !phone.isEmpty {
            phoneTextField.text = phone
        }

        if activeRole == .student {
            if let department = user.courseName,
               !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                dropDownButton.setTitle(department, for: .normal)
            }
            if let year = user.year {
                yearDropDownButton.setTitle("\(year)", for: .normal)
            }
        } else if let eid = user.employeeID, !eid.isEmpty {
            employeeIDTextField.text = eid
        }
    }
}
