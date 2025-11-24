//
//  UserProfileUI.swift
//  UniRide
//
//  Created by Student on 24/11/25.
//

import Foundation
struct UserProfileUI: Equatable, Codable {
    let id: UUID
    var fullName: String
    var department: String
    var year: String
    var memberSince: String
    var rating: Double
    var totalRides: Int
    var profileImage: String?

    var email: String
    var phone: String

    init(fullName: String,
         department: String,
         year: String,
         memberSince: String,
         rating: Double,
         totalRides: Int,
         profileImage: String? = nil,
         email: String,
         phone: String) {

        self.id = UUID()
        self.fullName = fullName
        self.department = department
        self.year = year
        self.memberSince = memberSince
        self.rating = rating
        self.totalRides = totalRides
        self.profileImage = profileImage
        self.email = email
        self.phone = phone
    }

    static func == (lhs: UserProfileUI, rhs: UserProfileUI) -> Bool {
        lhs.id == rhs.id
    }
}
