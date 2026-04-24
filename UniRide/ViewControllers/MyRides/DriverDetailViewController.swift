import UIKit

/// Bottom sheet shown when a passenger taps the driver row in their upcoming ride card.
/// Mirrors PassengerDetailViewController but shows driver/vehicle info.
final class DriverDetailViewController: UIViewController {

    var driver: UserProfile!
    var ride: Ride!

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStack = UIStackView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let infoStack = UIStackView()
    private var msgBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureSheetPresentation()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // ── Scroll View ──
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // ── Main Stack ──
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        // ── Header ──
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)

        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .systemGray3
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        headerView.addSubview(closeBtn)

        let titleLabel = UILabel()
        titleLabel.text = "Driver Details"
        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // ── Avatar ──
        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarSize: CGFloat = 100
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray6
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = AppDesign.Color.primary.withAlphaComponent(0.1).cgColor

        let initialLabel = UILabel()
        initialLabel.text = String(driver.fullName.prefix(1)).uppercased()
        initialLabel.font = AppDesign.Typography.display
        initialLabel.textColor = AppDesign.Color.textTertiary
        initialLabel.textAlignment = .center
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)

        if let url = driver.photoURL {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarView.image = img
                        initialLabel.isHidden = true
                    }
                }
            }.resume()
        }
        avatarContainer.addSubview(avatarView)
        mainStack.addArrangedSubview(avatarContainer)

        // ── Name & Role ──
        let nameStack = UIStackView()
        nameStack.axis = .vertical
        nameStack.spacing = 4
        nameStack.alignment = .center
        
        nameLabel.text = driver.fullName
        nameLabel.font = AppDesign.Typography.largeTitle
        nameLabel.textColor = AppDesign.Color.textPrimary
        nameLabel.textAlignment = .center
        nameStack.addArrangedSubview(nameLabel)

        let roleBadge = UILabel()
        roleBadge.text = "  DRIVER  "
        roleBadge.font = AppDesign.Typography.captionStrong
        roleBadge.textColor = AppDesign.Color.primary
        roleBadge.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.1)
        roleBadge.layer.cornerRadius = 6
        roleBadge.layer.masksToBounds = true
        nameStack.addArrangedSubview(roleBadge)
        mainStack.addArrangedSubview(nameStack)

        // ── Info Card ──
        let infoCard = UIView()
        infoCard.backgroundColor = AppDesign.Color.elevatedSurface
        infoCard.layer.cornerRadius = AppDesign.Radius.md
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(infoCard)
        
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        buildInfoRows()

        // ── Message Button ──
        msgBtn = makeActionButton(
            title: "Message \(driver.fullName.components(separatedBy: " ").first ?? "Driver")",
            image: "message.fill",
            color: AppDesign.Color.primary
        )
        msgBtn.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        mainStack.addArrangedSubview(msgBtn)

        // ── Safety Buttons ──
        let safetyStack = UIStackView()
        safetyStack.axis = .horizontal
        safetyStack.spacing = 20
        safetyStack.distribution = .fillEqually
        
        let reportBtn = UIButton(type: .system)
        reportBtn.setTitle("Report", for: .normal)
        reportBtn.setImage(UIImage(systemName: "exclamationmark.bubble"), for: .normal)
        reportBtn.tintColor = .systemRed
        reportBtn.titleLabel?.font = AppDesign.Typography.subheadline
        reportBtn.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        
        let blockBtn = UIButton(type: .system)
        blockBtn.setTitle("Block", for: .normal)
        blockBtn.setImage(UIImage(systemName: "hand.raised.fill"), for: .normal)
        blockBtn.tintColor = .systemRed
        blockBtn.titleLabel?.font = AppDesign.Typography.subheadline
        blockBtn.addTarget(self, action: #selector(blockTapped), for: .touchUpInside)
        
        safetyStack.addArrangedSubview(reportBtn)
        safetyStack.addArrangedSubview(blockBtn)
        mainStack.addArrangedSubview(safetyStack)

        // ── Constraints ──
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            closeBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            mainStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            avatarView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            
            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            infoCard.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 20),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -20),

            msgBtn.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            msgBtn.heightAnchor.constraint(equalToConstant: 56),
            
            safetyStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }

    private func buildInfoRows() {
        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var rows: [(String, String, String)] = [
            ("mappin.and.ellipse", "Pickup",    ride.source.address      ?? "—"),
            ("location.fill",      "Drop-off",  ride.destination.address ?? "—"),
            ("phone.fill",         "Contact",   driver.phone             ?? "Not provided")
        ]

        if let model = ride.vehicleModel, !model.isEmpty {
            let plate = ride.registrationPlate ?? "—"
            rows.append(("car.fill", "Vehicle", model))
            rows.append(("number",   "Plate",   plate))
        } else if let v = driver.vehicles?.first {
            let typeStr = (v.type == .car) ? "Car" : "Bike"
            let icon = (v.type == .car) ? "car.fill" : "bicycle"
            rows.append((icon, "Vehicle", "\(typeStr) · \(v.model)"))
            rows.append(("number", "Plate", v.registrationNumber))
            if v.seats > 0 {
                rows.append(("person.2.fill", "Seats", "\(v.seats)"))
            }
        }

        for (icon, key, value) in rows {
            infoStack.addArrangedSubview(makeInfoRow(icon: icon, title: key, value: value))
        }
    }

    private func configureSheetPresentation() {
        guard let sheet = sheetPresentationController else { return }
        let compactDetent = UISheetPresentationController.Detent.custom(identifier: .init("driverCompact")) { context in
            context.maximumDetentValue * 0.70
        }
        sheet.detents = [compactDetent, .large()]
        sheet.selectedDetentIdentifier = .init("driverCompact")
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = AppDesign.Radius.lg
    }

    // MARK: - Helpers
    private func makeInfoRow(icon: String, title: String, value: String, valueColor: UIColor = .label) -> UIView {
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .top

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppDesign.Color.primary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        hStack.addArrangedSubview(iconView)

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = AppDesign.Typography.captionStrong
        titleLbl.textColor = .secondaryLabel
        vStack.addArrangedSubview(titleLbl)

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = AppDesign.Typography.subheadline
        valueLbl.textColor = valueColor
        valueLbl.numberOfLines = 0
        vStack.addArrangedSubview(valueLbl)

        hStack.addArrangedSubview(vStack)
        return hStack
    }

    private func makeActionButton(title: String, image: String, color: UIColor, textColor: UIColor = .white) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: image)
        config.imagePadding = 10
        config.baseBackgroundColor = color
        config.baseForegroundColor = textColor
        config.cornerStyle = .large
        
        let btn = UIButton(configuration: config)
        btn.applyPressMicroInteraction()
        return btn
    }

    // MARK: - Actions
    @objc private func closeTapped() { dismiss(animated: true) }
    @objc private func messageTapped() { dismiss(animated: true) }

    @objc private func reportTapped() {
        SafetyHelper.shared.showReportUI(from: self, reportedUserID: driver.id, contentType: .user)
    }

    @objc private func blockTapped() {
        SafetyHelper.shared.showBlockUI(from: self, blockedUserID: driver.id, userName: driver.fullName) { [weak self] success in
            if success { self?.dismiss(animated: true) }
        }
    }
}
