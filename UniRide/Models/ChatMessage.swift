import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let senderName: String
    let text: String
    let isCurrentUser: Bool
    let timestamp: Date
}
