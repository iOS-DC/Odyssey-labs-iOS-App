import Foundation

private struct SupabaseOTPStartRequest: Encodable {
    let email: String?
    let phone: String?
    let createUser: Bool
    let channel: String?

    enum CodingKeys: String, CodingKey {
        case email
        case phone
        case createUser = "create_user"
        case channel
    }
}

private struct SupabaseEmailVerifyRequest: Encodable {
    let email: String
    let token: String
    let type: String
}

private struct SupabasePhoneVerifyRequest: Encodable {
    let phone: String
    let token: String
    let type: String
}

private struct SupabaseAuthSessionResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let user: SupabaseAuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

private struct SupabaseAuthUser: Decodable {
    let id: String
    let email: String?
    let phone: String?
    let emailConfirmedAt: String?
    let phoneConfirmedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case emailConfirmedAt = "email_confirmed_at"
        case phoneConfirmedAt = "phone_confirmed_at"
    }
}

private struct SupabaseProfileRecord: Decodable {
    let id: String
    let email: String?
    let phone: String?
    let isEmailVerified: Bool?
    let fullName: String?
    let role: String?
    let courseName: String?
    let year: Int?
    let employeeID: String?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case isEmailVerified = "is_email_verified"
        case fullName = "full_name"
        case role
        case courseName = "course_name"
        case year
        case employeeID = "employee_id"
        case photoURL = "photo_url"
    }
}

private struct SupabaseProfileUpsertRequest: Encodable {
    let id: String
    let email: String
    let phone: String?
    let isEmailVerified: Bool
    let fullName: String
    let role: String?
    let courseName: String?
    let year: Int?
    let employeeID: String?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case isEmailVerified = "is_email_verified"
        case fullName = "full_name"
        case role
        case courseName = "course_name"
        case year
        case employeeID = "employee_id"
        case photoURL = "photo_url"
    }
}

private struct SupabaseHomeLocationRow: Codable {
    let userID: String
    let label: String?
    let lat: Double
    let lon: Double
    let address: String?
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case label
        case lat
        case lon
        case address
        case isPrimary = "is_primary"
    }
}

private struct SupabaseVehicleRow: Codable {
    let userID: String
    let type: String
    let model: String
    let registrationNumber: String
    let seats: Int

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case type
        case model
        case registrationNumber = "registration_number"
        case seats
    }
}

private struct CurrentProfileSnapshot {
    let profile: SupabaseProfileRecord?
    let homeLocations: [SupabaseHomeLocationRow]
    let vehicle: SupabaseVehicleRow?
}

struct AuthVerifyEmailResponse: Decodable {
    let existingUser: Bool
    let user: AuthRemoteUser?
    let accessToken: String?
}

struct AuthRemoteUser: Decodable {
    let id: String?
    let email: String
    let phone: String?
    let isEmailVerified: Bool?
    let fullName: String?
    let role: String?
    let courseName: String?
    let year: Int?
    let employeeID: String?
    let photoURL: String?
    let savedHomeLocation: LocationPoint?
    let savedHomeLocations: [LocationPoint]?
    let vehicle: Vehicle?
}

final class AuthAPI {
    static let shared = AuthAPI()

    private let client: APIClient
    private let sessionStore: SessionStore

    init(client: APIClient = .shared, sessionStore: SessionStore = .shared) {
        self.client = client
        self.sessionStore = sessionStore
    }

