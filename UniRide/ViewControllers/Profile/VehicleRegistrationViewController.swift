import UIKit

// MARK: - VehicleRegistrationViewController
/// Shown from the Profile page when the user taps "Add Vehicle Info".
/// Collects registration plate, car model, vehicle type, and seat count.
class VehicleRegistrationViewController: UIViewController {

    // MARK: - State
    var vehicleToEdit: Vehicle?
    private var selectedType: VehicleType = .car
    private var seatCount: Int = 1

    // MARK: - UI (structural containers wired in VehicleRegistration.storyboard)
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var formStack: UIStackView!

    // MARK: - Form field views (built & added to formStack at runtime)
    private let nameField    = UITextField()
    private let plateField   = UITextField()
    private let modelField   = UITextField()

    private let carButton    = UIButton(type: .system)
    private let bikeButton   = UIButton(type: .system)

    private let minusSeat    = UIButton(type: .system)
    private let seatCountLbl = UILabel()
    private let plusSeat     = UIButton(type: .system)

    private let saveButton   = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = vehicleToEdit == nil ? "Add Vehicle" : "Edit Vehicle"
        view.backgroundColor = .systemGroupedBackground
        scrollView.alwaysBounceVertical = true
        setupLayout()
        preloadExisting()
    }

    // MARK: - Layout
    private func setupLayout() {
        // 1. Header
        let headerLabel = makeHeaderLabel("Enter your vehicle information so commuters can recognize your vehicle.")
        formStack.addArrangedSubview(headerLabel)

        // 2. Vehicle Name (Alias)
        formStack.addArrangedSubview(makeCard(title: "Vehicle Name (e.g. My Swift)", content: makeNameField()))

        // 3. Registration Plate
        formStack.addArrangedSubview(makeCard(title: "Registration Plate", content: makePlateField()))

        // 4. Car Model
        formStack.addArrangedSubview(makeCard(title: "Car Model", content: makeModelField()))

        // 5. Vehicle Type
        formStack.addArrangedSubview(makeCard(title: "Vehicle Type", content: makeTypeSelector()))

        // 6. Seats
        formStack.addArrangedSubview(makeCard(title: "Total Seats", content: makeSeatsControl()))

        // 7. Save button
        configureSaveButton()
        formStack.addArrangedSubview(saveButton)

        // 8. Delete button (only in edit mode)
        if vehicleToEdit != nil {
            configureDeleteButton()
            formStack.addArrangedSubview(deleteButton)
        }
    }

    // MARK: - Field factories

    private func makeNameField() -> UIView {
        nameField.placeholder = "e.g. Silver City, Red Activa"
        nameField.applyRoundedField()
        nameField.font = AppDesign.Typography.body
        nameField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        nameField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        return nameField
    }

    private func makePlateField() -> UIView {
        plateField.placeholder    = "e.g. PB-08-AB-1234"
        plateField.autocapitalizationType = .allCharacters
        plateField.returnKeyType  = .next
        plateField.clearButtonMode = .whileEditing
        plateField.applyRoundedField()
        plateField.font = AppDesign.Typography.body
        plateField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        plateField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        return plateField
    }

    private func makeModelField() -> UIView {
        modelField.placeholder = "e.g. Maruti Swift, Honda City"
        modelField.returnKeyType = .done
        modelField.clearButtonMode = .whileEditing
        modelField.applyRoundedField()
        modelField.font = AppDesign.Typography.body
        modelField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        modelField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        modelField.delegate = self
        return modelField
    }

    private func makeTypeSelector() -> UIView {
        configTypeButton(carButton, icon: "car.fill", label: "Car", type: .car)
        configTypeButton(bikeButton, icon: "bicycle", label: "Two-Wheeler", type: .bike)

        let row      = UIStackView(arrangedSubviews: [carButton, bikeButton])
        row.axis     = .horizontal
        row.spacing  = 12
        row.distribution = .fillEqually
        return row
    }

    private func configTypeButton(_ btn: UIButton, icon: String, label: String, type: VehicleType) {
        var config = UIButton.Configuration.tinted()
        config.image = UIImage(systemName: icon)
        config.title = label
        config.imagePlacement = .top
        config.imagePadding   = 8
        config.baseBackgroundColor = AppDesign.Color.primary
        config.baseForegroundColor = AppDesign.Color.primary
        config.cornerStyle = .medium
        btn.configuration = config
        btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.didSelectType(type)
        }, for: .touchUpInside)
    }

    private func makeSeatsControl() -> UIView {
        var minusCfg = UIButton.Configuration.filled()
        minusCfg.image = UIImage(systemName: "minus")
        minusCfg.baseBackgroundColor = AppDesign.Color.borderSubtle
        minusCfg.baseForegroundColor = .label
        minusCfg.cornerStyle = .capsule
        minusSeat.configuration = minusCfg
        minusSeat.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        minusSeat.heightAnchor.constraint(equalToConstant: 44).isActive = true
        minusSeat.addAction(UIAction { [weak self] _ in self?.adjustSeats(-1) }, for: .touchUpInside)

        seatCountLbl.text          = "\(seatCount)"
        seatCountLbl.font          = AppDesign.Typography.display
        seatCountLbl.textAlignment = .center
        seatCountLbl.widthAnchor.constraint(equalToConstant: 60).isActive = true

        var plusCfg = UIButton.Configuration.filled()
        plusCfg.image = UIImage(systemName: "plus")
        plusCfg.baseBackgroundColor = AppDesign.Color.primary
        plusCfg.baseForegroundColor = .white
        plusCfg.cornerStyle = .capsule
        plusSeat.configuration = plusCfg
        plusSeat.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        plusSeat.heightAnchor.constraint(equalToConstant: 44).isActive = true
        plusSeat.addAction(UIAction { [weak self] _ in self?.adjustSeats(1) }, for: .touchUpInside)

        let hint = UILabel()
        hint.text      = "Maximum 6 seats"
        hint.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)

        let row       = UIStackView(arrangedSubviews: [minusSeat, seatCountLbl, plusSeat])
        row.axis      = .horizontal
        row.spacing   = 16
        row.alignment = .center

        let container = UIStackView(arrangedSubviews: [row, hint])
        container.axis    = .vertical
        container.spacing = 6
        container.alignment = .center
        return container
    }

    private func configureSaveButton() {
        saveButton.setTitle(vehicleToEdit == nil ? "Save Vehicle" : "Update Vehicle", for: .normal)
        saveButton.applyPrimaryButton(color: AppDesign.Color.primary, radius: AppDesign.Radius.sm)
        saveButton.setPrimaryCTAEnabled(false)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func configureDeleteButton() {
        deleteButton.setTitle("Delete Vehicle", for: .normal)
        deleteButton.applyPrimaryButton(color: AppDesign.Color.destructive, radius: AppDesign.Radius.sm)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    // MARK: - Card wrapper
    private func makeCard(title: String, content: UIView) -> UIView {
        let card = UIView()
        card.applyCardStyle(corner: AppDesign.Radius.md, shadowOpacity: AppDesign.Shadow.smallCardOpacity, shadowRadius: AppDesign.Shadow.smallCardRadius)

        let titleLbl = UILabel()
        titleLbl.text      = title
        titleLbl.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)

        let stack      = UIStackView(arrangedSubviews: [titleLbl, content])
        stack.axis     = .vertical
        stack.spacing  = AppDesign.Spacing.sm - AppDesign.Spacing.xxs / 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: AppDesign.Spacing.md),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.md),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.md),
        ])
        return card
    }

    private func makeHeaderLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text          = text
        lbl.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel, lines: 0)
        lbl.numberOfLines = 0
        return lbl
    }

    // MARK: - Actions

    private func didSelectType(_ type: VehicleType) {
        selectedType = type
        updateTypeButtons()
        fieldsChanged()
    }

    private func updateTypeButtons() {
        let isCarSelected = selectedType == .car
        [carButton, bikeButton].forEach { btn in
            let isSel = (btn == carButton) ? isCarSelected : !isCarSelected
            btn.configuration?.baseBackgroundColor = isSel ? AppDesign.Color.primary : AppDesign.Color.fieldBackground
            btn.configuration?.baseForegroundColor = isSel ? AppDesign.Color.primary : .secondaryLabel
            btn.layer.borderWidth = isSel ? 2 : 0
            btn.layer.borderColor = isSel ? AppDesign.Color.primary.cgColor : nil
            btn.layer.cornerRadius = AppDesign.Radius.sm
        }
    }

    private func adjustSeats(_ delta: Int) {
        let newVal = seatCount + delta
        guard newVal >= 1, newVal <= 6 else { return }
        seatCount = newVal
        seatCountLbl.text = "\(seatCount)"
        minusSeat.isEnabled = seatCount > 1
        minusSeat.alpha     = seatCount > 1 ? 1 : 0.4
    }

    @objc private func fieldsChanged() {
        let ready = !(nameField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                 && !(plateField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                 && !(modelField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                 && seatCount >= 1
        saveButton.setPrimaryCTAEnabled(ready)
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
              let plate = plateField.text?.trimmingCharacters(in: .whitespaces), !plate.isEmpty,
              let model = modelField.text?.trimmingCharacters(in: .whitespaces), !model.isEmpty else { return }

        let vehicle = Vehicle(alias: name, type: selectedType, model: model, registrationNumber: plate, seats: seatCount)

        // Update local state
        var user = UserDataModel.shared.getCurrentUser()
        var list = user?.vehicles ?? []

        if let original = vehicleToEdit {
            if let idx = list.firstIndex(where: { $0.registrationNumber == original.registrationNumber }) {
                list[idx] = vehicle
            } else {
                list.append(vehicle)
            }
        } else {
            list.append(vehicle)
        }

        user?.vehicles = list
        if let u = user {
            UserDataModel.shared.editCurrentUser(vehicles: u.vehicles)
        }

        saveButton.isEnabled = false
        var cfg = saveButton.configuration
        cfg?.showsActivityIndicator = true
        cfg?.title = "Saving…"
        saveButton.configuration = cfg

        Task { @MainActor [weak self] in
            guard let self else { return }

            if let userID = SessionManager.shared.userID {
                do {
                    try await ProfileRepository.shared.upsertVehicle(userID: userID, vehicle: vehicle)
                } catch {
                    print("[VehicleReg] Remote sync failed:", error.localizedDescription)
                }
            }

            var cfg = self.saveButton.configuration
            cfg?.showsActivityIndicator = false
            cfg?.title = "Save Vehicle"
            self.saveButton.configuration = cfg
            self.saveButton.isEnabled = true

            AppHaptics.success()
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "Delete Vehicle?", message: "This vehicle will be removed from your profile. This can't be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        present(alert, animated: true)
    }

    private func performDelete() {
        guard let original = vehicleToEdit, var user = UserDataModel.shared.getCurrentUser() else { return }
        var list = user.vehicles ?? []
        list.removeAll(where: { $0.registrationNumber == original.registrationNumber })
        user.vehicles = list
        UserDataModel.shared.editCurrentUser(vehicles: list)

        Task {
            // Sync via profile upsert handled by repository
        }

        AppHaptics.success()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Preload existing vehicle
    private func preloadExisting() {
        if let vehicle = vehicleToEdit {
            nameField.text   = vehicle.alias
            plateField.text  = vehicle.registrationNumber
            modelField.text  = vehicle.model
            selectedType     = vehicle.type
            seatCount        = vehicle.seats
            seatCountLbl.text = "\(seatCount)"
            updateTypeButtons()
            fieldsChanged()
            return
        }
        updateTypeButtons()
    }
}

// MARK: - UITextFieldDelegate
extension VehicleRegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
