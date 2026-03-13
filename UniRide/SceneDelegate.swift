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
        guard let _ = (scene as? UIWindowScene) else { return }
        // Restore or reject persisted session on cold launch
        Task { await restoreSessionOrShowAuth() }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Silently refresh the access token each time the app comes to the foreground
        Task { await SessionManager.shared.refreshIfNeeded() }
    }

    // MARK: - Session restoration

    private func restoreSessionOrShowAuth() async {
        guard let window = window else { return }
        let session = SessionManager.shared

        guard session.isLoggedIn else {
            // No valid session — show auth flow on main thread
            await MainActor.run { showAuthFlow(window: window) }
            return
        }

        // 1️⃣ Refresh the access token FIRST — before any API calls fire
        await session.refreshIfNeeded()

        // 2️⃣ Restore currentUserID in UserDataModel from the saved session
        await UserDataModel.shared.restoreSessionUser()

        // 3️⃣ Jump to main tab bar
        await MainActor.run {
            let mainSB = UIStoryboard(name: "Main", bundle: nil)
            let tabBar = mainSB.instantiateViewController(withIdentifier: "MainTabBarController")
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        }
    }

    private func showAuthFlow(window: UIWindow) {
        if !(window.rootViewController is EmailViewController) {
            let authSB = UIStoryboard(name: "RoleSelection", bundle: nil)
            if let authRoot = authSB.instantiateInitialViewController() {
                window.rootViewController = authRoot
                window.makeKeyAndVisible()
            }
        }
    }

    // MARK: - Unused lifecycle stubs

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

