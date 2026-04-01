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
    // MARK: - UI
    private func buildUI() {
        view.backgroundColor = .systemBackground

        // ── Scroll View for Responsiveness ───────────────────────────
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // ── Main Stack View ──────────────────────────────────────────
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        // ── Header (Close Button & Title) ────────────────────────────
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
        titleLabel.text = "Passenger Details"
        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // ── Avatar ───────────────────────────────────────────────────
        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarSize: CGFloat = 100
        let avatarView = UIImageView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .systemGray6
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = AppDesign.Color.primary.withAlphaComponent(0.1).cgColor

        // Initials fallback
        let initialLabel = UILabel()
        initialLabel.text = String(passenger.fullName.prefix(1)).uppercased()
        initialLabel.font = .systemFont(ofSize: 40, weight: .bold)
        initialLabel.textColor = .systemGray3
        initialLabel.textAlignment = .center
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)

        if let url = passenger.photoURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        avatarView.image = img
                        initialLabel.isHidden = true
                    }
                }
            }.resume()
        }
        avatarContainer.addSubview(avatarView)
        mainStack.addArrangedSubview(avatarContainer)

        // ── Name & Role ──────────────────────────────────────────────
        let nameStack = UIStackView()
        nameStack.axis = .vertical
        nameStack.spacing = 4
        nameStack.alignment = .center
        
        let nameLabel = UILabel()
        nameLabel.text = passenger.fullName
        nameLabel.font = AppDesign.Typography.h2
        nameLabel.textColor = AppDesign.Color.textPrimary
        nameLabel.textAlignment = .center
        nameStack.addArrangedSubview(nameLabel)

        let roleBadge = UILabel()
        roleBadge.text = "  PASSENGER  "
        roleBadge.font = AppDesign.Typography.captionStrong
        roleBadge.textColor = AppDesign.Color.primary
        roleBadge.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.1)
        roleBadge.layer.cornerRadius = 6
        roleBadge.layer.masksToBounds = true
        nameStack.addArrangedSubview(roleBadge)
        
        mainStack.addArrangedSubview(nameStack)

        // ── Info Card ────────────────────────────────────────────────
        let infoCard = UIView()
        infoCard.backgroundColor = AppDesign.Color.elevatedSurface
        infoCard.layer.cornerRadius = AppDesign.Radius.md
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(infoCard)
        
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        let pickup = ride.source.address ?? "Unknown"
        let dropoff = ride.destination.address ?? "Unknown"
        let contact = passenger.phone ?? "Not provided"

        infoStack.addArrangedSubview(makeInfoRow(icon: "mappin.and.ellipse", title: "Pickup", value: pickup))
        infoStack.addArrangedSubview(makeInfoRow(icon: "location.fill", title: "Drop-off", value: dropoff))
        infoStack.addArrangedSubview(makeInfoRow(icon: "phone.fill", title: "Contact", value: contact))
        infoStack.addArrangedSubview(makeInfoRow(icon: "checkmark.seal.fill", title: "Status", value: "Confirmed", valueColor: AppDesign.Color.success))

        // ── Actions Stack ────────────────────────────────────────────
        let actionsStack = UIStackView()
        actionsStack.axis = .vertical
        actionsStack.spacing = 12
        actionsStack.alignment = .fill
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(actionsStack)

        let msgBtn = makeActionButton(
            title: "Message \(passenger.fullName.components(separatedBy: " ").first ?? "Passenger")",
            image: "message.fill",
            color: AppDesign.Color.primary
        )
        msgBtn.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        actionsStack.addArrangedSubview(msgBtn)

        let removeBtn = makeActionButton(title: "Remove Passenger", image: "person.badge.minus.fill", color: .systemGray6, textColor: AppDesign.Color.destructive)
        removeBtn.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        actionsStack.addArrangedSubview(removeBtn)

        // ── Safety Buttons ───────────────────────────────────────────
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

        // ── Layout Constraints ───────────────────────────────────────
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

            actionsStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            msgBtn.heightAnchor.constraint(equalToConstant: 56),
            removeBtn.heightAnchor.constraint(equalToConstant: 56),
            
            safetyStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }

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
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func messageTapped() {
        dismiss(animated: true)
        // Future: open messaging screen
    }

    @objc private func reportTapped() {
        SafetyHelper.shared.showReportUI(from: self, reportedUserID: passenger.id, contentType: .user)
    }

    @objc private func blockTapped() {
        SafetyHelper.shared.showBlockUI(from: self, blockedUserID: passenger.id, userName: passenger.fullName) { [weak self] success in
            if success { self?.dismiss(animated: true) }
        }
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
            Task { @MainActor in
                do {
                    let bookings = RideDataModel.shared.listBookings(for: self.ride.id)
                    if let booking = bookings.first(where: {
                        $0.passengerUserID == self.passenger.id && $0.status == .confirmed
                    }) {
                        try await RideDataModel.shared.cancelBookingAsync(
                            bookingID: booking.id,
                            by: self.ride.driverUserID
                        )
                    }
                    self.onRemovePassenger?()
                    self.dismiss(animated: true)
                } catch {
                    let fail = UIAlertController(
                        title: "Couldn’t remove passenger",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    fail.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(fail, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }
}
