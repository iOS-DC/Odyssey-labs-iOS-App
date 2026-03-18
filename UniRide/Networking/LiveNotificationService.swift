import UIKit

final class LiveNotificationService {
    static let shared = LiveNotificationService()

    private let realtimeClient = SupabaseRealtimeClient()
    private var currentUserID: UUID?
    private var channel: RealtimeChannel?
    private var lastPresentedNotificationID: UUID?
    private var pendingAlerts: [(id: UUID, rideID: UUID?, title: String, body: String, type: AppNotification.NotifType?)] = []
    private var isPresentingAlert = false
    private var knownNotificationIDs: Set<UUID> = []
    private var pollTimer: Timer?
    private var bannerView: NotificationBannerView?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidUpdate),
            name: Notification.Name("SessionUpdated"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogout),
            name: Notification.Name("UserLoggedOut"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        startIfPossible()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func sessionDidUpdate() {
        startIfPossible()
    }

    @objc private func userDidLogout() {
        stop()
    }

    @objc private func appDidBecomeActive() {
        startPolling()
        presentNextBannerIfPossible()
        Task { await fetchLatestNotifications(showPopups: true) }
    }

    @objc private func appWillResignActive() {
        stopPolling()
    }

    func startIfPossible() {
        guard SessionManager.shared.isLoggedIn, let userID = SessionManager.shared.userID else { return }
        guard currentUserID != userID else { return }

        stop()
        currentUserID = userID

        let topic = "public:app_notifications:user_id=eq.\(userID.uuidString)"
        let channel = realtimeClient.channel(topic)
        channel.on("INSERT") { [weak self] record in
            self?.handleInsert(record)
        }

        realtimeClient.connect()
        channel.subscribe()
        self.channel = channel

        Task {
            await fetchLatestNotifications(showPopups: false)
        }

        if UIApplication.shared.applicationState == .active {
            startPolling()
        }
    }

    func stop() {
        realtimeClient.disconnect()
        stopPolling()
        channel = nil
        currentUserID = nil
        knownNotificationIDs.removeAll()
    }

    private func handleInsert(_ record: [String: Any]) {
        guard
            let idString = record["id"] as? String,
            let notificationID = UUID(uuidString: idString),
            notificationID != lastPresentedNotificationID
        else {
            AppNotificationModel.shared.receiveRealtime(record)
            return
        }

        AppNotificationModel.shared.receiveRealtime(record)
        knownNotificationIDs.insert(notificationID)
        enqueueAlert(record: record, notificationID: notificationID)
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { await self?.fetchLatestNotifications(showPopups: true) }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func fetchLatestNotifications(showPopups: Bool) async {
        guard let userID = currentUserID else { return }
        do {
            let rows = try await NotificationAndReviewRepository.shared.fetchNotifications(userID: userID)
            let parsed = rows.compactMap { AppNotificationModel.shared.notification(from: $0) }
            let previouslyKnown = await MainActor.run { knownNotificationIDs }

            for notif in parsed {
                await MainActor.run {
                    AppNotificationModel.shared.receiveRealtime([
                        "id": notif.id.uuidString,
                        "user_id": notif.recipientUserID.uuidString,
                        "ride_id": notif.rideID?.uuidString as Any,
                        "title": notif.title,
                        "body": notif.body,
                        "notif_type": notif.type.rawValue,
                        "is_read": notif.isRead,
                        "created_at": ISO8601DateFormatter().string(from: notif.timestamp)
                    ])
                    knownNotificationIDs.insert(notif.id)
                }
                if showPopups && !previouslyKnown.contains(notif.id) && !notif.isRead {
                    await MainActor.run {
                        enqueueAlert(
                            record: [
                                "id": notif.id.uuidString,
                                "ride_id": notif.rideID?.uuidString as Any,
                                "title": notif.title,
                                "body": notif.body,
                                "notif_type": notif.type.rawValue
                            ],
                            notificationID: notif.id
                        )
                    }
                }
            }
        } catch {
            print("[LiveNotificationService] Poll fetch failed:", error.localizedDescription)
        }
    }

    private func enqueueAlert(record: [String: Any], notificationID: UUID) {
        let title = record["title"] as? String ?? "Notification"
        let body = record["body"] as? String ?? ""
        let type = (record["notif_type"] as? String).flatMap(AppNotification.NotifType.init(rawValue:))
        let rideID = (record["ride_id"] as? String).flatMap(UUID.init(uuidString:))
        pendingAlerts.append((id: notificationID, rideID: rideID, title: title, body: body, type: type))
        presentNextBannerIfPossible()
    }

    private func presentNextBannerIfPossible() {
        guard UIApplication.shared.applicationState == .active else { return }
        guard let topVC = UIApplication.shared.topViewController() else { return }
        guard !isPresentingAlert else { return }
        guard !pendingAlerts.isEmpty else { return }
        guard bannerView == nil else { return }

        let next = pendingAlerts.removeFirst()
        isPresentingAlert = true
        lastPresentedNotificationID = next.id

        let banner = NotificationBannerView(
            title: next.title,
            body: next.body,
            showsViewAction: next.type != nil
        )
        banner.onTap = { [weak self] in
            guard let self else { return }
            self.dismissBanner {
                self.handleNotificationTap(type: next.type, rideID: next.rideID)
            }
        }
        banner.onClose = { [weak self] in
            self?.dismissBanner()
        }

        topVC.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: topVC.view.leadingAnchor, constant: 12),
            banner.trailingAnchor.constraint(equalTo: topVC.view.trailingAnchor, constant: -12),
            banner.topAnchor.constraint(equalTo: topVC.view.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])

        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: -12)
        bannerView = banner
        UIView.animate(withDuration: 0.25) {
            banner.alpha = 1
            banner.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self, self.bannerView === banner else { return }
            self.dismissBanner()
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func dismissBanner(completion: (() -> Void)? = nil) {
        guard let banner = bannerView else {
            isPresentingAlert = false
            completion?()
            presentNextBannerIfPossible()
            return
        }

        UIView.animate(withDuration: 0.2, animations: {
            banner.alpha = 0
            banner.transform = CGAffineTransform(translationX: 0, y: -12)
        }, completion: { [weak self] _ in
            guard let self else { return }
            banner.removeFromSuperview()
            if self.bannerView === banner {
                self.bannerView = nil
            }
            self.isPresentingAlert = false
            completion?()
            self.presentNextBannerIfPossible()
        })
    }

    private func handleNotificationTap(type: AppNotification.NotifType?, rideID: UUID?) {
        guard let type else { return }
        guard let tabBar = resolveMainTabBarController() else { return }
        tabBar.selectedIndex = 1

        guard let me = UserDataModel.shared.getCurrentUser() else { return }

        switch type {
        case .newRequest:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard let myRidesVC = self.resolveMyRidesViewController(from: tabBar) else { return }
                myRidesVC.syncFromBackend {
                    let pendingTrip = RideDataModel.shared.myUpcoming(userID: me.id).first {
                        $0.role == .hosting &&
                        $0.ride.id == rideID
                    } ?? RideDataModel.shared.myUpcoming(userID: me.id).first {
                        $0.role == .hosting &&
                        RideDataModel.shared.listRequests(for: $0.ride.id).contains(where: { $0.status == .pending })
                    }
                    guard let pendingTrip else { return }

                    let vc = DriverRequestsViewController(trip: pendingTrip)
                    let nav = UINavigationController(rootViewController: vc)
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                        sheet.prefersGrabberVisible = true
                        sheet.preferredCornerRadius = 24
                    }
                    myRidesVC.present(nav, animated: true)
                }
            }
        case .requestApproved, .requestDenied, .passengerCancelled, .rideCreated, .rideCancelled, .rideStarted, .rideCompleted, .passengerJoined:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.resolveMyRidesViewController(from: tabBar)?.syncFromBackend()
            }
        }
    }

    private func resolveMainTabBarController() -> UITabBarController? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let root = scene.windows.first?.rootViewController else { return nil }

        if let tb = root as? UITabBarController { return tb }
        if let nav = root as? UINavigationController {
            if let tb = nav.viewControllers.first as? UITabBarController { return tb }
            if let tb = nav.topViewController as? UITabBarController { return tb }
        }
        return nil
    }

    private func resolveMyRidesViewController(from tabBar: UITabBarController) -> MyRidesViewController? {
        guard tabBar.viewControllers?.indices.contains(1) == true else { return nil }
        let vc = tabBar.viewControllers?[1]

        if let myRidesVC = vc as? MyRidesViewController {
            myRidesVC.loadViewIfNeeded()
            return myRidesVC
        }

        if let nav = vc as? UINavigationController {
            let myRidesVC = (nav.topViewController ?? nav.viewControllers.first) as? MyRidesViewController
            myRidesVC?.loadViewIfNeeded()
            return myRidesVC
        }

        return nil
    }
}

private final class NotificationBannerView: UIView {
    var onTap: (() -> Void)?
    var onClose: (() -> Void)?

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let actionLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    init(title: String, body: String, showsViewAction: Bool) {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
        isUserInteractionEnabled = true

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

        actionLabel.text = showsViewAction ? "Tap to view" : "New notification"
        actionLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        actionLabel.textColor = AppDesign.Color.primary

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, actionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            textStack.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() {
        onTap?()
    }

    @objc private func closeTapped() {
        onClose?()
    }
}
