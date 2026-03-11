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
        // Always use Supabase Auth OTP
        try await AuthService.shared.sendEmailOTP(email: email)
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

        // Always verify via Supabase Auth
        try await AuthService.shared.verifyEmailOTP(email: email, token: code)

        // Session is now stored. Try to fetch existing profile from Supabase.
        guard let uid = SessionManager.shared.userID else { return nil }

        // fetchProfile returns [String:Any]? — try? makes it [String:Any]??
        // Flatten both Optional layers: nil outer = network error, nil inner = no row
        let fetchedRow = try? await ProfileRepository.shared.fetchProfile(userID: uid)
        guard let row = fetchedRow ?? nil, !row.isEmpty else {
            // No profile row yet — brand new user, continue onboarding
            return nil
        }

        // Build local profile from the Supabase row
        var profile = profileFromRow(row, fallbackEmail: email, uid: uid)

        // Hydrate vehicle from user_vehicles table
        if let vehicle = try? await ProfileRepository.shared.fetchVehicle(userID: uid) {
            profile.vehicle = vehicle
        }

        // Hydrate home locations from home_locations table
        let homes = (try? await ProfileRepository.shared.fetchHomeLocations(userID: uid)) ?? []
        if !homes.isEmpty {
            profile.savedHomeLocations = homes
            profile.savedHomeLocation  = homes.first
        }

        return upsertAndLogin(profile)
    }

    func registerNewUser(profile: UserProfile) {
        // Use the Supabase auth UID if available
        let persisted: UserProfile
        if let authID = SessionManager.shared.userID, authID != profile.id {
            persisted = UserProfile(
                id: authID, email: profile.email, isEmailVerified: profile.isEmailVerified,
                phone: profile.phone, isPhoneVerified: profile.isPhoneVerified,
                fullName: profile.fullName, role: profile.role, courseName: profile.courseName,
                year: profile.year, employeeID: profile.employeeID, photoURL: profile.photoURL,
                vehicle: profile.vehicle, savedHomeLocation: profile.savedHomeLocation,
                savedHomeLocations: profile.savedHomeLocations, lastKnownLocation: profile.lastKnownLocation)
        } else {
            persisted = profile
        }
        users.append(persisted)
        currentUserID = persisted.id
        saveUsers()
        // Persist to Supabase
        Task {
            do { try await pushProfileToSupabase(persisted) } catch {
                print("Profile upsert failed:", error.localizedDescription)
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

    /// Called on app relaunch when a saved session exists.
    /// Restores currentUserID from SessionManager and re-fetches the profile
    /// from Supabase so the UI always shows up-to-date data.
    func restoreSessionUser() async {
        guard let uid = SessionManager.shared.userID else { return }

        // Immediately restore in-memory currentUserID so getCurrentUser() works
        // even if the network call below is slow.
        await MainActor.run { self.currentUserID = uid }

        // Re-fetch from Supabase to pick up any changes made on other devices
        // fetchProfile returns [String:Any]? so try? gives [String:Any]??  — flatten with ?? nil
        let fetched = (try? await ProfileRepository.shared.fetchProfile(userID: uid)) ?? nil
        guard let row = fetched, !row.isEmpty else { return }

        var profile = profileFromRow(row, fallbackEmail: SessionManager.shared.userEmail ?? "", uid: uid)

        if let vehicle = try? await ProfileRepository.shared.fetchVehicle(userID: uid) {
            profile.vehicle = vehicle
        }
        let homes = (try? await ProfileRepository.shared.fetchHomeLocations(userID: uid)) ?? []
        if !homes.isEmpty {
            profile.savedHomeLocations = homes
            profile.savedHomeLocation  = homes.first
        }

        await MainActor.run { _ = self.upsertAndLogin(profile) }
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
        Task {
            do { try await pushProfileToSupabase(user) } catch {
                print("Profile upsert failed:", error.localizedDescription)
            }
        }
    }

    // saveUserProfile (missing earlier)
    func saveUserProfile(_ updatedUser: UserProfile) {
        guard let id = currentUserID,
              let index = users.firstIndex(where: { $0.id == id }) else { return }

        users[index] = updatedUser
        saveUsers()
        Task {
            do { try await pushProfileToSupabase(updatedUser) } catch {
                print("Profile upsert failed:", error.localizedDescription)
            }
        }
    }

    // LOGOUT Function
    func logout() {
        currentUserID = nil
        SessionManager.shared.clear()
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

    // MARK: - Supabase profile helpers

    /// Build a UserProfile from a Supabase `profiles` row dictionary.
    func profileFromRow(_ row: [String: Any], fallbackEmail: String, uid: UUID) -> UserProfile {
        let email       = (row["email"] as? String) ?? fallbackEmail
        let fullName    = (row["full_name"] as? String) ?? ""
        let phone       = row["phone"] as? String
        let role        = (row["role"] as? String).flatMap(UserRole.init(rawValue:))
        let courseName  = row["course_name"] as? String
        let year        = row["year"] as? Int
        let employeeID  = row["employee_id"] as? String
        let photoURL    = (row["photo_url"] as? String).flatMap(URL.init(string:))
        let emailVerif  = (row["is_email_verified"] as? Bool) ?? true
        let phoneVerif  = (row["is_phone_verified"] as? Bool) ?? false
        return UserProfile(
            id: uid, email: email, isEmailVerified: emailVerif,
            phone: phone, isPhoneVerified: phoneVerif, fullName: fullName,
            role: role, courseName: courseName, year: year, employeeID: employeeID,
            photoURL: photoURL)
    }

    /// Push the current UserProfile to Supabase `profiles` (and `user_vehicles` if needed).
    func pushProfileToSupabase(_ user: UserProfile) async throws {
        guard SessionManager.shared.isLoggedIn else { return }
        var fields: [String: Any] = [
            "id":                user.id.uuidString,
            "email":             user.email,
            "full_name":         user.fullName,
            "is_email_verified": user.isEmailVerified,
            "is_phone_verified": user.isPhoneVerified
        ]
        if let v = user.phone        { fields["phone"]       = v }
        if let v = user.role         { fields["role"]        = v.rawValue }
        if let v = user.courseName   { fields["course_name"] = v }
        if let v = user.year         { fields["year"]        = v }
        if let v = user.employeeID   { fields["employee_id"] = v }
        if let v = user.photoURL     { fields["photo_url"]   = v.absoluteString }
        try await ProfileRepository.shared.upsertProfile(fields)

        if let vehicle = user.vehicle {
            try await ProfileRepository.shared.upsertVehicle(userID: user.id, vehicle: vehicle)
        }
        if let home = user.savedHomeLocation {
            try await ProfileRepository.shared.upsertHomeLocation(userID: user.id, location: home, isPrimary: true)
        }
    }

    private func upsertAndLogin(_ incoming: UserProfile) -> UserProfile {
        if let idx = users.firstIndex(where: { $0.id == incoming.id }) {
            users[idx] = incoming
            currentUserID = incoming.id
            saveUsers()
            return incoming
        }

        // Same email but different local ID — merge, always keep the Supabase UUID
        if let idx = users.firstIndex(where: { $0.email == incoming.email }) {
            let merged = UserProfile(
                id: incoming.id,           // always use the Supabase auth UUID
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
