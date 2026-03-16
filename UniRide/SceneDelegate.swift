//
//  SceneDelegate.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 14/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 1. Manually create the window
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 2. Synchronous check to set the very first screen the user sees.
        // This prevents UIKit from defaulting to the "Email" storyboard VC and flickering.
        let isLoggedIn = SessionManager.shared.isLoggedIn
        let isGuest = SessionManager.shared.isGuest
        
        if isLoggedIn || isGuest {
            // Logged in or Guest: Show a neutral color (Splash) while restoreSessionOrShowAuth runs
            let splashVC = UIViewController()
            splashVC.view.backgroundColor = .systemBackground // or matches LaunchScreen
            window.rootViewController = splashVC
        } else {
            // Not logged in: Route to Onboarding or Email immediately
            showAuthFlow(window: window)
        }
        
        window.makeKeyAndVisible()

        // 3. Kick off async restoration (token refresh, user hydration)
        Task { await restoreSessionOrShowAuth() }
        
        // 4. Global Keyboard Dismissal
        setupGlobalKeyboardDismissal()
    }

    private func setupGlobalKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGlobalTap))
        tap.cancelsTouchesInView = false
        window?.addGestureRecognizer(tap)
    }

    @objc private func handleGlobalTap() {
        window?.endEditing(true)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Silently refresh the access token each time the app comes to the foreground
        Task { await SessionManager.shared.refreshIfNeeded() }
    }

    // MARK: - Session restoration

    private func restoreSessionOrShowAuth() async {
        guard let window = window else { return }
        let session = SessionManager.shared

        guard session.isLoggedIn || session.isGuest else {
            // No valid session — show auth flow on main thread
            await MainActor.run { showAuthFlow(window: window) }
            return
        }

        if session.isLoggedIn {
            // 1️⃣ Refresh the access token FIRST — before any API calls fire
            await session.refreshIfNeeded()

            // 2️⃣ Restore currentUserID in UserDataModel from the saved session
            await UserDataModel.shared.restoreSessionUser()
        }

        // 3️⃣ Jump to main tab bar
        await MainActor.run {
            let mainSB = UIStoryboard(name: "Main", bundle: nil)
            let tabBar = mainSB.instantiateViewController(withIdentifier: "MainTabBarController")
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        }
    }

    private func showAuthFlow(window: UIWindow) {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        
        if !hasSeenOnboarding {
            // First time ever: Show Onboarding
            let onboardingVC = mainSB.instantiateViewController(withIdentifier: "OnboardingViewController")
            window.rootViewController = onboardingVC
        } else {
            // Returning logged-out user: Show Email Login
            let emailVC = mainSB.instantiateViewController(withIdentifier: "EmailViewController")
            let nav = UINavigationController(rootViewController: emailVC)
            window.rootViewController = nav
        }
        window.makeKeyAndVisible()
    }

    // MARK: - Unused lifecycle stubs

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

