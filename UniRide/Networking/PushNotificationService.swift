import Foundation
import UIKit
import UserNotifications

// MARK: - PushNotificationService
// ─────────────────────────────────────────────────────────────────────────────
// Full APNs lifecycle manager for UniRide.
//
// Responsibilities
//   1. Request notification permission at the right moment.
//   2. Capture the APNs device token and store it in Supabase `device_tokens`.
//   3. Expose a `send(to:title:body:data:)` method that calls the
//      Supabase Edge Function `notify-user` to push a notification to a
//      specific user across all their registered devices.
//   4. Create a `UNMutableNotificationContent` helper for local fallback
//      (shown when the triggering user's own device receives the push).
// ─────────────────────────────────────────────────────────────────────────────

final class PushNotificationService: NSObject {

    static let shared = PushNotificationService()
    private override init() { super.init() }

    // Edge Function endpoint — adjust if your project slug differs
    private var edgeFunctionURL: URL {
        let base = BackendConfig.baseURL?.absoluteString
            ?? "https://jobxehwerpvedlfkbfoi.supabase.co"
        return URL(string: "\(base)/functions/v1/notify-user")!
    }

    // MARK: - Permission

    /// Call once after the user completes onboarding / first login.
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
    }

    // MARK: - Token Registration

    /// Called from AppDelegate when APNs returns a device token.
    func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "apns_device_token")
        // Upload to Supabase asynchronously
        Task { try? await self.upsertDeviceToken(token) }
    }

    /// Called from AppDelegate when APNs registration fails.
    func didFailToRegister(error: Error) {
        print("[PushNotificationService] APNs registration failed: \(error.localizedDescription)")
    }

    private func upsertDeviceToken(_ token: String) async throws {
        guard let userID = SessionManager.shared.userID else { return }
        let mgr = SupabaseManager.shared
        let url = mgr.restURL(table: "device_tokens")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = mgr.userHeaders
        req.setValue("application/json",          forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        let payload: [String: Any] = [
            "user_id":    userID.uuidString,
            "token":      token,
            "platform":   "ios",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, _) = try await URLSession.shared.data(for: req)
    }

    // MARK: - Send Push via Supabase Edge Function

    /// Sends a push notification to every registered device of `recipientUserID`.
    /// The Edge Function fetches the device tokens from `device_tokens` table
    /// and calls APNs on the server side.
    func send(
        to recipientUserID: UUID,
        title: String,
        body: String,
        data: [String: String] = [:]
    ) {
        Task {
            try? await sendAsync(
                to: recipientUserID,
                title: title,
                body: body,
                data: data
            )
        }
    }

    private func sendAsync(
        to recipientUserID: UUID,
        title: String,
        body: String,
        data: [String: String]
    ) async throws {
        guard let token = SessionManager.shared.accessToken else { return }
        var req = URLRequest(url: edgeFunctionURL)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)",    forHTTPHeaderField: "Authorization")
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = [
            "recipient_user_id": recipientUserID.uuidString,
            "title":             title,
            "body":              body
        ]
        if !data.isEmpty { payload["data"] = data }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, _) = try await URLSession.shared.data(for: req)
    }
}

// MARK: - UNUserNotificationCenterDelegate (foreground display)

extension PushNotificationService: UNUserNotificationCenterDelegate {

    /// Show the notification banner even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    /// Handle a tap on a notification — deep-link to My Rides tab.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let action   = userInfo["action"] as? String ?? ""

        DispatchQueue.main.async {
            // Deep-link to the relevant tab based on the notification payload
            guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first,
                  let root  = scene.windows.first?.rootViewController else {
                completionHandler()
                return
            }

            // Resolve the tab bar (may be embedded in a nav controller)
            let tabBar: UITabBarController?
            if let tb  = root as? UITabBarController { tabBar = tb }
            else if let nav = root as? UINavigationController,
                    let tb  = nav.viewControllers.first as? UITabBarController { tabBar = tb }
            else { tabBar = nil }

            switch action {
            case "request_approved", "request_denied", "passenger_joined", "passenger_cancelled":
                tabBar?.selectedIndex = 1   // My Rides tab
            case "new_message":
                tabBar?.selectedIndex = 1   // also My Rides (chat lives there)
            default:
                tabBar?.selectedIndex = 0   // Home
            }
        }

        completionHandler()
    }
}
