import UIKit
import ObjectiveC

private var onboardingProgressTrackKey: UInt8 = 0
private var onboardingProgressFillKey: UInt8 = 0

extension UIViewController {
    func applyOnboardingChrome(step: Int, total: Int) {
        guard total > 0 else { return }
        navigationItem.backButtonTitle = ""

        let progress = max(0, min(CGFloat(step) / CGFloat(total), 1))
        let track: UIView
        let fill: UIView

        if let existingTrack = objc_getAssociatedObject(self, &onboardingProgressTrackKey) as? UIView,
           let existingFill = objc_getAssociatedObject(self, &onboardingProgressFillKey) as? UIView {
            track = existingTrack
            fill = existingFill
        } else {
            track = UIView()
            track.translatesAutoresizingMaskIntoConstraints = false
            track.backgroundColor = UIColor.systemGray5
            track.layer.cornerRadius = 2
            track.clipsToBounds = true

            fill = UIView()
            fill.translatesAutoresizingMaskIntoConstraints = false
            fill.backgroundColor = UIColor.systemBlue
            fill.layer.cornerRadius = 2
            fill.clipsToBounds = true

            track.addSubview(fill)
            view.addSubview(track)

            NSLayoutConstraint.activate([
                track.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                track.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                track.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
                track.heightAnchor.constraint(equalToConstant: 4),

                fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
                fill.topAnchor.constraint(equalTo: track.topAnchor),
                fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
                fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: progress)
            ])

            objc_setAssociatedObject(self, &onboardingProgressTrackKey, track, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &onboardingProgressFillKey, fill, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        track.constraints
            .filter { $0.firstItem as? UIView == fill && $0.firstAttribute == .width }
            .forEach { $0.isActive = false }
        NSLayoutConstraint.activate([
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: progress)
        ])

        // Keep content below the progress bar on all onboarding screens.
        additionalSafeAreaInsets.top = 12
    }

    func applyPrimaryOnboardingCTAStyle(_ button: UIButton) {
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        if let h = button.constraints.first(where: { $0.firstAttribute == .height }) {
            h.constant = max(h.constant, 50)
        } else {
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }
}
