import UIKit

let departmentOptions = [
    "CSE", "ECE", "Mechanical", "Civil",
    "Electrical", "Chemical Engineering",
    "Arts", "BCA", "BBA", "MBA", "MCA"
]

final class ProfileStep1ViewController: UIViewController, UITextFieldDelegate {
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

    private var activeRole: UserRole {
        if let lockedRole { return lockedRole }
        if let builderRole = RegistrationBuilder.shared.role { return builderRole }
        if let saved = UserDataModel.shared.getCurrentUser()?.role { return saved }
        return .student
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tell us about yourself"
        applyOnboardingChrome(step: 4, total: 7)
        removeOnboardingLogoIfPresent()

        setupUI()
        setupDepartmentDropDownMenu()
        setupYearDropDownMenu()
        updateFormForRole()
        preloadSavedState()
        validateContinueAvailability()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([headerTitleLabel, headerSubtitleLabel, containerCard, continueButton])
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
        containerCard.applyCardStyle()

        fullNameTextField.applyRoundedField()
        phoneTextField.keyboardType = .numberPad
        phoneTextField.applyRoundedField()

        otpTextField.keyboardType = .numberPad
        otpTextField.applyRoundedField()

        sendOTPButton.applyOutlineButton()
        dropDownButton.applyOutlineButton()
        yearDropDownButton.applyOutlineButton()
        continueButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(continueButton)

        continueButton.setPrimaryCTAEnabled(false)

        fullNameTextField.delegate = self
        phoneTextField.delegate = self
        fullNameTextField.addTarget(self, action: #selector(formDidChange), for: .editingChanged)
        phoneTextField.addTarget(self, action: #selector(formDidChange), for: .editingChanged)

        // OTP is handled by dedicated OTP screen.
        sendOTPButton.isHidden = true
        sendOTPButton.isEnabled = false
        otpTextField.isHidden = true
        otpTextField.alpha = 0
        otpTextField.isEnabled = false
        otpStatusLabel.isHidden = true
        otpStatusLabel.font = AppDesign.Typography.caption

        configureAccessibility()
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
    }

    @objc private func formDidChange() {
        phoneTextField.text = String((phoneTextField.text ?? "").filter(\.isNumber).prefix(10))
        validateContinueAvailability()
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == fullNameTextField {
            phoneTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == phoneTextField else { return true }
        let allowed = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowed.inverted) != nil { return false }
        let current = textField.text ?? ""
        guard let textRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: textRange, with: string)
        return updated.filter(\.isNumber).count <= 10
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
        let phone = (phoneTextField.text ?? "").filter(\.isNumber)

        guard phone.count == 10 else {
            showOTPStatus("Phone number must be exactly 10 digits", color: AppDesign.Color.destructive)
            phoneTextField.becomeFirstResponder()
            return
        }

        let role = activeRole
        let yearText = yearDropDownButton.title(for: .normal)
        let year = role == .student ? Int(yearText ?? "") : nil

        RegistrationBuilder.shared.fullName = fullNameTextField.text
        RegistrationBuilder.shared.role = role
        if role == .student {
            RegistrationBuilder.shared.courseName = dropDownButton.title(for: .normal)
            RegistrationBuilder.shared.year = year
        }
        RegistrationBuilder.shared.phone = phone

        let vc = storyboard?.instantiateViewController(withIdentifier: "ProfileStep2ViewController")
        if let vc { navigationController?.pushViewController(vc, animated: true) }
    }

    // MARK: - Helpers
    private func showOTPStatus(_ text: String, color: UIColor) {
        otpStatusLabel.text = text
        otpStatusLabel.textColor = color
        otpStatusLabel.isHidden = false
    }

    private func validateContinueAvailability() {
        let name = (fullNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let dept = dropDownButton.title(for: .normal) ?? ""
        let hasDepartment = dept != "Select Department" && dept != "Select Course"
        let hasValidPhone = (phoneTextField.text ?? "").filter(\.isNumber).count == 10

        if activeRole == .student {
            let hasYear = Int(yearDropDownButton.title(for: .normal) ?? "") != nil
            let enabled = !name.isEmpty && hasDepartment && hasYear && hasValidPhone
            continueButton.setPrimaryCTAEnabled(enabled)
            return
        }

        let enabled = !name.isEmpty && hasDepartment && hasValidPhone
        continueButton.setPrimaryCTAEnabled(enabled)
    }

    private func preloadSavedState() {
        // First try the builder, if rebuilding during onboarding steps
        if let name = RegistrationBuilder.shared.fullName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fullNameTextField.text = name
        }
        if let phone = RegistrationBuilder.shared.phone, !phone.isEmpty {
            phoneTextField.text = phone
        }

        if activeRole == .student {
            if let department = RegistrationBuilder.shared.courseName,
               !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                dropDownButton.setTitle(department, for: .normal)
            }
            if let year = RegistrationBuilder.shared.year {
                yearDropDownButton.setTitle("\(year)", for: .normal)
            }
        }
        
        // Next check existing user data
        if let user = UserDataModel.shared.getCurrentUser() {
            if fullNameTextField.text?.isEmpty ?? true, !(user.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                fullNameTextField.text = user.fullName
            }
            if phoneTextField.text?.isEmpty ?? true, let phone = user.phone, !phone.isEmpty {
                phoneTextField.text = phone
            }

            if activeRole == .student {
                if dropDownButton.title(for: .normal) == "Select Department" || dropDownButton.title(for: .normal) == "Select Course" {
                    if let department = user.courseName, !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        dropDownButton.setTitle(department, for: .normal)
                    }
                }
                if yearDropDownButton.title(for: .normal) == "Select year" {
                    if let year = user.year {
                        yearDropDownButton.setTitle("\(year)", for: .normal)
                    }
                }
            }
        }
    }

    private func configureAccessibility() {
        fullNameTextField.accessibilityLabel = "Full name"
        dropDownButton.accessibilityLabel = "Course or department"
        dropDownButton.accessibilityHint = "Select your course or department"
        yearDropDownButton.accessibilityLabel = "Year"
        yearDropDownButton.accessibilityHint = "Select your academic year"
        phoneTextField.accessibilityLabel = "Phone number"
        phoneTextField.accessibilityHint = "Enter your 10 digit mobile number"
        continueButton.accessibilityLabel = "Continue"
        continueButton.accessibilityHint = "Proceed to the next step"
    }
}
