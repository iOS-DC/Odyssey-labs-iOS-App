import UIKit

final class LiveNotificationService {
    static let shared = LiveNotificationService()

    private let realtimeClient = SupabaseRealtimeClient()
    private var currentUserID: UUID?
    private var channel: RealtimeChannel?
    private var lastPresentedNotificationID: UUID?
    private var pendingAlerts: [(id: UUID, title: String, body: String)] = []
    private var isPresentingAlert = false
    private var knownNotificationIDs: Set<UUID> = []
    private var pollTimer: Timer?

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
        presentNextAlertIfPossible()
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
                                "title": notif.title,
                                "body": notif.body
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
        pendingAlerts.append((id: notificationID, title: title, body: body))
        presentNextAlertIfPossible()
    }

    private func presentNextAlertIfPossible() {
        guard UIApplication.shared.applicationState == .active else { return }
        guard !isPresentingAlert else { return }
        guard let topVC = UIApplication.shared.topViewController() else { return }
        guard !(topVC is UIAlertController) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.presentNextAlertIfPossible()
            }
            return
        }
        guard !pendingAlerts.isEmpty else { return }

        let next = pendingAlerts.removeFirst()
        isPresentingAlert = true
        lastPresentedNotificationID = next.id

        let alert = UIAlertController(title: next.title, message: next.body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            self.isPresentingAlert = false
            self.presentNextAlertIfPossible()
        })
        topVC.present(alert, animated: true)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
