import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppTheme.applyGlobalAppearance()
        _ = LiveNotificationService.shared

        // ── Push Notifications ──────────────────────────────────────────────
        // Set PushNotificationService as the UNUserNotificationCenter delegate
        // so it can show banners while the app is in the foreground and handle
        // notification taps for deep-linking.
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared

        // Request permission after the user is already logged in
        // (called again from the post-login flow, this is a no-op if already granted)
        if SessionManager.shared.isLoggedIn {
            PushNotificationService.shared.requestPermission()
        }
        // ────────────────────────────────────────────────────────────────────

        return true
    }

    // MARK: - APNs Token Callbacks

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationService.shared.didRegister(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationService.shared.didFailToRegister(error: error)
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}
}
