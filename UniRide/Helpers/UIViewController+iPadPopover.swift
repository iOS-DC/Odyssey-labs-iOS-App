// UIViewController+iPadPopover.swift
// UniRide
//
// On iPad, UIActivityViewController and UIImagePickerController MUST be
// anchored to a source view via popoverPresentationController, otherwise
// UIKit throws NSInternalInconsistencyException and crashes.
// Use this helper instead of bare present(_:animated:) for those two types.

import UIKit

extension UIViewController {

    /// Presents a view controller, automatically configuring its
    /// `popoverPresentationController` when running on iPad.
    ///
    /// - Parameters:
    ///   - vc: The view controller to present. Typically a
    ///         `UIActivityViewController` or `UIImagePickerController`.
    ///   - sourceView: The view the popover arrow should point at.
    ///   - sourceRect: The rect within `sourceView` to anchor the popover.
    ///                 Defaults to the full bounds of `sourceView`.
    ///   - arrowDirections: Permitted arrow directions. Pass `[]` to show a
    ///                      centred popover with no arrow.
    ///   - animated: Whether to animate the presentation.
    ///   - completion: Called after the presentation finishes.
    func presentPopover(
        _ vc: UIViewController,
        from sourceView: UIView,
        sourceRect: CGRect? = nil,
        arrowDirections: UIPopoverArrowDirection = .any,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        if let popover = vc.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceRect ?? sourceView.bounds
            popover.permittedArrowDirections = arrowDirections
        }
        present(vc, animated: animated, completion: completion)
    }

    /// Convenience overload that anchors to the centre of `self.view`
    /// without an arrow — useful for share sheets and picker controllers
    /// that have no logical anchor button.
    func presentPopoverCentered(
        _ vc: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let centreRect = CGRect(
            x: view.bounds.midX, y: view.bounds.midY,
            width: 0, height: 0
        )
        presentPopover(
            vc,
            from: view,
            sourceRect: centreRect,
            arrowDirections: [],
            animated: animated,
            completion: completion
        )
    }
}
