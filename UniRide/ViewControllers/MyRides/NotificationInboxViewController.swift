import UIKit

/// A simple inbox sheet showing all in-app notifications for the current user.
final class NotificationInboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var notifications: [AppNotification]!

    @IBOutlet private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemGroupedBackground

        tableView.register(NotifCell.self, forCellReuseIdentifier: NotifCell.id)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.rowHeight  = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }

    // MARK: - DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotifCell.id, for: indexPath) as! NotifCell
        cell.configure(with: notifications[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell

private final class NotifCell: UITableViewCell {
    static let id = "NotifCell"

    private let iconView  = UIImageView()
    private let titleLbl  = UILabel()
    private let bodyLbl   = UILabel()
    private let timeLbl   = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor   = AppDesign.Color.primary
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.font = AppDesign.Typography.captionStrong
        titleLbl.numberOfLines = 1

        bodyLbl.font = AppDesign.Typography.caption
        bodyLbl.textColor = .secondaryLabel
        bodyLbl.numberOfLines = 0

        timeLbl.font = AppDesign.Typography.caption
        timeLbl.textColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLbl, bodyLbl, timeLbl])
        textStack.axis = .vertical
        textStack.spacing = AppDesign.Spacing.xxs / 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        [iconView, textStack].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDesign.Spacing.md),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppDesign.Spacing.sm + AppDesign.Spacing.xxs / 2),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: AppDesign.Spacing.sm),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDesign.Spacing.md),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppDesign.Spacing.sm),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppDesign.Spacing.sm),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with notif: AppNotification) {
        switch notif.type {
        case .newRequest:
            iconView.image     = UIImage(systemName: "bell.badge.fill")
            iconView.tintColor = AppDesign.Color.primary
        case .passengerCancelled:
            iconView.image     = UIImage(systemName: "person.badge.minus")
            iconView.tintColor = .systemOrange
        case .passengerJoined:
            iconView.image     = UIImage(systemName: "person.badge.plus")
            iconView.tintColor = AppDesign.Color.primary
        case .requestApproved:
            iconView.image     = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = AppDesign.Color.primary
        case .requestDenied:
            iconView.image     = UIImage(systemName: "xmark.circle.fill")
            iconView.tintColor = AppDesign.Color.destructive
        case .rideCreated:
            iconView.image     = UIImage(systemName: "car.fill")
            iconView.tintColor = AppDesign.Color.primary
        case .rideCancelled:
            iconView.image     = UIImage(systemName: "xmark.octagon.fill")
            iconView.tintColor = AppDesign.Color.destructive
        case .rideStarted:
            iconView.image     = UIImage(systemName: "figure.wave.circle.fill")
            iconView.tintColor = AppDesign.Color.primary
        case .rideCompleted:
            iconView.image     = UIImage(systemName: "checkmark.seal.fill")
            iconView.tintColor = .systemGreen
        }

        titleLbl.text = notif.title
        bodyLbl.text  = notif.body

        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        timeLbl.text = rel.localizedString(for: notif.timestamp, relativeTo: Date())

        // Unread highlight tinted to match notification type
        if notif.isRead {
            backgroundColor = .clear
        } else {
            switch notif.type {
            case .newRequest, .requestApproved, .passengerJoined, .rideCreated, .rideStarted, .rideCompleted:
                backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.08)
            case .requestDenied, .rideCancelled:
                backgroundColor = AppDesign.Color.destructive.withAlphaComponent(0.05)
            default:
                backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.06)
            }
        }
    }
}
