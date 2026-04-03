import UIKit

/// Modal sheet shown when the host taps a passenger avatar circle.
/// Displays passenger info and offers Message / Remove Passenger actions.
final class PassengerDetailViewController: UIViewController {

    // MARK: - Data
    var passenger: UserProfile!
    var ride: Ride!
    var onRemovePassenger: (() -> Void)?

    // MARK: - IBOutlets
    @IBOutlet private var avatarView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var roleLabel: UILabel!
    @IBOutlet private var infoStack: UIStackView!
    @IBOutlet private var msgBtn: UIButton!
    @IBOutlet private var removeBtn: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureAvatar()
        configureLabels()
        buildInfoRows()
        configureButtons()
        configureSheetPresentation()
    }

    // MARK: - Configuration

    private func configureAvatar() {
        avatarView.layer.cornerRadius = 45
        avatarView.layer.masksToBounds = true
        avatarView.contentMode = .scaleAspectFill

        let initial = String(passenger.fullName.prefix(1)).uppercased()
        let initLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        initLabel.text = initial
        initLabel.font = AppDesign.Typography.h1
        initLabel.textColor = .systemGray
        initLabel.textAlignment = .center
        avatarView.addSubview(initLabel)

        if let url = passenger.photoURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.avatarView.image = img
                        initLabel.removeFromSuperview()
                    }
                }
            }.resume()
        }
    }

    private func configureLabels() {
        nameLabel.text = passenger.fullName
    }

    private func buildInfoRows() {
        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.distribution = .fill
        infoStack.spacing = 12

        infoStack.arrangedSubviews.forEach { subview in
            infoStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        let pickup  = ride.source.address      ?? "Unknown"
        let dropoff = ride.destination.address ?? "Unknown"
        let contact = passenger.phone          ?? "—"

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
            row.setContentHuggingPriority(.required, for: .vertical)
            row.setContentCompressionResistancePriority(.required, for: .vertical)
            infoStack.addArrangedSubview(row)
        }
    }

    private func configureButtons() {
        let firstName = passenger.fullName.components(separatedBy: " ").first ?? passenger.fullName
        applyActionButtonStyle(msgBtn,    title: "Message \(firstName)", color: AppDesign.Color.primary)
        applyActionButtonStyle(removeBtn, title: "Remove Passenger",     color: AppDesign.Color.destructive)
    }

    private func configureSheetPresentation() {
        guard let sheet = sheetPresentationController else { return }
        let compactDetent = UISheetPresentationController.Detent.custom(identifier: .init("passengerCompact")) { context in
            context.maximumDetentValue * 0.65
        }
        sheet.detents = [compactDetent]
        sheet.selectedDetentIdentifier = .init("passengerCompact")
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = AppDesign.Radius.lg
    }

    private func applyActionButtonStyle(_ btn: UIButton, title: String, color: UIColor) {
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
        btn.configuration = config
    }

    // MARK: - IBActions
    @IBAction private func closeTapped() {
        dismiss(animated: true)
    }

    @IBAction private func messageTapped() {
        dismiss(animated: true)
    }

    @IBAction private func reportTapped() {
        SafetyHelper.shared.showReportUI(from: self, reportedUserID: passenger.id, contentType: .user)
    }

    @IBAction private func blockTapped() {
        SafetyHelper.shared.showBlockUI(from: self, blockedUserID: passenger.id, userName: passenger.fullName) { [weak self] success in
            if success { self?.dismiss(animated: true) }
        }
    }

    @IBAction private func removeTapped() {
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
                        title: "Couldn't remove passenger",
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
