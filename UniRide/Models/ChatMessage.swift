import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let senderID: String        // UserProfile.id.uuidString
    let senderName: String
    let text: String
    let timestamp: Date

    // Computed — not stored — so each user sees their own messages on the right
    var isCurrentUser: Bool {
        senderID == (UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "")
    }
}
