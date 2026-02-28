import UIKit

/// Modal sheet shown when the host taps a passenger avatar circle.
/// Displays passenger info and offers Message / Remove Passenger actions.
final class PassengerDetailViewController: UIViewController {

    // MARK: - Data
    private let passenger: UserProfile
    private let ride: Ride
    var onRemovePassenger: (() -> Void)?

    init(passenger: UserProfile, ride: Ride) {
        self.passenger = passenger
        self.ride = ride
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    // MARK: - UI
    private func buildUI() {
        view.backgroundColor = .systemBackground

        // ── Close button (top-right X) ──────────────────────────────
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .systemGray3
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)

        // ── Title ────────────────────────────────────────────────────
        let titleLabel = UILabel()
        titleLabel.text = "Passenger Details"
        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ── Avatar ───────────────────────────────────────────────────
        let avatarSize: CGFloat = 90
        let avatarView = UIImageView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray5
        avatarView.contentMode = .scaleAspectFill

        // Initials fallback
        let initial = String(passenger.fullName.prefix(1)).uppercased()
        let initLabel = UILabel(frame: CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize))
        initLabel.text = initial
        initLabel.font = AppDesign.Typography.h1
        initLabel.textColor = .systemGray
        initLabel.textAlignment = .center
        avatarView.addSubview(initLabel)

        if let url = passenger.photoURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        avatarView.image = img
                        initLabel.removeFromSuperview()
                    }
                }
            }.resume()
        }
        view.addSubview(avatarView)

        // ── Name ─────────────────────────────────────────────────────
        let nameLabel = UILabel()
        nameLabel.text = passenger.fullName
        nameLabel.font = AppDesign.Typography.title
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        // ── Role tag ─────────────────────────────────────────────────
        let roleLabel = UILabel()
        roleLabel.text = "Passenger"
        roleLabel.font = AppDesign.Typography.subheadline
        roleLabel.textColor = .secondaryLabel
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roleLabel)

        // ── Info stack ───────────────────────────────────────────────
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = AppDesign.Spacing.xs
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        let pickup = ride.source.address ?? "Unknown"
        let dropoff = ride.destination.address ?? "Unknown"
        let contact = passenger.phone ?? "—"

        for (key, value) in [
            ("Pickup", pickup),
            ("Drop-off", dropoff),
            ("Contact", contact),
            ("Status", "Confirmed")
        ] {
            let row = UILabel()
            row.text = "\(key): \(value)"
            row.font = AppDesign.Typography.subheadline
            row.textColor = .label
            row.numberOfLines = 0
            infoStack.addArrangedSubview(row)
        }

        // ── Message button ───────────────────────────────────────────
        let msgBtn = makeActionButton(
            title: "Message \(passenger.fullName.components(separatedBy: " ").first ?? passenger.fullName)",
            color: AppDesign.Color.primary
        )
        msgBtn.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        view.addSubview(msgBtn)

        // ── Remove button ────────────────────────────────────────────
        let removeBtn = makeActionButton(title: "Remove Passenger", color: AppDesign.Color.destructive)
        removeBtn.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        view.addSubview(removeBtn)

        // ── Layout ───────────────────────────────────────────────────
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

            removeBtn.topAnchor.constraint(equalTo: msgBtn.bottomAnchor, constant: 12),
            removeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.lg),
            removeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.lg),
            removeBtn.heightAnchor.constraint(equalToConstant: AppDesign.Size.buttonHeight),
        ])
    }

    private func makeActionButton(title: String, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = AppDesign.Typography.action
            return a
        }
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func messageTapped() {
        dismiss(animated: true)
        // Future: open messaging screen
    }

    @objc private func removeTapped() {
        let alert = UIAlertController(
            title: "Remove Passenger",
            message: "Are you sure you want to remove \(passenger.fullName) from this ride?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self else { return }
            // Find the confirmed booking and cancel it (returns seat to ride)
            let bookings = RideDataModel.shared.listBookings(for: self.ride.id)
            if let booking = bookings.first(where: {
                $0.passengerUserID == self.passenger.id && $0.status == .confirmed
            }) {
                RideDataModel.shared.cancelBooking(
                    bookingID: booking.id,
                    by: self.ride.driverUserID  // host is removing the passenger
                )
            }
            self.onRemovePassenger?()
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
