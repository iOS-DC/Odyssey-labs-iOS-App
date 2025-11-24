//
//  ProfileDataModel.swift
//  UniRide
//
//  Created by Student on 24/11/25.
//

import Foundation
class ProfileDataModel {

    static let shared = ProfileDataModel()

    private let documentsDirectory =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    private let profileURL: URL

    // IMPORTANT: change UserProfile → UserProfileUI
    private(set) var profile: UserProfileUI?

    private init() {
        profileURL = documentsDirectory
            .appendingPathComponent("userProfile")
            .appendingPathExtension("plist")

        loadProfile()

        if profile == nil {
            loadSampleProfile()
        }
    }

    // MARK: - Public Functions
    func getProfile() -> UserProfileUI? {
        return profile
    }

    func saveProfile(_ updatedProfile: UserProfileUI) {
        self.profile = updatedProfile
        saveToFile()
    }

    func deleteProfile() {
        profile = nil
        try? FileManager.default.removeItem(at: profileURL)
    }

    // MARK: - Load / Save
    private func loadProfile() {
        guard let data = try? Data(contentsOf: profileURL) else { return }
        let decoder = PropertyListDecoder()
        profile = try? decoder.decode(UserProfileUI.self, from: data)
    }

    private func saveToFile() {
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(profile) {
            try? data.write(to: profileURL, options: .noFileProtection)
        }
    }

    // MARK: - Sample Data
    private func loadSampleProfile() {
        profile = UserProfileUI(
            fullName: "Jagpreet Singh",
            department: "Computer Science Engineering",
            year: "3rd Year",
            memberSince: "September 2022",
            rating: 4.8,
            totalRides: 47,
            profileImage: "profile1",
            email: "jagpreet1936.b323@chitkara.edu.in",
            phone: "+91 9868359586"
        )

        saveToFile()
    }
}
