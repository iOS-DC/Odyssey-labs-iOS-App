import UIKit

extension UIViewController {
    /// Checks if the user is logged in. If not, shows an alert that redirects to the Auth flow.
    /// - Parameter completion: Block executed if the user is already logged in.
    func ensureNonGuest(completion: @escaping () -> Void) {
        if SessionManager.shared.isLoggedIn {
            completion()
        } else {
            let alert = UIAlertController(
                title: "Login Required",
                message: "This feature is only available for university members. Login now to proceed?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sign In", style: .default) { _ in
                SceneDelegate.setRootToAuth()
            })
            
            present(alert, animated: true)
        }
    }
}
