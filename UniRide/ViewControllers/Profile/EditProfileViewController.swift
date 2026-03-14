import UIKit

class EditProfileViewController: UIViewController,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate {

    // MARK: - State
    private var newPhotoURL: URL? = nil
    private var isSaving = false

    // MARK: - UI
    private let scrollView       = UIScrollView()
    private let contentStack     = UIStackView()

    private let avatarImageView  = UIImageView()
    private let cameraBadge      = UIView()
    private let changePhotoBtn   = UIButton(type: .system)

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
        refreshVehicleCard()
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
        contentStack.addArrangedSubview(buildVehicleCard())
    }

    // MARK: - Profile Card
    private func buildProfileCard() -> UIView {
        let card = makeCard()

        // ── Avatar ───────────────────────────────────────────────────────────
        avatarImageView.contentMode   = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .systemGray5
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

        // ── Change Photo button ───────────────────────────────────────────────
        var photoCfg = UIButton.Configuration.plain()
        photoCfg.title = "Change Photo"
        photoCfg.baseForegroundColor = AppDesign.Color.primary
        changePhotoBtn.configuration = photoCfg
        changePhotoBtn.titleLabel?.font = AppDesign.Typography.subheadline
        changePhotoBtn.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)

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

        // ── Inner stack: avatar → Change Photo → separator → fields → save ───
        let inner = UIStackView(arrangedSubviews: [
            avatarWrapper,
            changePhotoBtn,
            makeSeparator(),
            nameField, yearField, emailField, phoneField,
            saveButton,
        ])
        inner.axis    = .vertical
        inner.spacing = 14
        inner.setCustomSpacing(8, after: avatarWrapper)     // small gap avatar → button
        inner.setCustomSpacing(20, after: changePhotoBtn)   // more breathing room after button

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


    // MARK: - Vehicle Card
    private var vehicleDetailsStack = UIStackView()
    private var vehicleCTABtn       = UIButton(type: .system)

    private func buildVehicleCard() -> UIView {
        let card = makeCard()

        // Header
        let iconBg = UIView()
        iconBg.backgroundColor    = AppDesign.Color.primary.withAlphaComponent(0.1)
        iconBg.layer.cornerRadius = AppDesign.Radius.sm
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 36).isActive  = true
        iconBg.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let carIcon = UIImageView(image: UIImage(systemName: "car.fill"))
        carIcon.tintColor    = AppDesign.Color.primary
        carIcon.contentMode  = .scaleAspectFit
        carIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(carIcon)
        NSLayoutConstraint.activate([
            carIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            carIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            carIcon.widthAnchor.constraint(equalToConstant: 20),
            carIcon.heightAnchor.constraint(equalToConstant: 20),
        ])

        let titleLbl    = UILabel()
        titleLbl.text   = "Vehicle Information"
        titleLbl.applyTextStyle(AppDesign.Typography.bodyStrong)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor   = AppDesign.Color.primary
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true

        let headerStack = UIStackView(arrangedSubviews: [iconBg, titleLbl, chevron])
        headerStack.axis = .horizontal; headerStack.spacing = 10; headerStack.alignment = .center

        // Details
        vehicleDetailsStack.axis    = .vertical
        vehicleDetailsStack.spacing = 12

        // CTA
        vehicleCTABtn.applyTextActionStyle()
        vehicleCTABtn.contentHorizontalAlignment = .leading
        vehicleCTABtn.addTarget(self, action: #selector(openVehicleDetails), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [
            headerStack, makeSeparator(), vehicleDetailsStack, vehicleCTABtn
        ])
        mainStack.axis = .vertical; mainStack.spacing = AppDesign.Spacing.sm + AppDesign.Spacing.xxs / 2
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(openVehicleDetails))
        card.addGestureRecognizer(tap)
        return card
    }

    private func refreshVehicleCard() {
        vehicleDetailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
 
        if let vehicles = UserDataModel.shared.getCurrentUser()?.vehicles, !vehicles.isEmpty {
            for v in vehicles {
                let name = v.alias ?? v.model
                let vehicleRow = buildVehicleRowForList(vehicle: v)
                vehicleDetailsStack.addArrangedSubview(vehicleRow)
                
                // Add a separator between vehicles if not the last one
                if v != vehicles.last {
                    vehicleDetailsStack.addArrangedSubview(makeSeparator())
                }
            }
            vehicleCTABtn.setTitle("Add Another Vehicle", for: .normal)
        } else {
            let empty = UILabel()
            empty.text      = "No vehicles added yet."
            empty.applyTextStyle(AppDesign.Typography.subheadline, color: .tertiaryLabel)
            vehicleDetailsStack.addArrangedSubview(empty)
            vehicleCTABtn.setTitle("Add Vehicle", for: .normal)
        }
    }
 
    private func buildVehicleRowForList(vehicle: Vehicle) -> UIView {
        let nameLbl = UILabel()
        nameLbl.text = vehicle.alias ?? vehicle.model
        nameLbl.applyTextStyle(AppDesign.Typography.bodyStrong)
        
        let subLbl = UILabel()
        subLbl.text = "\(vehicle.model) • \(vehicle.registrationNumber)"
        subLbl.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        
        let textStack = UIStackView(arrangedSubviews: [nameLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let icon = UIImageView(image: UIImage(systemName: vehicle.type == .car ? "car.fill" : "bicycle"))
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        let editIcon = UIImageView(image: UIImage(systemName: "pencil"))
        editIcon.tintColor = .tertiaryLabel
        editIcon.contentMode = .scaleAspectFit
        
        let row = UIStackView(arrangedSubviews: [icon, textStack, editIcon])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let tap = UIAction { [weak self] _ in
            let vc = VehicleRegistrationViewController()
            vc.vehicleToEdit = vehicle
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        let btn = UIButton(type: .system, primaryAction: tap)
        btn.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: row.topAnchor),
            btn.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        
        return row
    }

    private func vehicleRow(icon: String, label: String, value: String) -> UIView {
        let icn = UIImageView(image: UIImage(systemName: icon))
        icn.tintColor    = AppDesign.Color.primary
        icn.contentMode  = .scaleAspectFit
        icn.translatesAutoresizingMaskIntoConstraints = false
        icn.widthAnchor.constraint(equalToConstant: 18).isActive  = true
        icn.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let keyLbl = UILabel()
        keyLbl.text = label
        keyLbl.font = AppDesign.Typography.caption
        keyLbl.textColor = .secondaryLabel
        keyLbl.widthAnchor.constraint(equalToConstant: 56).isActive = true

        let valLbl = UILabel()
        valLbl.text = value
        valLbl.font = AppDesign.Typography.subheadline
        valLbl.textColor = .label

        let row = UIStackView(arrangedSubviews: [icn, keyLbl, valLbl])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        return row
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
    @IBAction func changePhotoTapped(_ sender: Any) { selectImageTapped() }

    @objc private func selectImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate    = self
        picker.sourceType  = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
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

    @objc private func openVehicleDetails() {
        let vc = VehicleRegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
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
}
