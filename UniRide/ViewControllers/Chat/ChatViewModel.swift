import Foundation
import Combine

final class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []

    let rideID: String
    let rideTitle: String

    /// Other people in this ride chat (passengers + driver, minus current user)
    var participants: [UserProfile]

    private let currentUserID: String
    private let currentUserName: String

    private var cancellable: AnyCancellable?

    // MARK: - Init
    init(rideID: String, rideTitle: String, participants: [UserProfile] = []) {
        self.rideID        = rideID
        self.rideTitle     = rideTitle
        self.participants  = participants

        let me = UserDataModel.shared.getCurrentUser()
        self.currentUserID   = me?.id.uuidString ?? ""
        self.currentUserName = me?.fullName ?? "Me"

        load()
        subscribeToUpdates()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Load + Subscribe
    private func load() {
        messages = ChatDataModel.shared.messages(for: rideID)
        ChatDataModel.shared.markAsRead(rideID: rideID)
    }

    private func subscribeToUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdate(_:)),
            name: .chatMessagesUpdated,
            object: nil
        )
    }

    @objc private func handleUpdate(_ note: Notification) {
        guard let updated = note.object as? String, updated == rideID else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.messages = ChatDataModel.shared.messages(for: self.rideID)
            ChatDataModel.shared.markAsRead(rideID: self.rideID)
        }
    }

    // MARK: - Send
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let msg = ChatMessage(
            id: UUID(),
            senderID: currentUserID,
            senderName: currentUserName,
            text: trimmed,
            timestamp: Date()
        )
        ChatDataModel.shared.append(msg, to: rideID)
        messages.append(msg)

        scheduleAutoReply(after: trimmed)
    }

    // MARK: - Contextual Auto-Reply
    /// Simulates a reply from one of the real ride participants (not the current user).
    /// This makes the chat feel alive for a demo — in a real app this would be a push notification.
    private func scheduleAutoReply(after message: String) {
        let others = participants.filter { $0.id.uuidString != currentUserID }
        guard let responder = others.randomElement() else { return }

        // Only reply sometimes (70% of the time) to keep it natural
        guard Double.random(in: 0...1) < 0.70 else { return }

        let replies: [String]
        let lower = message.lowercased()

        if lower.contains("late") || lower.contains("wait") {
            replies = [
                "No worries, I can wait a couple minutes 🙂",
                "Ok, just let me know when you're on your way!",
                "Sure, I'll hold. Just please hurry 😅"
            ]
        } else if lower.contains("where") || lower.contains("location") {
            replies = [
                "I'm at the main gate, near the parking 📍",
                "Just outside the hostel block. Can you share your live location?",
                "I can see the building from here, coming to you!"
            ]
        } else if lower.contains("hi") || lower.contains("hello") || lower.contains("hey") {
            replies = [
                "Hey! 👋 See you at the pickup!",
                "Hi! All set for the ride 🚗",
                "Hello! Ready to go!"
            ]
        } else if lower.contains("thanks") || lower.contains("thank") {
            replies = ["You're welcome! 😊", "No problem at all!", "Anytime! 🙏"]
        } else {
            replies = [
                "Got it 👍",
                "Ok, noted!",
                "Sounds good!",
                "I'll be ready at the pickup point.",
                "✓ Acknowledged",
                "Perfect, see you soon!",
                "Running on time 🕐",
                "Cool, thanks for the heads up!",
                "Ok sure 👌",
                "On my way! 🏃"
            ]
        }

        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let reply = ChatMessage(
                id: UUID(),
                senderID: responder.id.uuidString,
                senderName: responder.fullName,
                text: replies.randomElement()!,
                timestamp: Date()
            )
            ChatDataModel.shared.append(reply, to: self.rideID)
            self.messages.append(reply)
        }
    }
}