    func startEmailVerification(email: String) async throws {
        let body = try client.encodeBody(
            SupabaseOTPStartRequest(
                email: email,
                phone: nil,
                createUser: true,
                channel: nil
            )
        )
        let endpoint = APIEndpoint(path: "/auth/v1/otp", method: "POST", body: body)
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func verifyEmailOTP(email: String, code: String) async throws -> AuthVerifyEmailResponse {
        let response = try await verifyEmailOTPWithFallback(email: email, code: code)

        // BUG FIX: Save the full session (including refresh_token) into SessionManager
        // so BOTH the old (RideRepository) and new (RidesAPI) networking layers share one token.
        if let at = response.accessToken, !at.isEmpty,
           let rt = response.refreshToken, !rt.isEmpty,
           let userIDStr = response.user?.id, !userIDStr.isEmpty,
           let uid = UUID(uuidString: userIDStr) {
            let userEmail = response.user?.email
            SessionManager.shared.save(
                accessToken: at,
                refreshToken: rt,
                userID: uid,
                email: userEmail,
                expiresAt: nil,
                preserveLoginDate: false
            )
        } else if let token = response.accessToken, !token.isEmpty {
            // Partial response — at minimum keep the access token alive
            sessionStore.accessToken = token
        }
        if let userID = response.user?.id, !userID.isEmpty {
            sessionStore.authUserID = userID
        }
        guard sessionStore.accessToken != nil else {
            throw NSError(
                domain: "Auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Could not create an authenticated session from OTP. Please request OTP again."]
            )
        }

        let snapshot = try await fetchCurrentProfileSnapshot(userID: response.user?.id)
        let mapped = mapAuthToRemoteUser(authUser: response.user, snapshot: snapshot, fallbackEmail: email)
        let hasCompletedProfile = hasCompleteProfile(snapshot)

        return AuthVerifyEmailResponse(
            existingUser: hasCompletedProfile,
            user: mapped,
            accessToken: response.accessToken
        )
    }

