import UIKit

// MARK: - VehicleRegistrationViewController
/// Shown from the Profile page when the user taps "Add Vehicle Info".
/// Collects registration plate, car model, vehicle type, and seat count.
class VehicleRegistrationViewController: UIViewController {

    // MARK: - State
    private var selectedType: VehicleType = .car
    private var seatCount: Int = 1

    // MARK: - UI — form fields
    private let scrollView   = UIScrollView()
    private let formStack    = UIStackView()

    private let plateField   = UITextField()
    private let modelField   = UITextField()

    private let carButton    = UIButton(type: .system)
    private let bikeButton   = UIButton(type: .system)

    private let minusSeat    = UIButton(type: .system)
    private let seatCountLbl = UILabel()
    private let plusSeat     = UIButton(type: .system)

    private let saveButton   = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vehicle Details"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        preloadExisting()
    }

    // MARK: - Layout
    private func setupLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        formStack.axis    = .vertical
        formStack.spacing = AppDesign.Spacing.lg
        formStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(formStack)
        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.xl),
            formStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            formStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            formStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl - AppDesign.Spacing.xs),
            formStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.xl * 2),
        ])

        // 1. Header
        let headerLabel = makeHeaderLabel("Enter your vehicle information so passengers can recognise your vehicle.")
        formStack.addArrangedSubview(headerLabel)

        // 2. Registration Plate
        formStack.addArrangedSubview(makeCard(title: "Registration Plate", content: makePlateField()))

        // 3. Car Model
        formStack.addArrangedSubview(makeCard(title: "Car Model", content: makeModelField()))

        // 4. Vehicle Type
        formStack.addArrangedSubview(makeCard(title: "Vehicle Type", content: makeTypeSelector()))

        // 5. Seats
        formStack.addArrangedSubview(makeCard(title: "Seats You Can Offer", content: makeSeatsControl()))

        // 6. Save button
        configureSaveButton()
        formStack.addArrangedSubview(saveButton)
    }

    // MARK: - Field factories

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
        // Car
        configTypeButton(carButton, icon: "car.fill", label: "Car", type: .car)

        // Bike
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
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.didSelectType(type)
        }, for: .touchUpInside)
    }

    private func makeSeatsControl() -> UIView {
        // Minus
        var minusCfg = UIButton.Configuration.filled()
        minusCfg.image = UIImage(systemName: "minus")
        minusCfg.baseBackgroundColor = .systemGray5
        minusCfg.baseForegroundColor = .label
        minusCfg.cornerStyle = .capsule
        minusSeat.configuration = minusCfg
        minusSeat.translatesAutoresizingMaskIntoConstraints = false
        minusSeat.widthAnchor.constraint(equalToConstant: 44).isActive  = true
        minusSeat.heightAnchor.constraint(equalToConstant: 44).isActive = true
        minusSeat.addAction(UIAction { [weak self] _ in self?.adjustSeats(-1) }, for: .touchUpInside)

        // Count label
        seatCountLbl.text          = "\(seatCount)"
        seatCountLbl.font          = AppDesign.Typography.h2
        seatCountLbl.textAlignment = .center
        seatCountLbl.widthAnchor.constraint(equalToConstant: 60).isActive = true

        // Plus
        var plusCfg = UIButton.Configuration.filled()
        plusCfg.image = UIImage(systemName: "plus")
        plusCfg.baseBackgroundColor = AppDesign.Color.primary
        plusCfg.baseForegroundColor = .white
        plusCfg.cornerStyle = .capsule
        plusSeat.configuration = plusCfg
        plusSeat.translatesAutoresizingMaskIntoConstraints = false
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
        saveButton.setTitle("Save Vehicle", for: .normal)
        saveButton.applyPrimaryButton(color: AppDesign.Color.primary, radius: AppDesign.Radius.sm)
        saveButton.setPrimaryCTAEnabled(false)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
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
        let ready = !(plateField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                 && !(modelField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                 && seatCount >= 1
        saveButton.setPrimaryCTAEnabled(ready)
    }

    @objc private func saveTapped() {
        guard let plate = plateField.text?.trimmingCharacters(in: .whitespaces), !plate.isEmpty,
              let model = modelField.text?.trimmingCharacters(in: .whitespaces), !model.isEmpty else { return }

        let vehicle = Vehicle(type: selectedType, model: model, registrationNumber: plate, seats: seatCount)

        // Save locally immediately
        UserDataModel.shared.editCurrentUser(vehicle: vehicle)

        // Show loading state on save button
        saveButton.isEnabled = false
        var cfg = saveButton.configuration
        cfg?.showsActivityIndicator = true
        cfg?.title = "Saving…"
        saveButton.configuration = cfg

        Task { @MainActor [weak self] in
            guard let self else { return }

            // Sync to Supabase
            if let userID = SessionManager.shared.userID {
                do {
                    try await ProfileRepository.shared.upsertVehicle(userID: userID, vehicle: vehicle)
                } catch {
                    // Non-fatal — local save already succeeded
                    print("[VehicleReg] Remote sync failed:", error.localizedDescription)
                }
            }

            // Restore button state
            var cfg = self.saveButton.configuration
            cfg?.showsActivityIndicator = false
            cfg?.title = "Save Vehicle"
            self.saveButton.configuration = cfg
            self.saveButton.isEnabled = true

            AppHaptics.success()
            let alert = UIAlertController(title: "Saved!", message: "Your vehicle has been registered.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: - Preload existing vehicle
    private func preloadExisting() {
        guard let vehicle = UserDataModel.shared.getCurrentUser()?.vehicle else {
            updateTypeButtons()
            return
        }
        plateField.text  = vehicle.registrationNumber
        modelField.text  = vehicle.model
        selectedType     = vehicle.type
        seatCount        = vehicle.seats
        seatCountLbl.text = "\(seatCount)"
        updateTypeButtons()
        fieldsChanged()
    }
}

// MARK: - UITextFieldDelegate
extension VehicleRegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
