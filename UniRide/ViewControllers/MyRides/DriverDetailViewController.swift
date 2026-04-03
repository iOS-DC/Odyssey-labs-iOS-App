import UIKit

/// Bottom sheet shown when a passenger taps the driver row in their upcoming ride card.
/// Mirrors PassengerDetailViewController but shows driver/vehicle info.
final class DriverDetailViewController: UIViewController {

    var driver: UserProfile!
    var ride: Ride!

    // MARK: - IBOutlets
    @IBOutlet private var avatarView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var roleLabel: UILabel!
    @IBOutlet private var infoStack: UIStackView!
    @IBOutlet private var msgBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureAvatar()
        configureLabels()
        buildInfoRows()
        configureMessageButton()
        configureSheetPresentation()
    }

    // MARK: - Configuration

    private func configureAvatar() {
        avatarView.layer.cornerRadius = 45
        avatarView.layer.masksToBounds = true
        avatarView.contentMode = .scaleAspectFill

        let initial = String(driver.fullName.prefix(1)).uppercased()
        let initLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        initLabel.text = initial
        initLabel.font = AppDesign.Typography.h1
        initLabel.textColor = .systemGray
        initLabel.textAlignment = .center
        avatarView.addSubview(initLabel)

        if let url = driver.photoURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async { self.avatarView.image = img; initLabel.removeFromSuperview() }
                }
            }.resume()
        }
    }

    private func configureLabels() {
        nameLabel.text = driver.fullName
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

        var rows: [(String, String)] = [
            ("Pickup",   ride.source.address      ?? "—"),
            ("Drop-off", ride.destination.address ?? "—"),
            ("Contact",  driver.phone             ?? "—"),
        ]

        if let model = ride.vehicleModel, !model.isEmpty {
            let plate = ride.registrationPlate ?? "—"
            rows.append(("Vehicle", model))
            rows.append(("Plate",   plate))
        } else if let v = driver.vehicles?.first {
            let typeStr = (v.type == .car) ? "Car" : "Bike"
            rows.append(("Vehicle",   "\(typeStr) · \(v.model)"))
            rows.append(("Plate",     v.registrationNumber))
            if v.seats > 0 {
                rows.append(("Seats", "\(v.seats)"))
            }
        }

        for (key, value) in rows {
            let row = makeInfoRow(key: key, value: value)
            infoStack.addArrangedSubview(row)
        }
    }

    private func configureMessageButton() {
        let firstName = driver.fullName.components(separatedBy: " ").first ?? driver.fullName
        var config = UIButton.Configuration.filled()
        config.title = "Message \(firstName)"
        config.baseBackgroundColor = AppDesign.Color.primary
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var a = a; a.font = AppDesign.Typography.action; return a
        }
        config.cornerStyle = .capsule
        msgBtn.configuration = config
    }

    private func configureSheetPresentation() {
        guard let sheet = sheetPresentationController else { return }
        let compactDetent = UISheetPresentationController.Detent.custom(identifier: .init("driverCompact")) { context in
            context.maximumDetentValue * 0.70
        }
        sheet.detents = [compactDetent]
        sheet.selectedDetentIdentifier = .init("driverCompact")
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = AppDesign.Radius.lg
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
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    // MARK: - IBActions
    @IBAction private func closeTapped() { dismiss(animated: true) }
    @IBAction private func messageTapped() { dismiss(animated: true) }

    @IBAction private func reportTapped() {
        SafetyHelper.shared.showReportUI(from: self, reportedUserID: driver.id, contentType: .user)
    }

    @IBAction private func blockTapped() {
        SafetyHelper.shared.showBlockUI(from: self, blockedUserID: driver.id, userName: driver.fullName) { [weak self] success in
            if success { self?.dismiss(animated: true) }
        }
    }
}
