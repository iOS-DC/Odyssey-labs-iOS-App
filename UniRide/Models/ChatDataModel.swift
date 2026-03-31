import Foundation

// Notification fired whenever a new message is added to any ride chat.
// `object` is the rideID string.
extension Notification.Name {
    static let chatMessagesUpdated = Notification.Name("chatMessagesUpdated")
}

// MARK: - ChatDataModel
/// Singleton that persists messages per ride to Documents/chat_<rideID>.json
final class ChatDataModel {

    static let shared = ChatDataModel()
    private init() {}

    private let docs = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask)[0]

    // MARK: - Read
    func messages(for rideID: String) -> [ChatMessage] {
        let url = fileURL(for: rideID)
        guard
            let data = try? Data(contentsOf: url),
            let msgs = try? JSONDecoder().decode([ChatMessage].self, from: data)
        else { return [] }
        return msgs
    }

    // MARK: - Write
    func save(_ messages: [ChatMessage], for rideID: String) {
        let url = fileURL(for: rideID)
        if let data = try? JSONEncoder().encode(messages) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func append(_ message: ChatMessage, to rideID: String) {
        var current = messages(for: rideID)
        // Deduplicate by ID
        guard !current.contains(where: { $0.id == message.id }) else { return }
        
        current.append(message)
        save(current, for: rideID)
        NotificationCenter.default.post(
            name: .chatMessagesUpdated,
            object: rideID
        )
    }

    /// Appends multiple messages with deduplication and a single notification.
    func appendContents(of newMessages: [ChatMessage], to rideID: String) {
        var current = messages(for: rideID)
        let existingIDs = Set(current.map { $0.id })
        
        let filtered = newMessages.filter { !existingIDs.contains($0.id) }
        guard !filtered.isEmpty else { return }
        
        current.append(contentsOf: filtered)
        // Sort by timestamp to ensure chronological order after merging remote/local
        current.sort { $0.timestamp < $1.timestamp }
        
        save(current, for: rideID)
        NotificationCenter.default.post(
            name: .chatMessagesUpdated,
            object: rideID
        )
    }

    // MARK: - Unread count
    func unreadCount(for rideID: String) -> Int {
        let lastRead = lastReadDate(for: rideID)
        let currentUserID = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? ""
        return messages(for: rideID).filter {
            $0.senderID != currentUserID && $0.timestamp > lastRead
        }.count
    }

    func markAsRead(rideID: String) {
        UserDefaults.standard.set(Date(), forKey: readKey(rideID))
    }

    private func lastReadDate(for rideID: String) -> Date {
        return UserDefaults.standard.object(forKey: readKey(rideID)) as? Date ?? .distantPast
    }

    private func readKey(_ rideID: String) -> String { "chat_read_\(rideID)" }

    // MARK: - Welcome message
    /// Called once when a ride is first created. Seeds a friendly opener from the driver.
    func seedWelcomeIfNeeded(ride: Ride, driverName: String) {
        let rideID = ride.id.uuidString
        guard messages(for: rideID).isEmpty else { return }

        let from = ride.source.address ?? "origin"
        let to   = ride.destination.address ?? "destination"

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeStr = formatter.string(from: ride.departureTime)

        let welcome = ChatMessage(
            id: UUID(),
            senderID: ride.driverUserID.uuidString,
            senderName: driverName,
            text: "👋 Hey! I'm your driver for \(from) → \(to) at \(timeStr). Feel free to coordinate here. See you at the pickup! 🚗",
            timestamp: Date().addingTimeInterval(-60)   // 1 min ago
        )
        save([welcome], for: rideID)
    }

    // MARK: - Helpers
    private func fileURL(for rideID: String) -> URL {
        docs.appendingPathComponent("chat_\(rideID).json")
    }
}
