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
        case passengerCancelled  // passenger cancelled a confirmed booking → driver sees it
        case passengerJoined     // passenger request approved (legacy, kept for compat)
        case requestApproved     // driver approved passenger's join request → passenger sees it
        case requestDenied       // driver denied passenger's join request → passenger sees it
        case newRequest          // passenger requested to join → driver sees it
        case rideCancelled       // driver cancelled the entire ride → all passengers see it
        case bookingCancelledByHost // driver cancelled a specific booking → passenger sees it
        case ridePublished       // driver successfully offered a ride → driver sees it
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
        notifications.insert(notif, at: 0)   // newest first
        save()
        NotificationCenter.default.post(name: .appNotificationsUpdated, object: nil)
    }

    // MARK: - Read
    func unread(for userID: UUID) -> [AppNotification] {
        notifications.filter { $0.recipientUserID == userID && !$0.isRead }
    }

    func unreadCount(for userID: UUID) -> Int {
        unread(for: userID).count
    }

    func markAllRead(for userID: UUID) {
        for i in notifications.indices where
            notifications[i].recipientUserID == userID && !notifications[i].isRead {
            notifications[i].isRead = true
        }
        save()
        NotificationCenter.default.post(name: .appNotificationsUpdated, object: nil)
    }
}
