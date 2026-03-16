import Foundation
import UIKit

/// A singleton builder object used to temporarily store user data while navigating
/// through the onboarding flow. Once all screens are complete, `buildUser()` is called
/// to safely assemble the final UserProfile that gets committed to the system in one go.
final class RegistrationBuilder {
    static let shared = RegistrationBuilder()

    var email: String?
    var isEmailVerified: Bool = false
    var phone: String?
    var role: UserRole?

    var fullName: String?
    var courseName: String?
    var year: Int?
    var employeeID: String?

    var vehicle: Vehicle?
    var homeLocation: LocationPoint?
    var profileImage: UIImage?

    private init() {}

    /// Restores the builder to a blank state if the user cancels or restarts registration
    func reset() {
        email = nil
        isEmailVerified = false
        phone = nil
        role = nil
        fullName = nil
        courseName = nil
        year = nil
        employeeID = nil
        vehicle = nil
        homeLocation = nil
        profileImage = nil
    }

    /// Assembles the final `UserProfile` and ensures required fields exist.
    /// - Returns: A `UserProfile` if the builder has the minimum required data.
    func buildUser() throws -> UserProfile {
        guard let email = email, isEmailVerified else {
            throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email verification required."])
        }
        guard let role = role else {
            throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please select a role."])
        }
        guard let fullName = fullName, !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Full name is required."])
        }
        guard let home = homeLocation else {
            throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Home location is required."])
        }

        if role == .student {
            guard let course = courseName, !course.isEmpty else {
                throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Course is required for students."])
            }
            guard let _ = year else {
                throw NSError(domain: "Registration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Year is required for students."])
            }
        }

        return UserProfile(
            email: email,
            isEmailVerified: isEmailVerified,
            phone: phone,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            courseName: courseName,
            year: year,
            employeeID: employeeID,
            photoURL: nil,
            vehicles: vehicle.map { [$0] },
            savedHomeLocation: homeLocation,
            savedHomeLocations: [home],
            lastKnownLocation: nil
        )
    }
}
