//
//  File.swift
//  UniRide
//
//  Created by Air on 11/11/25.


import Foundation

// MARK: - Post Model
struct Post: Codable, Equatable {
    let id: UUID
    let authorUserID: UUID
    var text: String
    var imageURL: URL?
    let createdAt: Date

    // Counters
    var likeCount: Int
    var shareCount: Int
    var commentCount: Int

    init(authorUserID: UUID, text: String, imageURL: URL? = nil) {
        self.id = UUID()
        self.authorUserID = authorUserID
        self.text = text
        self.imageURL = imageURL
        self.createdAt = Date()
        self.likeCount = 0
        self.shareCount = 0
        self.commentCount = 0
    }

    static func == (lhs: Post, rhs: Post) -> Bool { lhs.id == rhs.id }
}

// MARK: - Like Model
struct Like: Codable, Equatable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    let createdAt: Date

    init(postID: UUID, userID: UUID) {
        self.id = UUID()
        self.postID = postID
        self.userID = userID
        self.createdAt = Date()
    }

    static func == (lhs: Like, rhs: Like) -> Bool { lhs.id == rhs.id }
}

// MARK: - Comment Model
struct Comment: Codable, Equatable {
    let id: UUID
    let postID: UUID
    let authorUserID: UUID
    var text: String
    let createdAt: Date
    var editedAt: Date?

    init(postID: UUID, authorUserID: UUID, text: String) {
        self.id = UUID()
        self.postID = postID
        self.authorUserID = authorUserID
        self.text = text
        self.createdAt = Date()
        self.editedAt = nil
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool { lhs.id == rhs.id }
}

// MARK: - Share Event Model
struct ShareEvent: Codable, Equatable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    let destination: String?
    let createdAt: Date

    init(postID: UUID, userID: UUID, destination: String? = nil) {
        self.id = UUID()
        self.postID = postID
        self.userID = userID
        self.destination = destination
        self.createdAt = Date()
    }

    static func == (lhs: ShareEvent, rhs: ShareEvent) -> Bool { lhs.id == rhs.id }
}

// MARK: - Community Data Manager
final class CommunityDataModel {

    static let shared = CommunityDataModel()

    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let postsURL: URL
    private let likesURL: URL
    private let commentsURL: URL
    private let sharesURL: URL

    private var posts: [Post] = []
    private var likes: [Like] = []
    private var comments: [Comment] = []
    private var shares: [ShareEvent] = []

    private init() {
        postsURL = documentsDirectory.appendingPathComponent("community_posts").appendingPathExtension("plist")
        likesURL = documentsDirectory.appendingPathComponent("community_likes").appendingPathExtension("plist")
        commentsURL = documentsDirectory.appendingPathComponent("community_comments").appendingPathExtension("plist")
        sharesURL = documentsDirectory.appendingPathComponent("community_shares").appendingPathExtension("plist")
        loadAll()
    }

    // MARK: - Post CRUD
    @discardableResult
    func createPost(authorUserID: UUID, text: String, imageURL: URL? = nil) -> Post {
        let post = Post(authorUserID: authorUserID, text: text, imageURL: imageURL)
        posts.append(post)
        savePosts()
        return post
    }

    func editPost(id: UUID, text: String? = nil, imageURL: URL? = nil) {
        guard let i = posts.firstIndex(where: { $0.id == id }) else { return }
        var post = posts[i]
        if let t = text { post.text = t }
        if let u = imageURL { post.imageURL = u }
        posts[i] = post
        savePosts()
    }

    func deletePost(id: UUID) {
        posts.removeAll { $0.id == id }
        likes.removeAll { $0.postID == id }
        comments.removeAll { $0.postID == id }
        shares.removeAll { $0.postID == id }
        savePosts(); saveLikes(); saveComments(); saveShares()
    }

    func getAllPosts() -> [Post] {
        posts.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Like CRUD
    func likePost(postID: UUID, userID: UUID) {
        guard !likes.contains(where: { $0.postID == postID && $0.userID == userID }),
              let i = posts.firstIndex(where: { $0.id == postID }) else { return }
        likes.append(Like(postID: postID, userID: userID))
        var post = posts[i]; post.likeCount += 1; posts[i] = post
        saveLikes(); savePosts()
    }

    func unlikePost(postID: UUID, userID: UUID) {
        guard let l = likes.firstIndex(where: { $0.postID == postID && $0.userID == userID }),
              let i = posts.firstIndex(where: { $0.id == postID }) else { return }
        likes.remove(at: l)
        var post = posts[i]; post.likeCount = max(0, post.likeCount - 1); posts[i] = post
        saveLikes(); savePosts()
    }

    // MARK: - Comment CRUD
    @discardableResult
    func addComment(postID: UUID, authorUserID: UUID, text: String) -> Comment {
        let comment = Comment(postID: postID, authorUserID: authorUserID, text: text)
        comments.append(comment)
        if let i = posts.firstIndex(where: { $0.id == postID }) {
            var post = posts[i]; post.commentCount += 1; posts[i] = post
            savePosts()
        }
        saveComments()
        return comment
    }

    func editComment(id: UUID, newText: String) {
        guard let i = comments.firstIndex(where: { $0.id == id }) else { return }
        var c = comments[i]; c.text = newText; c.editedAt = Date()
        comments[i] = c
        saveComments()
    }

    func deleteComment(id: UUID) {
        guard let i = comments.firstIndex(where: { $0.id == id }) else { return }
        let postID = comments[i].postID
        comments.remove(at: i)
        if let pi = posts.firstIndex(where: { $0.id == postID }) {
            var post = posts[pi]; post.commentCount = max(0, post.commentCount - 1); posts[pi] = post
            savePosts()
        }
        saveComments()
    }

    func getComments(for postID: UUID) -> [Comment] {
        comments.filter { $0.postID == postID }.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Share CRUD
    func sharePost(postID: UUID, userID: UUID, destination: String? = nil) {
        guard let i = posts.firstIndex(where: { $0.id == postID }) else { return }
        shares.append(ShareEvent(postID: postID, userID: userID, destination: destination))
        var post = posts[i]; post.shareCount += 1; posts[i] = post
        saveShares(); savePosts()
    }

    // MARK: - Persistence
    private func loadAll() {
        posts = load([Post].self, from: postsURL) ?? []
        likes = load([Like].self, from: likesURL) ?? []
        comments = load([Comment].self, from: commentsURL) ?? []
        shares = load([ShareEvent].self, from: sharesURL) ?? []
    }

    private func savePosts()    { save(posts, to: postsURL) }
    private func saveLikes()    { save(likes, to: likesURL) }
    private func saveComments() { save(comments, to: commentsURL) }
    private func saveShares()   { save(shares, to: sharesURL) }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let dec = PropertyListDecoder()
        return try? dec.decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        let enc = PropertyListEncoder()
        let data = try? enc.encode(value)
        try? data?.write(to: url, options: .noFileProtection)
    }
}

