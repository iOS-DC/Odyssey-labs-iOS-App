import UIKit

final class EventAdminDashboardViewController: UIViewController {

    // MARK: - State

    private enum AdminSegment: Int { case events = 0, trips = 1 }
    private var segment: AdminSegment = .events

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let segControl = UISegmentedControl(items: ["Events", "Trips"])
    private var events: [EventItem] = []
    private var trips: [Trip] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Admin Dashboard"
        view.backgroundColor = AppDesign.Color.groupedBackground
        configureNavigation()
        configureSegmentControl()
        configureTableView()
        reloadData()
        refreshFromBackend()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    // MARK: - Setup

    private func configureNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
    }

    private func configureSegmentControl() {
        segControl.selectedSegmentIndex = 0
        segControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segControl.translatesAutoresizingMaskIntoConstraints = false

        let header = UIView()
        header.backgroundColor = AppDesign.Color.groupedBackground
        header.addSubview(segControl)
        NSLayoutConstraint.activate([
            segControl.topAnchor.constraint(equalTo: header.topAnchor, constant: AppDesign.Spacing.sm),
            segControl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: AppDesign.Spacing.md),
            segControl.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -AppDesign.Spacing.md),
            segControl.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -AppDesign.Spacing.sm)
        ])
        header.frame = CGRect(x: 0, y: 0, width: 0, height: 52)
        tableView.tableHeaderView = header
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppDesign.Color.groupedBackground
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminItemCell.self, forCellReuseIdentifier: AdminItemCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data

    private func reloadData() {
        events = EventDataModel.shared.eventList().sorted { $0.startsAt < $1.startsAt }
        trips = TripDataModel.shared.trips.sorted { $0.startDate < $1.startDate }
        tableView.reloadData()
        let isEmpty = segment == .events ? events.isEmpty : trips.isEmpty
        tableView.backgroundView = isEmpty ? emptyState() : nil
    }

    private func refreshFromBackend() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let remoteEvents = try? await EventsAPI.shared.fetchTopEvents(limit: 50), !remoteEvents.isEmpty {
                EventDataModel.shared.replaceEventsFromBackend(remoteEvents)
            }
            if let remoteTrips = try? await TripsAPI.shared.fetchTrips(), !remoteTrips.isEmpty {
                TripDataModel.shared.replaceTripsFromBackend(remoteTrips)
            }
            self.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        segment = AdminSegment(rawValue: segControl.selectedSegmentIndex) ?? .events
        reloadData()
    }

    @objc private func addTapped() {
        switch segment {
        case .events:
            let editor = EventEditorViewController()
            editor.onSave = { [weak self] in self?.reloadData() }
            navigationController?.pushViewController(editor, animated: true)
        case .trips:
            let editor = TripEditorViewController()
            editor.onSave = { [weak self] in self?.reloadData() }
            navigationController?.pushViewController(editor, animated: true)
        }
    }

    @objc private func logoutTapped() {
        EventAdminSession.shared.logout()
        SceneDelegate.setRootToAuth()
    }

    private func emptyState() -> UIView {
        switch segment {
        case .events:
            let empty = EmptyStateView(
                systemImage: "calendar.badge.plus",
                title: "No events yet",
                body: "Create the first campus event and publish it for students.",
                actionTitle: "Create Event",
                tintColor: AppDesign.Color.primary
            )
            empty.onAction = { [weak self] in self?.addTapped() }
            return empty
        case .trips:
            let empty = EmptyStateView(
                systemImage: "map.fill",
                title: "No trips yet",
                body: "Post the first community trip for students to join.",
                actionTitle: "Add Trip",
                tintColor: AppDesign.Color.primary
            )
            empty.onAction = { [weak self] in self?.addTapped() }
            return empty
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension EventAdminDashboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segment == .events ? events.count : trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AdminItemCell.reuseID, for: indexPath) as! AdminItemCell
        switch segment {
        case .events:
            let event = events[indexPath.row]
            let fmt = DateFormatter(); fmt.dateStyle = .medium; fmt.timeStyle = .short
            cell.configure(
                title: event.title,
                meta: "\(fmt.string(from: event.startsAt)) · \(event.location?.name ?? "Campus")",
                detail: event.details?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "No description"
            )
        case .trips:
            let trip = trips[indexPath.row]
            cell.configure(
                title: trip.title,
                meta: "\(trip.dateRange) · \(trip.location)",
                detail: "\(trip.priceFormatted) · \(trip.spotsLeft) spot\(trip.spotsLeft == 1 ? "" : "s") left"
            )
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch segment {
        case .events:
            let editor = EventEditorViewController(event: events[indexPath.row])
            editor.onSave = { [weak self] in self?.reloadData() }
            navigationController?.pushViewController(editor, animated: true)
        case .trips:
            let editor = TripEditorViewController(trip: trips[indexPath.row])
            editor.onSave = { [weak self] in self?.reloadData() }
            navigationController?.pushViewController(editor, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, finish in
            guard let self else { finish(false); return }
            switch self.segment {
            case .events:
                let event = self.events[indexPath.row]
                EventDataModel.shared.deleteEvent(id: event.id)
                Task { try? await EventsAPI.shared.deleteEvent(eventID: event.id) }
            case .trips:
                let trip = self.trips[indexPath.row]
                TripDataModel.shared.deleteTrip(id: trip.id)
                Task { try? await TripsAPI.shared.deleteTrip(tripID: trip.id) }
            }
            self.reloadData()
            finish(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Shared Cell

private final class AdminItemCell: UITableViewCell {
    static let reuseID = "AdminItemCell"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        card.applyCardStyle(corner: AppDesign.Radius.lg)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong, lines: 2)
        metaLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel, lines: 1)
        detailLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel, lines: 2)

        let inner = UIStackView(arrangedSubviews: [titleLabel, metaLabel, detailLabel])
        inner.axis = .vertical
        inner.spacing = AppDesign.Spacing.xs
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppDesign.Spacing.xs),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDesign.Spacing.md),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDesign.Spacing.md),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppDesign.Spacing.xs),
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: AppDesign.Spacing.md),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.md),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.md)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, meta: String, detail: String) {
        titleLabel.text = title
        metaLabel.text = meta
        detailLabel.text = detail
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
