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

// User Role
enum UserRole: String, Codable {
    case student, faculty
}

// User Profile Structure
struct UserProfile: Equatable, Codable {
    let id: UUID
    var email: String
    var isEmailVerified: Bool
    var phone: String?
    var isPhoneVerified: Bool
    var fullName: String
    var role: UserRole?
    var courseName: String? // This will be used as "Department"
    var year: Int?
    var employeeID: String?
    var photoURL: URL?
    var vehicle: Vehicle?

    var savedHomeLocation: LocationPoint?
    var savedHomeLocations: [LocationPoint]?
    var lastKnownLocation: LocationPoint?

    init(id: UUID,
         email: String,
         isEmailVerified: Bool = false,
         phone: String? = nil,
         isPhoneVerified: Bool = false,
         fullName: String = "",
         role: UserRole? = nil,
         courseName: String? = nil,
         year: Int? = nil,
         employeeID: String? = nil,
         photoURL: URL? = nil,
         vehicle: Vehicle? = nil,
         savedHomeLocation: LocationPoint? = nil,
         savedHomeLocations: [LocationPoint]? = nil,
         lastKnownLocation: LocationPoint? = nil) {
        self.id = id
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phone = phone
        self.isPhoneVerified = isPhoneVerified
        self.fullName = fullName
        self.role = role
        self.courseName = courseName
        self.year = year
        self.employeeID = employeeID
        self.photoURL = photoURL
        self.vehicle = vehicle
        self.savedHomeLocation = savedHomeLocation
        self.savedHomeLocations = savedHomeLocations
        self.lastKnownLocation = lastKnownLocation
    }


