import Foundation
import UIKit

// Vehicle Types
enum VehicleType: String, Codable {
    case bike, car, other
}

// Vehicle Struct
struct Vehicle: Codable, Equatable {
    var alias: String? // e.g. "My Swift"
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
    var fullName: String
    var role: UserRole?
    var courseName: String? // This will be used as "Department"
    var year: Int?
    var employeeID: String?
    var photoURL: URL?
    var vehicles: [Vehicle]?

    var savedHomeLocation: LocationPoint?
    var savedHomeLocations: [LocationPoint]?
    var lastKnownLocation: LocationPoint?

    init(id: UUID,
         email: String,
         isEmailVerified: Bool = false,
         phone: String? = nil,
         fullName: String = "",
         role: UserRole? = nil,
         courseName: String? = nil,
         year: Int? = nil,
         employeeID: String? = nil,
         photoURL: URL? = nil,
         vehicles: [Vehicle]? = nil,
         savedHomeLocation: LocationPoint? = nil,
         savedHomeLocations: [LocationPoint]? = nil,
         lastKnownLocation: LocationPoint? = nil) {
        self.id = id
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phone = phone
        self.fullName = fullName
        self.role = role
        self.courseName = courseName
        self.year = year
        self.employeeID = employeeID
        self.photoURL = photoURL
        self.vehicles = vehicles
        self.savedHomeLocation = savedHomeLocation
        self.savedHomeLocations = savedHomeLocations
        self.lastKnownLocation = lastKnownLocation
    }


