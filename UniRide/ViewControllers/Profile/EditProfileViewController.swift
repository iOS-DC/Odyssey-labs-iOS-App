import UIKit

class EditProfileViewController: UIViewController,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate,
                                  UITextFieldDelegate {

    // MARK: - State
    private var newPhotoURL: URL? = nil
    private var isSaving = false

    // MARK: - UI
    private let scrollView       = UIScrollView()
    private let contentStack     = UIStackView()

    private let avatarImageView  = UIImageView()
    private let cameraBadge      = UIView()

    private let nameField        = UITextField()
    private let yearField        = UITextField()
    private let emailField       = UITextField()
    private let phoneField       = UITextField()

    // Saved reference to the save button so we can toggle its loading state
    private weak var saveButton: UIButton?

    // outlets needed by @IBAction stubs
    @IBOutlet weak var cardBackgroundView: UIView?
    @IBOutlet weak var profileImageView: UIImageView?
    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var yearTextField: UITextField?
    @IBOutlet weak var mailTextField: UITextField?
    @IBOutlet weak var phoneTextField: UITextField?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        buildLayout()
        loadExistingData()

        let bgTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        bgTap.cancelsTouchesInView = false
        view.addGestureRecognizer(bgTap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard Avoidance

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        let bottom = view.bounds.height - frame.minY
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = bottom
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) else { return }
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    // MARK: - Build layout
    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = AppDesign.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.lg),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl - AppDesign.Spacing.xs),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.xl * 2),
        ])

        contentStack.addArrangedSubview(buildProfileCard())
    }

    // MARK: - Profile Card
    private func buildProfileCard() -> UIView {
        let card = makeCard()

        // ── Avatar ───────────────────────────────────────────────────────────
        avatarImageView.contentMode   = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = AppDesign.Color.borderSubtle
        avatarImageView.layer.cornerRadius = 55        // half of 110 — always circular
        avatarImageView.layer.borderWidth  = 3
        avatarImageView.layer.borderColor  = AppDesign.Color.primary.withAlphaComponent(0.7).cgColor
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImageTapped))
        avatarImageView.addGestureRecognizer(tap)

        // ── Camera badge (positioned relative to the avatar) ─────────────────
        cameraBadge.backgroundColor    = AppDesign.Color.primary
        cameraBadge.layer.cornerRadius = 16
        cameraBadge.layer.borderWidth  = 2.5
        cameraBadge.layer.borderColor  = UIColor.systemBackground.cgColor
        cameraBadge.layer.shadowColor   = UIColor.black.cgColor
        cameraBadge.layer.shadowOpacity = 0.2
        cameraBadge.layer.shadowRadius  = 4
        cameraBadge.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cameraBadge.translatesAutoresizingMaskIntoConstraints = false
        cameraBadge.isUserInteractionEnabled = false

        let camIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        camIcon.tintColor   = .white
        camIcon.contentMode = .scaleAspectFit
        camIcon.translatesAutoresizingMaskIntoConstraints = false
        cameraBadge.addSubview(camIcon)
        NSLayoutConstraint.activate([
            camIcon.centerXAnchor.constraint(equalTo: cameraBadge.centerXAnchor),
            camIcon.centerYAnchor.constraint(equalTo: cameraBadge.centerYAnchor),
            camIcon.widthAnchor.constraint(equalToConstant: 14),
            camIcon.heightAnchor.constraint(equalToConstant: 14),
        ])

        // ── Container that holds avatar + badge ──────────────────────────────
        // Must have explicit size so the layout engine doesn't collapse it.
        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.widthAnchor.constraint(equalToConstant: 110).isActive  = true
        avatarContainer.heightAnchor.constraint(equalToConstant: 110).isActive = true
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraBadge)
        NSLayoutConstraint.activate([
            // Avatar fills container
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            // Badge sits at bottom-right corner of avatar
            cameraBadge.widthAnchor.constraint(equalToConstant: 32),
            cameraBadge.heightAnchor.constraint(equalToConstant: 32),
            cameraBadge.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 4),
            cameraBadge.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 4),
        ])

        // ── Center the container in a full-width wrapper for the stack ────────
        let avatarWrapper = UIView()           // full-width row that centers the 110pt square
        avatarWrapper.translatesAutoresizingMaskIntoConstraints = false
        avatarWrapper.addSubview(avatarContainer)
        NSLayoutConstraint.activate([
            avatarContainer.centerXAnchor.constraint(equalTo: avatarWrapper.centerXAnchor),
            avatarContainer.topAnchor.constraint(equalTo: avatarWrapper.topAnchor),
            avatarContainer.bottomAnchor.constraint(equalTo: avatarWrapper.bottomAnchor),
        ])

        // ── Fields ────────────────────────────────────────────────────────────
        setupField(nameField,  placeholder: "Full Name",     icon: "person.fill",   keyboardType: .default)
        setupField(yearField,  placeholder: "Year (e.g. 2)", icon: "calendar",      keyboardType: .numberPad)
        setupField(emailField, placeholder: "College Email", icon: "envelope.fill", keyboardType: .emailAddress)
        setupField(phoneField, placeholder: "Phone Number",  icon: "phone.fill",    keyboardType: .phonePad)

        // ── Save Button ───────────────────────────────────────────────────────
        let saveButton  = UIButton(type: .system)
        var saveCfg     = UIButton.Configuration.filled()
        saveCfg.title   = "Save Changes"
        saveCfg.image   = UIImage(systemName: "checkmark.circle.fill")
        saveCfg.imagePlacement  = .leading
        saveCfg.imagePadding    = 8
        saveCfg.baseBackgroundColor = AppDesign.Color.primary
        saveCfg.baseForegroundColor = .white
        saveCfg.cornerStyle = .capsule
        saveCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var at = a
            at.font = AppDesign.Typography.action
            return at
        }
        saveButton.configuration = saveCfg
        saveButton.applyPrimaryButton(color: AppDesign.Color.primary)
        saveButton.addTarget(self, action: #selector(saveButtonTapped(_:)), for: .touchUpInside)
        // Keep a weak reference so loading state can be toggled from beginSaving/endSaving
        self.saveButton = saveButton

        // ── Inner stack: avatar → separator → fields → save ───
        let inner = UIStackView(arrangedSubviews: [
            avatarWrapper,
            makeSeparator(),
            nameField, yearField, emailField, phoneField,
            saveButton,
        ])
        inner.axis    = .vertical
        inner.spacing = 14
        inner.setCustomSpacing(20, after: avatarWrapper)     // more breathing room after avatar

        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
        ])
        return card
    }


    // MARK: - Helpers
    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor    = .systemBackground
        card.applyCardStyle()
        return card
    }

    private func setupField(_ field: UITextField, placeholder: String, icon: String, keyboardType: UIKeyboardType) {
        field.borderStyle     = .none
        field.applyRoundedField()
        field.font            = AppDesign.Typography.subheadline
        field.keyboardType    = keyboardType
        field.delegate        = self
        field.autocorrectionType = .no
        field.autocapitalizationType = keyboardType == .default ? .words : .none
        field.attributedPlaceholder = NSAttributedString(string: placeholder,
            attributes: [.foregroundColor: UIColor.tertiaryLabel])

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor    = AppDesign.Color.primary
        iconView.contentMode  = .scaleAspectFit
        iconView.frame        = CGRect(x: 12, y: 0, width: 20, height: 20)
        let leftContainer     = UIView(frame: CGRect(x: 0, y: 0, width: 42, height: 52))
        iconView.center       = CGPoint(x: 21, y: 26)
        leftContainer.addSubview(iconView)
        field.leftView        = leftContainer
        field.leftViewMode    = .always

        let rightPad          = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 52))
        field.rightView       = rightPad
        field.rightViewMode   = .always
        if field == emailField {
            field.isEnabled = false
            field.textColor = .secondaryLabel
            iconView.tintColor = .secondaryLabel
        }

        if field == phoneField {
            field.addTarget(self, action: #selector(phoneFieldDidChange), for: .editingChanged)
        }
    }

    @objc private func phoneFieldDidChange() {
        phoneField.text = String((phoneField.text ?? "").filter(\.isNumber).prefix(10))
    }

    private func centeredView(_ child: UIView) -> UIView {
        let wrapper = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(child)
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            child.topAnchor.constraint(equalTo: wrapper.topAnchor),
            child.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = AppDesign.Color.border
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }

    // MARK: - Load Data
    private func loadExistingData() {
        guard let user = UserDataModel.shared.getCurrentUser() else { return }
        nameField.text  = user.fullName
        emailField.text = user.email
        phoneField.text = user.phone
        yearField.text  = user.year.map { "\($0)" }

        // Non-blocking avatar load using the shared helper
        // Force layout so bounds are known before calling loadAndFallback
        avatarImageView.layoutIfNeeded()
        avatarImageView.loadAndFallback(from: user.photoURL, name: user.fullName.isEmpty ? "?" : user.fullName)
        avatarImageView.contentMode = user.photoURL != nil ? .scaleAspectFill : .scaleAspectFit
    }

    // MARK: - Actions
    @objc private func selectImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate    = self
        picker.sourceType  = .photoLibrary
        picker.allowsEditing = true
        presentPopover(picker, from: avatarImageView)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @IBAction func saveButtonTapped(_ sender: Any) {
        guard !isSaving else { return }
        guard var user = UserDataModel.shared.getCurrentUser() else { return }

        // Collect & validate fields
        let newName  = (nameField.text  ?? "").trimmingCharacters(in: .whitespaces)
        let newEmail = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        let newPhone = (phoneField.text ?? "").trimmingCharacters(in: .whitespaces)
        let newYear  = yearField.text.flatMap { Int($0) }

        guard !newName.isEmpty else {
            showAlert(title: "Name Required", message: "Please enter your full name.")
            return
        }

        guard newPhone.count == 10, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: newPhone)) else {
            showAlert(title: "Invalid Phone Number", message: "Phone number must be exactly 10 digits.")
            return
        }

        user.fullName = newName
        user.email    = newEmail.isEmpty ? user.email : newEmail
        user.phone    = newPhone.isEmpty ? user.phone : newPhone
        if let yr = newYear { user.year = yr }

        beginSaving()

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.endSaving() }

            // 1. Upload avatar if a new photo was picked
            if let photoURL = self.newPhotoURL,
               let imageData = try? Data(contentsOf: photoURL) {
                do {
                    let remoteURLStr = try await ProfileRepository.shared.uploadAvatar(
                        userID: user.id, imageData: imageData)
                    user.photoURL = URL(string: remoteURLStr)
                } catch {
                    self.showAlert(title: "Photo Upload Failed",
                                   message: error.localizedDescription + "\n\nOther changes were still saved.")
                }
            }

            // 2. Persist text-field changes locally first
            UserDataModel.shared.saveUserProfile(user)

            // 3. Sync to Supabase (best-effort, won't block navigation)
            var remoteFields: [String: Any] = [
                "id":        user.id.uuidString,
                "full_name": user.fullName,
                "email":     user.email,
            ]
            if let phone = user.phone    { remoteFields["phone"] = phone }
            if let year  = user.year     { remoteFields["year"]  = year }
            if let urlStr = user.photoURL?.absoluteString { remoteFields["photo_url"] = urlStr }

            do {
                try await ProfileRepository.shared.upsertProfile(remoteFields)
            } catch {
                // Non-fatal — local save already succeeded
                print("[EditProfile] Remote sync failed:", error.localizedDescription)
            }

            AppHaptics.success()
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Image Picker
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let img {
            avatarImageView.image       = img
            avatarImageView.contentMode = .scaleAspectFill
            newPhotoURL = saveImageToDocuments(img)
        }
        dismiss(animated: true)
    }

    private func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_\(UUID().uuidString).jpg")
        try? data.write(to: url)
        return url
    }

    // MARK: - Loading State

    private func beginSaving() {
        isSaving = true
        var cfg = saveButton?.configuration
        cfg?.showsActivityIndicator = true
        cfg?.title = "Saving…"
        saveButton?.configuration = cfg
        saveButton?.isEnabled = false
    }

    private func endSaving() {
        isSaving = false
        var cfg = saveButton?.configuration
        cfg?.showsActivityIndicator = false
        cfg?.title = "Save Changes"
        saveButton?.configuration = cfg
        saveButton?.isEnabled = true
    }

    // MARK: - Alert Helper

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == phoneField else { return true }
        let allowed = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowed.inverted) != nil { return false }
        let current = textField.text ?? ""
        guard let textRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: textRange, with: string)
        return updated.count <= 10
    }
}