    init(email: String,
         isEmailVerified: Bool = false,
         phone: String? = nil,
         isPhoneVerified: Bool = false,
         fullName: String = "",
         role: UserRole? = nil,
         courseName: String? = nil,
         year: Int? = nil,
         employeeID: String? = nil,
         photoURL: URL? = nil,
         vehicle: Vehicle? = nil,
         savedHomeLocation: LocationPoint? = nil,
         savedHomeLocations: [LocationPoint]? = nil,
         lastKnownLocation: LocationPoint? = nil) {
        self.id = UUID()
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phone = phone
        self.isPhoneVerified = isPhoneVerified
        self.fullName = fullName
        self.role = role
        self.courseName = courseName
        self.year = year
        self.employeeID = employeeID
        self.photoURL = photoURL
        self.vehicle = vehicle
        self.savedHomeLocation = savedHomeLocation
        self.savedHomeLocations = savedHomeLocations
        self.lastKnownLocation = lastKnownLocation
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
    private let campusLocation = LocationPoint(
        lat: 30.5163,
        lon: 76.6598,
        address: "Chitkara University"
    )

    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("users").appendingPathExtension("json")
        loadUsers()
        seedMockUsersIfNeeded()
    }
    func updateUserLocation(_ location: LocationPoint) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        var user = users[index]
        user.lastKnownLocation = location
        users[index] = user
        saveUsers()
    }

    func getCampusLocation() -> LocationPoint {
        campusLocation
    }

    func getHomeLocations(for userID: UUID? = nil) -> [LocationPoint] {
        let user = (userID == nil) ? getCurrentUser() : users.first(where: { $0.id == userID })
        guard let user else { return [] }

        var homes = user.savedHomeLocations ?? []
        if homes.isEmpty, let single = user.savedHomeLocation {
            homes = [single]
        }
        return Array(homes.prefix(3))
    }

    func setHomeLocations(_ locations: [LocationPoint]) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        var user = users[index]
        let trimmed = Array(locations.prefix(3))
        user.savedHomeLocations = trimmed
        user.savedHomeLocation = trimmed.first
        users[index] = user
        saveUsers()
    }

    func preferredHomeLocation() -> LocationPoint? {
        guard let user = getCurrentUser() else { return nil }
        let homes = getHomeLocations(for: user.id)
        guard !homes.isEmpty else { return nil }

        guard let live = user.lastKnownLocation else {
            return homes.first
        }

        return homes.min(by: { distanceMeters($0, live) < distanceMeters($1, live) })
    }

    func isProfileSetupComplete(for user: UserProfile) -> Bool {
        let hasName = !user.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRole = user.role != nil
        let hasPhone = !(user.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasHome = !(getHomeLocations(for: user.id).isEmpty)
        return hasName && hasRole && hasPhone && hasHome
    }

    func suggestedCommutePrefill() -> (from: LocationPoint, to: LocationPoint)? {
        guard let user = getCurrentUser(),
              let home = preferredHomeLocation() else { return nil }

        let campus = campusLocation
        guard let live = user.lastKnownLocation else {
            return (from: campus, to: home)
        }

        if distanceMeters(live, campus) <= 1500 {
            return (from: campus, to: home)
        } else if distanceMeters(live, home) <= 3000 {
            return (from: home, to: campus)
        } else {
            return (from: campus, to: home)
        }
    }

    private func distanceMeters(_ a: LocationPoint, _ b: LocationPoint) -> Double {
        let dx = (a.lon - b.lon) * 111_320 * cos((a.lat + b.lat) * 0.5 * .pi / 180)
        let dy = (a.lat - b.lat) * 110_540
        return sqrt(dx * dx + dy * dy)
    }

    // FUNCTION CALLING IN THE EMAILVIEW CONTROLLER for storing the email and printing the otp
    func startEmailVerification(email raw: String) throws {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.hasSuffix("@chitkara.edu.in") || email.hasSuffix("@chitkarauniversity.edu.in") else {
            throw NSError(domain: "Login", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please use your Chitkara email only"])
        }
        let otp = String(Int.random(in: 100000...999999))
        emailOTPs[email] = otp
        print("DEBUG Email OTP for \(email): \(otp)")
    }

    func startEmailVerificationAsync(email raw: String) async throws {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.hasSuffix("@chitkara.edu.in") || email.hasSuffix("@chitkarauniversity.edu.in") else {
            throw NSError(domain: "Login", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please use your Chitkara email only"])
        }

        if BackendConfig.useRealBackend {
            try await AuthAPI.shared.startEmailVerification(email: email)
            return
        }

        try startEmailVerification(email: email)
    }

    // Function Verifying The otp. Called in the otp view controller
    func verifyEmailOTP(email: String, code: String) throws -> UserProfile? {
        guard let sent = emailOTPs[email.lowercased()] else {
            throw NSError(domain: "Login", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No OTP found for this email"])
        }

        guard sent == code else {
            throw NSError(domain: "Login", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Incorrect OTP"])
        }

        emailOTPs[email.lowercased()] = nil

        // If it's a returning user, log them in. 
        if let existingUser = users.first(where: { $0.email == email.lowercased() }) {
            currentUserID = existingUser.id
            return existingUser
        }

        // Return nil to indicate this is a new user who must continue onboarding
        return nil
    }

    func verifyEmailOTPAsync(email rawEmail: String, code: String) async throws -> UserProfile? {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if BackendConfig.useRealBackend {
            let response = try await AuthAPI.shared.verifyEmailOTP(email: email, code: code)
            guard response.existingUser else { return nil }

            if let remote = response.user {
                let remoteProfile = mapRemoteUserToProfile(remote, fallbackEmail: email)
                return upsertAndLogin(remoteProfile)
            }

            if let existing = users.first(where: { $0.email == email }) {
                currentUserID = existing.id
                return existing
            }
            return nil
        }

        return try verifyEmailOTP(email: email, code: code)
    }

    func registerNewUser(profile: UserProfile) {
        let persisted = withBackendIdentity(profile)
        users.append(persisted)
        currentUserID = persisted.id
        saveUsers()
        if BackendConfig.useRealBackend {
            Task {
                do {
                    try await AuthAPI.shared.upsertCurrentUserProfile(persisted)
                } catch {
                    print("Profile upsert failed:", error.localizedDescription)
                }
            }
        }
        print("New user completely registered:", persisted)
    }

    // PHONE VERIFICATION Function
    func startPhoneVerification(phone raw: String) throws {
        let phone = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count >= 10 else {
            throw NSError(domain: "Phone", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Enter a valid phone number"])
        }
        let otp = BackendConfig.devFixedPhoneOTP ?? String(Int.random(in: 100000...999999))
        phoneOTPs[phone] = otp
        print("DEBUG Phone OTP for \(phone): \(otp)")
    }

    func startPhoneVerificationAsync(phone raw: String) async throws {
        let phone = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count >= 10 else {
            throw NSError(domain: "Phone", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Enter a valid phone number"])
        }

        if BackendConfig.devFixedPhoneOTP != nil {
            try startPhoneVerification(phone: phone)
            return
        }

        if BackendConfig.useRealBackend {
            try await AuthAPI.shared.startPhoneVerification(phone: phone)
            return
        }

        try startPhoneVerification(phone: phone)
    }

    func verifyPhoneOTP(phone: String, code: String) throws -> Bool {
        guard let sent = phoneOTPs[phone] else {
            throw NSError(domain: "Login", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No OTP found for this phone number"])
        }

        guard sent == code else {
            throw NSError(domain: "Login", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Incorrect OTP"])
        }

        phoneOTPs[phone] = nil
        
        // If a user is already logged in (e.g. they are adding a phone to an existing account)
        if let currentUserID = self.currentUserID,
           let index = users.firstIndex(where: { $0.id == currentUserID }) {
            var user = users[index]
            user.phone = phone
            user.isPhoneVerified = true
            users[index] = user
            saveUsers()
            return true
        }
        
        // Return true to indicate the phone OTP was valid for the builder flow
        return true
    }

    func verifyPhoneOTPAsync(phone rawPhone: String, code: String) async throws -> Bool {
        let phone = rawPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        if BackendConfig.devFixedPhoneOTP != nil {
            return try verifyPhoneOTP(phone: phone, code: code)
        }
        if BackendConfig.useRealBackend {
            return try await AuthAPI.shared.verifyPhoneOTP(phone: phone, code: code)
        }
        return try verifyPhoneOTP(phone: phone, code: code)
    }
    
    func createNewUser(fullName: String, role: UserRole, department: String, year: Int?, phone: String) {

        let newUser = UserProfile(
            email: "",
            isEmailVerified: true,
            phone: phone,
            isPhoneVerified: true,
            fullName: fullName,
            role: role,
            courseName: department,
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

    func userExists(email: String) -> Bool {
        return users.contains(where: { $0.email.lowercased() == email.lowercased() })
    }

    func editCurrentUser(
        fullName: String? = nil,
        role: UserRole? = nil,
        courseName: String? = nil,
        year: Int? = nil,
        employeeID: String? = nil,
        photoURL: URL? = nil,
        vehicle: Vehicle? = nil
    ) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        var user = users[index]
        if let n = fullName { user.fullName = n }
        if let r = role { user.role = r }
        if let c = courseName { user.courseName = c }
        if let y = year { user.year = y }
        if let e = employeeID { user.employeeID = e }
        if let p = photoURL { user.photoURL = p }
        if let v = vehicle { user.vehicle = v }

        users[index] = user
        saveUsers()
        if BackendConfig.useRealBackend {
            Task {
                do {
                    try await AuthAPI.shared.upsertCurrentUserProfile(user)
                } catch {
                    print("Profile upsert failed:", error.localizedDescription)
                }
            }
        }
    }

    // saveUserProfile (missing earlier)
    func saveUserProfile(_ updatedUser: UserProfile) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        users[index] = updatedUser
        saveUsers()
        if BackendConfig.useRealBackend {
            Task {
                do {
                    try await AuthAPI.shared.upsertCurrentUserProfile(updatedUser)
                } catch {
                    print("Profile upsert failed:", error.localizedDescription)
                }
            }
        }
    }

    // LOGOUT Function
    func logout() {
        currentUserID = nil
        SessionStore.shared.accessToken = nil
        SessionStore.shared.authUserID = nil
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
    
    // TEMP - debug only
    func allUsersForDebugging() -> [(id: String, name: String, email: String?)] {
        return users.map { (id: $0.id.uuidString, name: $0.fullName, email: (Mirror(reflecting: $0).children.first(where: { $0.label == "email" })?.value as? String)) }
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

    // MARK: - Ensure driver profiles exist for ride owners
    func ensureDriverProfiles(for driverIDs: [UUID]) {
        let existing = Set(users.map { $0.id })
        var added = 0

        for id in driverIDs where !existing.contains(id) {
            let idx = abs(id.uuidString.hashValue) % MockData.driverNames.count
            let name = MockData.driverNames[idx]
            let profile = UserProfile(
                id: id,
                email: "driver\(idx + 1)@chitkara.edu.in",
                isEmailVerified: true,
                fullName: name,
                role: .student,
                courseName: "CSE",
                year: 3
            )
            users.append(profile)
            added += 1
        }

        if added > 0 {
            saveUsers()
        }
    }

    // MARK: - Mock Users
    private static let mockUsersSeedKey = "mock_users_seeded"

    private func seedMockUsersIfNeeded() {
        let seeded = UserDefaults.standard.bool(forKey: UserDataModel.mockUsersSeedKey)
        let mockIDs = Set(MockData.driverProfiles.map { $0.id })
        let hasAnyMock = users.contains { mockIDs.contains($0.id) }
        if seeded && hasAnyMock { return }

        for profile in MockData.driverProfiles {
            if users.contains(where: { $0.id == profile.id }) { continue }
            users.append(profile)
        }

        saveUsers()
        UserDefaults.standard.set(true, forKey: UserDataModel.mockUsersSeedKey)
    }

    private func mapRemoteUserToProfile(_ remote: AuthRemoteUser, fallbackEmail: String) -> UserProfile {
        let parsedID = remote.id.flatMap(UUID.init(uuidString:))
        let parsedRole = remote.role.flatMap(UserRole.init(rawValue:))
        let parsedPhotoURL = remote.photoURL.flatMap(URL.init(string:))

        return UserProfile(
            id: parsedID ?? UUID(),
            email: remote.email.isEmpty ? fallbackEmail : remote.email.lowercased(),
            isEmailVerified: remote.isEmailVerified ?? true,
            phone: remote.phone,
            isPhoneVerified: remote.isPhoneVerified ?? false,
            fullName: remote.fullName ?? "",
            role: parsedRole,
            courseName: remote.courseName,
            year: remote.year,
            employeeID: remote.employeeID,
            photoURL: parsedPhotoURL,
            vehicle: remote.vehicle,
            savedHomeLocation: remote.savedHomeLocation,
            savedHomeLocations: remote.savedHomeLocations,
            lastKnownLocation: nil
        )
    }

    private func withBackendIdentity(_ profile: UserProfile) -> UserProfile {
        guard BackendConfig.useRealBackend,
              let backendID = AuthAPI.shared.currentAuthUserID() else {
            return profile
        }

        return UserProfile(
            id: backendID,
            email: profile.email,
            isEmailVerified: profile.isEmailVerified,
            phone: profile.phone,
            isPhoneVerified: profile.isPhoneVerified,
            fullName: profile.fullName,
            role: profile.role,
            courseName: profile.courseName,
            year: profile.year,
            employeeID: profile.employeeID,
            photoURL: profile.photoURL,
            vehicle: profile.vehicle,
            savedHomeLocation: profile.savedHomeLocation,
            savedHomeLocations: profile.savedHomeLocations,
            lastKnownLocation: profile.lastKnownLocation
        )
    }

    private func upsertAndLogin(_ incoming: UserProfile) -> UserProfile {
        if let idx = users.firstIndex(where: { $0.id == incoming.id }) {
            users[idx] = incoming
            currentUserID = incoming.id
            saveUsers()
            return incoming
        }

        if let idx = users.firstIndex(where: { $0.email == incoming.email }) {
            let existingID = users[idx].id
            let merged = UserProfile(
                id: existingID,
                email: incoming.email,
                isEmailVerified: incoming.isEmailVerified,
                phone: incoming.phone,
                isPhoneVerified: incoming.isPhoneVerified,
                fullName: incoming.fullName,
                role: incoming.role,
                courseName: incoming.courseName,
                year: incoming.year,
                employeeID: incoming.employeeID,
                photoURL: incoming.photoURL,
                vehicle: incoming.vehicle,
                savedHomeLocation: incoming.savedHomeLocation,
                savedHomeLocations: incoming.savedHomeLocations,
                lastKnownLocation: incoming.lastKnownLocation
            )
            users[idx] = merged
            currentUserID = merged.id
            saveUsers()
            return merged
        }

        users.append(incoming)
        currentUserID = incoming.id
        saveUsers()
        return incoming
    }
}
