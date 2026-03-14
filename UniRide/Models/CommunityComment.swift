// CommunityComment.swift
// UniRide
// Public model for a community post comment.

import Foundation

struct CommunityComment {
    let id: UUID
    let postID: UUID
    let authorUserID: UUID
    let text: String
    let createdAt: Date
}