    init(email: String,
         isEmailVerified: Bool = false,
         phone: String? = nil,
         fullName: String = "",
         role: UserRole? = nil,
         courseName: String? = nil,
         year: Int? = nil,
         employeeID: String? = nil,
         photoURL: URL? = nil,
         vehicles: [Vehicle]? = nil,
         savedHomeLocation: LocationPoint? = nil,
         savedHomeLocations: [LocationPoint]? = nil,
         lastKnownLocation: LocationPoint? = nil) {
        self.id = UUID()
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phone = phone
        self.fullName = fullName
        self.role = role
        self.courseName = courseName
        self.year = year
        self.employeeID = employeeID
        self.photoURL = photoURL
        self.vehicles = vehicles
        self.savedHomeLocation = savedHomeLocation
        self.savedHomeLocations = savedHomeLocations
        self.lastKnownLocation = lastKnownLocation
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    /// Convenience initializer from Supabase row
    init?(row: [String: Any]) {
        guard let idStr = row["id"] as? String, let id = UUID(uuidString: idStr) else { return nil }
        
        self.id = id
        // `email` may be absent in joined profile rows (PostgREST foreign-key joins only return
        // columns from the `profiles` table, not `auth.users`). Fall back to empty string so
        // the init doesn't fail — display-only callers only need id, full_name and photo_url.
        self.email = row["email"] as? String ?? ""
        self.fullName = row["full_name"] as? String ?? ""
        self.isEmailVerified = row["is_email_verified"] as? Bool ?? false
        self.phone = row["phone"] as? String
        
        if let roleStr = row["role"] as? String {
            self.role = UserRole(rawValue: roleStr)
        } else {
            self.role = nil
        }
        
        self.courseName = row["course_name"] as? String
        self.year = row["year"] as? Int
        self.employeeID = row["employee_id"] as? String
        
        if let photoStr = row["photo_url"] as? String {
            self.photoURL = URL(string: photoStr)
        } else {
            self.photoURL = nil
        }
        
        self.vehicles = nil // Vehicles are in a separate table/join if needed
        self.savedHomeLocation = nil
        self.savedHomeLocations = nil
        self.lastKnownLocation = nil
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

        // Push to Supabase so it persists across sessions
        Task {
            do { try await pushProfileToSupabase(user) } catch {
                print("Home location sync failed:", error.localizedDescription)
            }
        }
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
        let hasHome = !(getHomeLocations(for: user.id).isEmpty)
        return hasName && hasRole && hasHome
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

        // Hydrate vehicles from user_vehicles table
        if let vehicles = try? await ProfileRepository.shared.fetchVehicles(userID: uid) {
            profile.vehicles = vehicles
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
        // Capture optional image from builder before it gets reset by the caller
        let imageToUpload = RegistrationBuilder.shared.profileImage

        // Use the Supabase auth UID if available
        let persisted: UserProfile
        if let authID = SessionManager.shared.userID, authID != profile.id {
            persisted = UserProfile(
                id: authID, email: profile.email, isEmailVerified: profile.isEmailVerified,
                phone: profile.phone,
                fullName: profile.fullName, role: profile.role, courseName: profile.courseName,
                year: profile.year, employeeID: profile.employeeID, photoURL: profile.photoURL,
                vehicles: profile.vehicles, savedHomeLocation: profile.savedHomeLocation,
                savedHomeLocations: profile.savedHomeLocations, lastKnownLocation: profile.lastKnownLocation)
        } else {
            persisted = profile
        }
        users.append(persisted)
        currentUserID = persisted.id
        saveUsers()

        // Persist to Supabase and handle photo upload if needed
        Task {
            var finalProfile = persisted

            if let img = imageToUpload, let data = img.jpegData(compressionQuality: 0.7) {
                do {
                    let urlStr = try await ProfileRepository.shared.uploadAvatar(userID: finalProfile.id, imageData: data)
                    if let url = URL(string: urlStr) {
                        finalProfile.photoURL = url
                        // Update local cache with URL immediately
                        await MainActor.run {
                            if let idx = self.users.firstIndex(where: { $0.id == finalProfile.id }) {
                                self.users[idx] = finalProfile
                                self.saveUsers()
                            }
                        }
                    }
                } catch {
                    print("Onboarding photo upload failed:", error.localizedDescription)
                }
            }

            do { try await pushProfileToSupabase(finalProfile) } catch {
                print("Profile upsert failed:", error.localizedDescription)
            }
        }
        print("New user registered (background upload started if photo present):", persisted)
    }

    func createNewUser(fullName: String, role: UserRole, department: String, year: Int?, phone: String) {

        let newUser = UserProfile(
            email: "",
            isEmailVerified: true,
            phone: phone,
            fullName: fullName,
            role: role,
            courseName: department,
            year: year,
            photoURL: nil,
            vehicles: nil
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

        if let vehicles = try? await ProfileRepository.shared.fetchVehicles(userID: uid) {
            profile.vehicles = vehicles
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

    /// Returns all locally cached user profiles.
    func allUsers() -> [UserProfile] {
        return users
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
        vehicles: [Vehicle]? = nil
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
        if let v = vehicles { user.vehicles = v }

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
    // MARK: - Ensure driver profiles exist (Legacy - now handled by Supabase joins)
    func ensureDriverProfiles(for driverIDs: [UUID]) {
        // No-op: We now rely on Supabase joins to bundle real profiles with rides/requests.
        // Generating random mock names here causes identity inconsistency across devices.
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
            fullName: remote.fullName ?? "",
            role: parsedRole,
            courseName: remote.courseName,
            year: remote.year,
            employeeID: remote.employeeID,
            photoURL: parsedPhotoURL,
            vehicles: remote.vehicle.map { [$0] },
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
        return UserProfile(
            id: uid, email: email, isEmailVerified: emailVerif,
            phone: phone, fullName: fullName,
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
            "is_email_verified": user.isEmailVerified
        ]
        if let v = user.phone        { fields["phone"]       = v }
        if let v = user.role         { fields["role"]        = v.rawValue }
        if let v = user.courseName   { fields["course_name"] = v }
        if let v = user.year         { fields["year"]        = v }
        if let v = user.employeeID   { fields["employee_id"] = v }
        if let v = user.photoURL     { fields["photo_url"]   = v.absoluteString }

        // BUG FIX: Sync last-known location to Supabase profiles table.
        // Previously these columns (last_known_lat/lon/address) were always NULL in Supabase.
        if let loc = user.lastKnownLocation {
            fields["last_known_lat"]     = loc.lat
            fields["last_known_lon"]     = loc.lon
            if let addr = loc.address {
                fields["last_known_address"] = addr
            }
        }

        try await ProfileRepository.shared.upsertProfile(fields)

        if let vehicles = user.vehicles {
            for v in vehicles {
                try await ProfileRepository.shared.upsertVehicle(userID: user.id, vehicle: v)
            }
        }

        // BUG FIX: Sync ALL saved home locations, not just the primary one.
        // Previously only user.savedHomeLocation (the first entry) was written, silently
        // dropping any additional locations the user had saved.
        let homes: [LocationPoint]
        if let all = user.savedHomeLocations, !all.isEmpty {
            homes = all
        } else if let single = user.savedHomeLocation {
            homes = [single]
        } else {
            homes = []
        }

        // Delete all old locations first to avoid duplicate lat/lon unique constraint issues
        try await ProfileRepository.shared.deleteHomeLocations(userID: user.id)

        for (index, loc) in homes.enumerated() {
            try await ProfileRepository.shared.upsertHomeLocation(
                userID: user.id,
                location: loc,
                isPrimary: index == 0
            )
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
                id: incoming.id,
                email: incoming.email,
                isEmailVerified: incoming.isEmailVerified,
                phone: incoming.phone,
                fullName: incoming.fullName,
                role: incoming.role,
                courseName: incoming.courseName,
                year: incoming.year,
                employeeID: incoming.employeeID,
                photoURL: incoming.photoURL,
                vehicles: incoming.vehicles,
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
