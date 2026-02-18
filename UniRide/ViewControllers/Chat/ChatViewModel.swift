import Foundation
import Combine

final class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []

    let rideID: String
    let rideTitle: String

    private let currentUserName: String

    init(rideID: String, rideTitle: String) {
        self.rideID = rideID
        self.rideTitle = rideTitle
        self.currentUserName = UserDataModel.shared.getCurrentUser()?.fullName ?? "You"
        seedDemoMessages()
    }

    // MARK: - Public API

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let msg = ChatMessage(
            id: UUID(),
            senderName: currentUserName,
            text: trimmed,
            isCurrentUser: true,
            timestamp: Date()
        )
        messages.append(msg)
    }

    func simulateReply() {
        let replies = [
            "Sounds good! See you then 👋",
            "I'll be at the pickup point on time.",
            "Can we leave 5 minutes earlier?",
            "Thanks for the update!",
            "Perfect, I'm ready 🚗"
        ]
        let senders = ["Alex M.", "Priya K.", "Jordan T."]

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            let reply = ChatMessage(
                id: UUID(),
                senderName: senders.randomElement()!,
                text: replies.randomElement()!,
                isCurrentUser: false,
                timestamp: Date()
            )
            self.messages.append(reply)
        }
    }

    // MARK: - Private

    private func seedDemoMessages() {
        let now = Date()
        let seed: [ChatMessage] = [
            ChatMessage(
                id: UUID(),
                senderName: "Alex M.",
                text: "Hey everyone! Ready for tomorrow's ride? 🚗",
                isCurrentUser: false,
                timestamp: now.addingTimeInterval(-3600)
            ),
            ChatMessage(
                id: UUID(),
                senderName: "Priya K.",
                text: "Yes! What time are we meeting at the pickup point?",
                isCurrentUser: false,
                timestamp: now.addingTimeInterval(-3000)
            ),
            ChatMessage(
                id: UUID(),
                senderName: currentUserName,
                text: "I'll be there 5 minutes early. See you all! 👍",
                isCurrentUser: true,
                timestamp: now.addingTimeInterval(-2400)
            )
        ]
        messages = seed
    }
}
