import UIKit

/// Bottom sheet shown when a passenger taps the driver row in their upcoming ride card.
/// Mirrors PassengerDetailViewController but shows driver/vehicle info.
final class DriverDetailViewController: UIViewController {

    private let driver: UserProfile
    private let ride: Ride

    init(driver: UserProfile, ride: Ride) {
        self.driver = driver
        self.ride   = ride
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    private func buildUI() {
        view.backgroundColor = .systemBackground

        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .systemGray3
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Driver Details"
        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Avatar
        let avatarSize: CGFloat = 90
        let avatarView = UIImageView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius  = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray5
        avatarView.contentMode = .scaleAspectFill
        let initial = String(driver.fullName.prefix(1)).uppercased()
        let initLabel = UILabel(frame: CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize))
        initLabel.text = initial
        initLabel.font = AppDesign.Typography.h1
        initLabel.textColor = .systemGray
        initLabel.textAlignment = .center
        avatarView.addSubview(initLabel)
        if let url = driver.photoURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async { avatarView.image = img; initLabel.removeFromSuperview() }
                }
            }.resume()
        }
        view.addSubview(avatarView)

        // Name
        let nameLabel = UILabel()
        nameLabel.text = driver.fullName
        nameLabel.font = AppDesign.Typography.title
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        // Role tag (Driver)
        let roleLabel = UILabel()
        roleLabel.text = "Driver"
        roleLabel.font = AppDesign.Typography.subheadline
        roleLabel.textColor = .secondaryLabel
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roleLabel)

        // Info rows
        let infoStack = UIStackView()
        infoStack.axis    = .vertical
        infoStack.spacing = AppDesign.Spacing.xs
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        var rows: [(String, String)] = [
            ("Pickup",    ride.source.address      ?? "—"),
            ("Drop-off",  ride.destination.address ?? "—"),
            ("Contact",   driver.phone             ?? "—"),
        ]

        if let model = ride.vehicleModel, let plate = ride.registrationPlate {
            rows.append(("Vehicle", model))
            rows.append(("Plate",   plate))
        } else if let v = driver.vehicles?.first {
            let typeStr = (v.type == .car) ? "Car" : "Bike"
            rows.append(("Vehicle",    "\(typeStr) · \(v.model)"))
            rows.append(("Plate",      v.registrationNumber))
            rows.append(("Seats",      "\(v.seats)"))
        }

        for (key, value) in rows {
            let row = makeInfoRow(key: key, value: value)
            infoStack.addArrangedSubview(row)
        }

        // Message button
        let msgBtn = makeActionButton(
            title: "Message \(driver.fullName.components(separatedBy: " ").first ?? driver.fullName)",
            color: AppDesign.Color.primary
        )
        msgBtn.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        view.addSubview(msgBtn)

        // Layout
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppDesign.Spacing.lg),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            avatarView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),

            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            infoStack.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 20),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),

            msgBtn.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 28),
            msgBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            msgBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),
            msgBtn.heightAnchor.constraint(equalToConstant: AppDesign.Size.buttonHeight),
        ])
    }

    // MARK: - Helpers

    private func makeInfoRow(key: String, value: String) -> UILabel {
        let label = UILabel()
        let str = NSMutableAttributedString(
            string: "\(key): ",
            attributes: [.font: AppDesign.Typography.subheadline,
                         .foregroundColor: UIColor.secondaryLabel])
        str.append(NSAttributedString(
            string: value,
            attributes: [.font: AppDesign.Typography.subheadline,
                         .foregroundColor: UIColor.label]))
        label.attributedText = str
        label.numberOfLines = 0
        return label
    }

    private func makeActionButton(title: String, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var a = a; a.font = AppDesign.Typography.action; return a
        }
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // MARK: - Actions
    @objc private func closeTapped() { dismiss(animated: true) }
    @objc private func messageTapped() { dismiss(animated: true) }
}