    func startPhoneVerification(phone: String) async throws {
        let body = try client.encodeBody(
            SupabaseOTPStartRequest(
                email: nil,
                phone: phone,
                createUser: false,
                channel: "sms"
            )
        )
        let endpoint = APIEndpoint(path: "/auth/v1/otp", method: "POST", body: body)
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    func verifyPhoneOTP(phone: String, code: String) async throws -> Bool {
        let body = try client.encodeBody(SupabasePhoneVerifyRequest(phone: phone, token: code, type: "sms"))
        let endpoint = APIEndpoint(path: "/auth/v1/verify", method: "POST", body: body)
        let response: SupabaseAuthSessionResponse = try await client.send(endpoint, as: SupabaseAuthSessionResponse.self)

        if let token = response.accessToken, !token.isEmpty {
            sessionStore.accessToken = token
        }
        if let userID = response.user?.id, !userID.isEmpty {
            sessionStore.authUserID = userID
        }

        return response.user?.phoneConfirmedAt != nil || response.accessToken != nil
    }

    func upsertCurrentUserProfile(_ profile: UserProfile) async throws {
        guard let userID = effectiveAuthUserID(localProfileID: profile.id) else { return }

        let payload = SupabaseProfileUpsertRequest(
            id: userID.uuidString.lowercased(),
            email: profile.email.lowercased(),
            phone: profile.phone,
            isEmailVerified: profile.isEmailVerified,
            fullName: profile.fullName,
            role: profile.role?.rawValue,
            courseName: profile.courseName,
            year: profile.year,
            employeeID: profile.employeeID,
            photoURL: profile.photoURL?.absoluteString
        )

        let body = try client.encodeBody(payload)
        let profileEndpoint = APIEndpoint(
            path: "/rest/v1/profiles",
            method: "POST",
            headers: ["Prefer": "resolution=merge-duplicates,return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(profileEndpoint, as: EmptyResponse.self)

        try await replaceHomeLocations(for: userID, from: profile)
        try await upsertVehicle(for: userID, vehicle: profile.vehicles?.first)
    }

    func currentAuthUserID() -> UUID? {
        guard let raw = sessionStore.authUserID else { return nil }
        return UUID(uuidString: raw)
    }

    private func fetchCurrentProfileSnapshot(userID: String?) async throws -> CurrentProfileSnapshot {
        guard let userID = userID, !userID.isEmpty else {
            return CurrentProfileSnapshot(profile: nil, homeLocations: [], vehicle: nil)
        }

        async let profileTask: [SupabaseProfileRecord] = client.send(
            APIEndpoint(
                path: "/rest/v1/profiles?select=id,email,phone,is_email_verified,full_name,role,course_name,year,employee_id,photo_url&id=eq.\(userID)&limit=1",
                method: "GET",
                headers: ["Accept": "application/json"]
            ),
            as: [SupabaseProfileRecord].self
        )

        async let homeTask: [SupabaseHomeLocationRow] = client.send(
            APIEndpoint(
                path: "/rest/v1/home_locations?select=user_id,label,lat,lon,address,is_primary&user_id=eq.\(userID)&order=is_primary.desc,created_at.asc",
                method: "GET"
            ),
            as: [SupabaseHomeLocationRow].self
        )

        async let vehicleTask: [SupabaseVehicleRow] = client.send(
            APIEndpoint(
                path: "/rest/v1/user_vehicles?select=user_id,type,model,registration_number,seats&user_id=eq.\(userID)&limit=1",
                method: "GET"
            ),
            as: [SupabaseVehicleRow].self
        )

        let profile = try await profileTask.first
        let homes = (try? await homeTask) ?? []
        let vehicle = try await vehicleTask.first

        return CurrentProfileSnapshot(profile: profile, homeLocations: homes, vehicle: vehicle)
    }

    private func replaceHomeLocations(for userID: UUID, from profile: UserProfile) async throws {
        let uid = userID.uuidString.lowercased()

        let deleteEndpoint = APIEndpoint(
            path: "/rest/v1/home_locations?user_id=eq.\(uid)",
            method: "DELETE",
            headers: ["Prefer": "return=minimal"]
        )
        let _: EmptyResponse = try await client.send(deleteEndpoint, as: EmptyResponse.self)

        let homes = profile.savedHomeLocations ?? (profile.savedHomeLocation.map { [$0] } ?? [])
        guard !homes.isEmpty else { return }

        let rows = homes.enumerated().map { index, loc in
            SupabaseHomeLocationRow(
                userID: uid,
                label: index == 0 ? "Home" : "Home \(index + 1)",
                lat: loc.lat,
                lon: loc.lon,
                address: loc.address,
                isPrimary: index == 0
            )
        }

        let body = try client.encodeBody(rows)
        let insertEndpoint = APIEndpoint(
            path: "/rest/v1/home_locations",
            method: "POST",
            headers: ["Prefer": "return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(insertEndpoint, as: EmptyResponse.self)
    }

    private func upsertVehicle(for userID: UUID, vehicle: Vehicle?) async throws {
        let uid = userID.uuidString.lowercased()

        guard let vehicle else {
            let endpoint = APIEndpoint(
                path: "/rest/v1/user_vehicles?user_id=eq.\(uid)",
                method: "DELETE",
                headers: ["Prefer": "return=minimal"]
            )
            let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
            return
        }

        let payload = SupabaseVehicleRow(
            userID: uid,
            type: vehicle.type.rawValue,
            model: vehicle.model,
            registrationNumber: vehicle.registrationNumber,
            seats: vehicle.seats
        )
        let body = try client.encodeBody(payload)
        let endpoint = APIEndpoint(
            path: "/rest/v1/user_vehicles",
            method: "POST",
            headers: ["Prefer": "resolution=merge-duplicates,return=minimal"],
            body: body
        )
        let _: EmptyResponse = try await client.send(endpoint, as: EmptyResponse.self)
    }

    private func mapAuthToRemoteUser(authUser: SupabaseAuthUser?, snapshot: CurrentProfileSnapshot, fallbackEmail: String) -> AuthRemoteUser? {
        let email = snapshot.profile?.email ?? authUser?.email ?? fallbackEmail
        guard !email.isEmpty else { return nil }

        let homePoints = snapshot.homeLocations.map { row in
            LocationPoint(lat: row.lat, lon: row.lon, address: row.address)
        }

        let vehicle: Vehicle?
        if let row = snapshot.vehicle, let type = VehicleType(rawValue: row.type) {
            vehicle = Vehicle(type: type, model: row.model, registrationNumber: row.registrationNumber, seats: row.seats)
        } else {
            vehicle = nil
        }

        return AuthRemoteUser(
            id: snapshot.profile?.id ?? authUser?.id,
            email: email,
            phone: snapshot.profile?.phone ?? authUser?.phone,
            isEmailVerified: snapshot.profile?.isEmailVerified ?? (authUser?.emailConfirmedAt != nil),
            fullName: snapshot.profile?.fullName,
            role: snapshot.profile?.role,
            courseName: snapshot.profile?.courseName,
            year: snapshot.profile?.year,
            employeeID: snapshot.profile?.employeeID,
            photoURL: snapshot.profile?.photoURL,
            savedHomeLocation: homePoints.first,
            savedHomeLocations: homePoints.isEmpty ? nil : homePoints,
            vehicle: vehicle
        )
    }

    private func hasCompleteProfile(_ snapshot: CurrentProfileSnapshot) -> Bool {
        guard let profile = snapshot.profile else { return false }
        let name = (profile.fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRole = profile.role != nil
        let hasPhone = !(profile.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasHome = !snapshot.homeLocations.isEmpty
        return !name.isEmpty && hasRole && hasPhone && hasHome
    }

    private func effectiveAuthUserID(localProfileID: UUID) -> UUID? {
        if let backendID = currentAuthUserID() {
            return backendID
        }
        return localProfileID
    }

    private func verifyEmailOTPWithFallback(email: String, code: String) async throws -> SupabaseAuthSessionResponse {
        do {
            let primaryBody = try client.encodeBody(SupabaseEmailVerifyRequest(email: email, token: code, type: "email"))
            let primaryEndpoint = APIEndpoint(path: "/auth/v1/verify", method: "POST", body: primaryBody)
            return try await client.send(primaryEndpoint, as: SupabaseAuthSessionResponse.self)
        } catch {
            let fallbackBody = try client.encodeBody(SupabaseEmailVerifyRequest(email: email, token: code, type: "signup"))
            let fallbackEndpoint = APIEndpoint(path: "/auth/v1/verify", method: "POST", body: fallbackBody)
            return try await client.send(fallbackEndpoint, as: SupabaseAuthSessionResponse.self)
        }
    }
}

// BUG FIX: SessionStore is now a thin bridge over SessionManager.
// Previously, the old networking layer (RideRepository, ProfileRepository) read its token
// from SessionManager, while the new APIClient layer read from SessionStore — two different
// UserDefaults keys, causing either layer to go out unauthenticated depending on login path.
// Now all reads and writes funnel through SessionManager as the single source of truth.
final class SessionStore {
    static let shared = SessionStore()
    private init() {}

    /// Delegates to SessionManager — the single source of truth for the access token.
    var accessToken: String? {
        get { SessionManager.shared.accessToken }
        set {
            guard let token = newValue else {
                SessionManager.shared.clear()
                return
            }
            // Preserve existing refresh token and expiry when only the access token changes.
            let rt = SessionManager.shared.refreshToken ?? token
            let uid = SessionManager.shared.userID ?? UUID()
            SessionManager.shared.save(
                accessToken: token,
                refreshToken: rt,
                userID: uid,
                email: SessionManager.shared.userEmail,
                expiresAt: SessionManager.shared.accessTokenExpiresAt,
                preserveLoginDate: true
            )
        }
    }

    /// Delegates to SessionManager — returns the auth user ID as a string.
    var authUserID: String? {
        get { SessionManager.shared.userID?.uuidString }
        set {
            // UserID is stored as part of the full save() call in verifyEmailOTP.
            // This setter is a no-op to avoid partial-state writes.
        }
    }
}
