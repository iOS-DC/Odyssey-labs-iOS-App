import UIKit

final class LiveNotificationService {
    static let shared = LiveNotificationService()

    private let realtimeClient = SupabaseRealtimeClient()
    private var currentUserID: UUID?
    private var channel: RealtimeChannel?
    private var lastPresentedNotificationID: UUID?

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
            await AppNotificationModel.shared.refreshFromBackend(for: userID)
        }
    }

    func stop() {
        realtimeClient.disconnect()
        channel = nil
        currentUserID = nil
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
        presentAlertIfNeeded(record: record, notificationID: notificationID)
    }

    private func presentAlertIfNeeded(record: [String: Any], notificationID: UUID) {
        guard UIApplication.shared.applicationState == .active else { return }
        guard let topVC = UIApplication.shared.topViewController() else { return }
        guard !(topVC is UIAlertController) else { return }

        let title = record["title"] as? String ?? "Notification"
        let body = record["body"] as? String ?? ""
        lastPresentedNotificationID = notificationID

        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC.present(alert, animated: true)
    }
}
