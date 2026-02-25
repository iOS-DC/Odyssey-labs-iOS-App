import UIKit

/// A simple inbox sheet showing all in-app notifications for the current user.
final class NotificationInboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let notifications: [AppNotification]
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(notifications: [AppNotification]) {
        self.notifications = notifications
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemGroupedBackground

        tableView.register(NotifCell.self, forCellReuseIdentifier: NotifCell.id)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.rowHeight  = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
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
        iconView.tintColor   = .systemOrange
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLbl.numberOfLines = 1

        bodyLbl.font = .systemFont(ofSize: 13)
        bodyLbl.textColor = .secondaryLabel
        bodyLbl.numberOfLines = 0

        timeLbl.font = .systemFont(ofSize: 11)
        timeLbl.textColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLbl, bodyLbl, timeLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        [iconView, textStack].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with notif: AppNotification) {
        switch notif.type {
        case .passengerCancelled:
            iconView.image     = UIImage(systemName: "person.badge.minus")
            iconView.tintColor = .systemOrange
        case .passengerJoined:
            iconView.image     = UIImage(systemName: "person.badge.plus")
            iconView.tintColor = .systemGreen
        case .requestApproved:
            iconView.image     = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .systemGreen
        case .requestDenied:
            iconView.image     = UIImage(systemName: "xmark.circle.fill")
            iconView.tintColor = .systemRed
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
            case .requestApproved, .passengerJoined:
                backgroundColor = UIColor.systemGreen.withAlphaComponent(0.05)
            case .requestDenied:
                backgroundColor = UIColor.systemRed.withAlphaComponent(0.05)
            default:
                backgroundColor = UIColor.systemOrange.withAlphaComponent(0.06)
            }
        }
    }
}
