import Foundation

struct Review: Codable, Identifiable {
    let id: UUID
    let rideID: UUID
    let reviewerID: UUID   // who gave the rating
    let revieweeID: UUID   // who received the rating
    let stars: Int         // 1–5
    let comment: String?
    let timestamp: Date
}
