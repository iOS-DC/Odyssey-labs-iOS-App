import Foundation

/// A global registry that maintains the current authoritative counts for post interactions.
/// This acts as the "global variable" storage to ensure no matter where a post is displayed,
/// it shows the most up-to-date counts.
final class PostRegistry {
    static let shared = PostRegistry()
    private init() {}

    private var commentCounts: [UUID: Int] = [:]
    private var likeCounts: [UUID: Int] = [:]
    private var shareCounts: [UUID: Int] = [:]
    
    private let queue = DispatchQueue(label: "com.uniride.postregistry", attributes: .concurrent)

    func updateCommentCount(for postID: UUID, to newCount: Int) {
        queue.async(flags: .barrier) {
            let old = self.commentCounts[postID]
            self.commentCounts[postID] = newCount
            
            if old != newCount {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .CommunityCommentDidUpdate,
                        object: nil,
                        userInfo: ["postID": postID, "newCount": newCount]
                    )
                }
            }
        }
    }

    func getCommentCount(for postID: UUID?) -> Int? {
        guard let id = postID else { return nil }
        var count: Int?
        queue.sync {
            count = commentCounts[id]
        }
        return count
    }

    func updateLikeCount(for postID: UUID, to newCount: Int) {
        queue.async(flags: .barrier) {
            self.likeCounts[postID] = newCount
        }
    }

    func getLikeCount(for postID: UUID?) -> Int? {
        guard let id = postID else { return nil }
        var count: Int?
        queue.sync {
            count = likeCounts[id]
        }
        return count
    }

    func updateShareCount(for postID: UUID, to newCount: Int) {
        queue.async(flags: .barrier) {
            self.shareCounts[postID] = newCount
        }
    }

    func getShareCount(for postID: UUID?) -> Int? {
        guard let id = postID else { return nil }
        var count: Int?
        queue.sync {
            count = shareCounts[id]
        }
        return count
    }
}
