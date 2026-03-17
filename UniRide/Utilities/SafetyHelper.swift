import UIKit

/// A reusable helper to show Reporting and Blocking UI across the app.
final class SafetyHelper {
    
    static let shared = SafetyHelper()
    private init() {}
    
    /// Shows an action sheet to choose a report reason and then submits it.
    func showReportUI(
        from vc: UIViewController,
        reportedUserID: UUID,
        contentType: SafetyService.ContentType,
        contentID: UUID? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: "Report", message: "Why are you reporting this?", preferredStyle: .actionSheet)
        
        for reason in SafetyService.ReportReason.allCases {
            alert.addAction(UIAlertAction(title: reason.rawValue, style: .default) { _ in
                Task {
                    do {
                        try await SafetyService.shared.report(
                            reportedUserID: reportedUserID,
                            contentType: contentType,
                            contentID: contentID,
                            reason: reason
                        )
                        await MainActor.run {
                            self.showSuccess(from: vc, message: "Report submitted. Thank you for helping keep UniRide safe.")
                            completion?(true)
                        }
                    } catch {
                        await MainActor.run {
                            self.showError(from: vc, error: error)
                            completion?(false)
                        }
                    }
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = vc.view
            popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        vc.present(alert, animated: true)
    }
    
    /// Shows a confirmation dialog to block a user.
    func showBlockUI(
        from vc: UIViewController,
        blockedUserID: UUID,
        userName: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: "Block \(userName)?",
            message: "You will no longer see each other's rides, posts, or messages. This action can be undone from Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { _ in
            Task {
                do {
                    try await SafetyService.shared.blockUser(blockedUserID: blockedUserID)
                    await MainActor.run {
                        self.showSuccess(from: vc, message: "\(userName) has been blocked.")
                        completion?(true)
                    }
                } catch {
                    await MainActor.run {
                        self.showError(from: vc, error: error)
                        completion?(false)
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        vc.present(alert, animated: true)
    }
    
    private func showSuccess(from vc: UIViewController, message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
    
    private func showError(from vc: UIViewController, error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}
