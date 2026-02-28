import UIKit
import ObjectiveC

private var onboardingProgressTrackKey: UInt8 = 0
private var onboardingProgressFillKey: UInt8 = 0
private var onboardingEntranceAnimatedKey: UInt8 = 0

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
            track.backgroundColor = AppDesign.Color.progressTrack
            track.layer.cornerRadius = AppDesign.Size.progressHeight / 2
            track.clipsToBounds = true

            fill = UIView()
            fill.translatesAutoresizingMaskIntoConstraints = false
            fill.backgroundColor = AppDesign.Color.primary
            fill.layer.cornerRadius = AppDesign.Size.progressHeight / 2
            fill.clipsToBounds = true

            track.addSubview(fill)
            view.addSubview(track)

            NSLayoutConstraint.activate([
                track.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.md),
                track.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.md),
                track.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppDesign.Spacing.xs),
                track.heightAnchor.constraint(equalToConstant: AppDesign.Size.progressHeight),

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
        button.layer.cornerRadius = AppDesign.Radius.md
        button.clipsToBounds = true
        if let h = button.constraints.first(where: { $0.firstAttribute == .height }) {
            h.constant = max(h.constant, AppDesign.Size.buttonHeight)
        } else {
            button.heightAnchor.constraint(equalToConstant: AppDesign.Size.buttonHeight).isActive = true
        }
    }

    /// Consistent entrance motion for onboarding/auth screens.
    /// Runs once per view controller instance.
    func animateOnboardingEntrance(_ views: [UIView]) {
        guard objc_getAssociatedObject(self, &onboardingEntranceAnimatedKey) as? Bool != true else { return }
        objc_setAssociatedObject(self, &onboardingEntranceAnimatedKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let validViews = views.filter { !$0.isHidden && $0.alpha > 0.0 }
        guard !validViews.isEmpty else { return }

        // If this screen is arriving through an animated nav/modal transition,
        // keep only the system transition to avoid stacked animations.
        if let coordinator = transitionCoordinator, coordinator.isAnimated {
            validViews.forEach {
                $0.alpha = 1.0
                $0.transform = .identity
            }
            return
        }

        if UIAccessibility.isReduceMotionEnabled {
            validViews.forEach { $0.alpha = 1.0; $0.transform = .identity }
            return
        }

        validViews.forEach {
            $0.alpha = 0.0
            $0.transform = CGAffineTransform(translationX: 0, y: 20)
        }

        for (index, item) in validViews.enumerated() {
            UIView.animate(
                withDuration: 0.42,
                delay: 0.03 * Double(index),
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.35,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                item.alpha = 1.0
                item.transform = .identity
            }
        }
    }
}
