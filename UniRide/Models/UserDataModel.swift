import Foundation

// Vehicle Types
enum VehicleType: String, Codable {
    case bike, car, other
}

// Vehicle Struct
struct Vehicle: Codable, Equatable {
    var type: VehicleType
    var model: String
    var registrationNumber: String
    var seats: Int
}

// User Profile Structure
struct UserProfile: Equatable, Codable {
    let id: UUID
    var email: String
    var isEmailVerified: Bool
    var phone: String?
    var isPhoneVerified: Bool
    var fullName: String
    var courseName: String?
    var year: Int?
    var photoURL: URL?
    var vehicle: Vehicle?

    init(email: String,
         isEmailVerified: Bool = false,
         phone: String? = nil,
         isPhoneVerified: Bool = false,
         fullName: String = "",
         courseName: String? = nil,
         year: Int? = nil,
         photoURL: URL? = nil,
         vehicle: Vehicle? = nil) {
        self.id = UUID()
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phone = phone
        self.isPhoneVerified = isPhoneVerified
        self.fullName = fullName
        self.courseName = courseName
        self.year = year
        self.photoURL = photoURL
        self.vehicle = vehicle
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
}

// Singleton Data Manager
final class UserDataModel {

    static let shared = UserDataModel()

    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    private var users: [UserProfile] = []
    private var currentUserID: UUID?

    private var emailOTPs: [String: String] = [:]
    private var phoneOTPs: [String: String] = [:]

    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("users").appendingPathExtension("json")
        loadUsers()
    }

    // FUNCTION CALLING IN THE EMAILVIEW CONTROLLER for storing the email and printing the otp
    func startEmailVerification(email raw: String) throws {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.hasSuffix("@chitkara.edu.in") || email.hasSuffix("@chitkarauniversity.edu.in") else {
            throw NSError(domain: "Login", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please use your Chitkara email only"])
        }
        let otp = String(Int.random(in: 1000...9999))
        emailOTPs[email] = otp
        print("DEBUG Email OTP for \(email): \(otp)")
    }

    // Function Verifying The otp. Called in the otp view controller
    func verifyEmailOTP(email: String, code: String) throws -> UserProfile {

        guard let sent = emailOTPs[email.lowercased()] else {
            throw NSError(domain: "Login", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No OTP found for this email"])
        }

        guard sent == code else {
            throw NSError(domain: "Login", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Incorrect OTP"])
        }

        if let existingUser = users.first(where: { $0.email == email.lowercased() }) {
            currentUserID = existingUser.id
            emailOTPs[email.lowercased()] = nil
            return existingUser
        }

        let newUser = UserProfile(email: email.lowercased(), isEmailVerified: true)
        users.append(newUser)
        currentUserID = newUser.id
        saveUsers()

        print("New user created:", newUser)

        emailOTPs[email.lowercased()] = nil

        return newUser
    }

    // PHONE VERIFICATION Function
    func startPhoneVerification(phone raw: String) throws {
        let phone = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count >= 10 else {
            throw NSError(domain: "Phone", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Enter a valid phone number"])
        }
        let otp = String(Int.random(in: 1000...9999))
        phoneOTPs[phone] = otp
        print("DEBUG Phone OTP for \(phone): \(otp)")
    }

    func verifyPhoneOTP(phone: String, code: String) throws {
        guard let sent = phoneOTPs[phone] else {
            throw NSError(domain: "Phone", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No OTP found for this phone number"])
        }
        guard sent == code else {
            throw NSError(domain: "Phone", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Incorrect OTP"])
        }
        guard let id = currentUserID, let idx = users.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Phone", code: 440,
                          userInfo: [NSLocalizedDescriptionKey: "No current user to update"])
        }

        var user = users[idx]
        user.phone = phone
        user.isPhoneVerified = true
        users[idx] = user
        saveUsers()
        phoneOTPs[phone] = nil
    }
    
    func createNewUser(fullName: String, course: String, year: Int, phone: String) {

        let newUser = UserProfile(
            email: "",
            isEmailVerified: true,
            phone: phone,
            isPhoneVerified: true,
            fullName: fullName,
            courseName: course,
            year: year,
            photoURL: nil,
            vehicle: nil
        )

        users.append(newUser)
        currentUserID = newUser.id
        saveUsers()

        print("New user created:", newUser)
    }

    // PROFILE CRUD
    func getCurrentUser() -> UserProfile? {
        guard let id = currentUserID else { return nil }
        return users.first(where: { $0.id == id })
    }

    func getUser(by id: UUID) -> UserProfile? {
        return users.first(where: { $0.id == id })
    }

    func editCurrentUser(
        fullName: String? = nil,
        courseName: String? = nil,
        year: Int? = nil,
        photoURL: URL? = nil,
        vehicle: Vehicle? = nil
    ) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        var user = users[index]
        if let n = fullName { user.fullName = n }
        if let c = courseName { user.courseName = c }
        if let y = year { user.year = y }
        if let p = photoURL { user.photoURL = p }
        if let v = vehicle { user.vehicle = v }

        users[index] = user
        saveUsers()
    }

    // ✅ ADDED: saveUserProfile (missing earlier)
    func saveUserProfile(_ updatedUser: UserProfile) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        users[index] = updatedUser
        saveUsers()
    }

    // LOGOUT Function
    func logout() {
        guard let id = currentUserID else { return }
        users.removeAll { $0.id == id }
        currentUserID = nil
        saveUsers()
    }

    private func loadUsers() {
        guard let data = try? Data(contentsOf: archiveURL) else {
            return
        }
        do {
            let decoder = JSONDecoder()
            users = try decoder.decode([UserProfile].self, from: data)
        } catch {
            print("Failed to load users.json:", error)
        }
    }

    private func saveUsers() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(users)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            print("Failed to save users.json:", error)
        }
    }
}

