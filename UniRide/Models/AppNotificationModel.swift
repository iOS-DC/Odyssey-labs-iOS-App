import Foundation

// MARK: - Model

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let recipientUserID: UUID
    let title: String
    let body: String
    let timestamp: Date
    var isRead: Bool
    let type: NotifType

    enum NotifType: String, Codable {
        case newRequest          // a new passenger request arrived for the driver
        case passengerCancelled  // passenger cancelled a confirmed booking → driver sees it
        case passengerJoined     // passenger request approved (legacy, kept for compat)
        case requestApproved     // driver approved passenger's join request → passenger sees it
        case requestDenied       // driver denied passenger's join request → passenger sees it
        case rideCreated         // driver created/published a ride
        case rideCancelled       // host cancelled the ride
        case rideStarted         // host started the ride
        case rideCompleted       // host completed the ride
    }
}

// MARK: - Singleton

extension Notification.Name {
    static let appNotificationsUpdated = Notification.Name("appNotificationsUpdated")
}

final class AppNotificationModel {
    static let shared = AppNotificationModel()
    private init() { load() }

    private(set) var notifications: [AppNotification] = []

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("app_notifications.json")
    }

    // MARK: - Persistence
    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([AppNotification].self, from: data)
        else { return }
        notifications = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func insertLocal(_ notif: AppNotification) {
        guard !notifications.contains(where: { $0.id == notif.id }) else { return }
        notifications.insert(notif, at: 0)
        notifications.sort { $0.timestamp > $1.timestamp }
        save()
        NotificationCenter.default.post(name: .appNotificationsUpdated, object: nil)
    }

    private func mergeRemote(_ incoming: [AppNotification]) {
        guard !incoming.isEmpty else { return }
        var changed = false
        for notif in incoming {
            if let idx = notifications.firstIndex(where: { $0.id == notif.id }) {
                if notifications[idx].isRead != notif.isRead {
                    notifications[idx] = notif
                    changed = true
                }
            } else {
                notifications.append(notif)
                changed = true
            }
        }
        guard changed else { return }
        notifications.sort { $0.timestamp > $1.timestamp }
        save()
        NotificationCenter.default.post(name: .appNotificationsUpdated, object: nil)
    }

    func notification(from raw: [String: Any]) -> AppNotification? {
        guard
            let idString = raw["id"] as? String,
            let id = UUID(uuidString: idString),
            let userIDString = raw["user_id"] as? String,
            let userID = UUID(uuidString: userIDString),
            let title = raw["title"] as? String,
            let body = raw["body"] as? String,
            let typeString = raw["notif_type"] as? String,
            let type = AppNotification.NotifType(rawValue: typeString)
        else {
            return nil
        }

        let timestamp: Date
        if let createdAt = raw["created_at"] as? String,
           let parsed = ISO8601DateFormatter().date(from: createdAt) {
            timestamp = parsed
        } else {
            timestamp = Date()
        }

        let isRead = raw["is_read"] as? Bool ?? false
        return AppNotification(
            id: id,
            recipientUserID: userID,
            title: title,
            body: body,
            timestamp: timestamp,
            isRead: isRead,
            type: type
        )
    }

    // MARK: - Write
    func send(to recipientID: UUID, title: String, body: String, type: AppNotification.NotifType) {
        let notif = AppNotification(
            id: UUID(),
            recipientUserID: recipientID,
            title: title,
            body: body,
            timestamp: Date(),
            isRead: false,
            type: type
        )
        insertLocal(notif)

        guard SessionManager.shared.userID == recipientID else { return }

        Task {
            try? await NotificationAndReviewRepository.shared.insertNotification(
                id: notif.id,
                userID: recipientID,
                title: title,
                body: body,
                type: type.rawValue,
                isRead: false,
                createdAt: notif.timestamp
            )
        }
    }

    func refreshFromBackend(for userID: UUID) async {
        guard SessionManager.shared.isLoggedIn else { return }
        do {
            let rows = try await NotificationAndReviewRepository.shared.fetchNotifications(userID: userID)
            let parsed = rows.compactMap(notification(from:))
            DispatchQueue.main.async { [weak self] in
                self?.mergeRemote(parsed)
            }
        } catch {
            print("[AppNotificationModel] Failed to fetch notifications:", error.localizedDescription)
        }
    }

    func receiveRealtime(_ raw: [String: Any]) {
        guard let notif = notification(from: raw) else { return }
        insertLocal(notif)
    }

    // MARK: - Read
    func all(for userID: UUID) -> [AppNotification] {
        notifications.filter { $0.recipientUserID == userID }
    }

    func unread(for userID: UUID) -> [AppNotification] {
        all(for: userID).filter { !$0.isRead }
    }

    func unreadCount(for userID: UUID) -> Int {
        unread(for: userID).count
    }

    func markAllRead(for userID: UUID) {
        let unreadIDs = notifications
            .filter { $0.recipientUserID == userID && !$0.isRead }
            .map(\.id)
        for i in notifications.indices where
            notifications[i].recipientUserID == userID && !notifications[i].isRead {
            notifications[i].isRead = true
        }
        save()
        NotificationCenter.default.post(name: .appNotificationsUpdated, object: nil)

        guard SessionManager.shared.isLoggedIn, !unreadIDs.isEmpty else { return }
        Task {
            for id in unreadIDs {
                try? await NotificationAndReviewRepository.shared.markNotificationRead(id: id)
            }
        }
    }
}
