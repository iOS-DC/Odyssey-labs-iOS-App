//
//  UIStyleExtensions.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 11/12/25.
//

import Foundation
import UIKit
import ObjectiveC

// MARK: - Design Tokens
enum AppDesign {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
    }

    enum Size {
        static let buttonHeight: CGFloat = 52
        static let fieldHeight: CGFloat = 52
        static let progressHeight: CGFloat = 4
    }

    enum Shadow {
        static let cardOpacity: Float = 0.08
        static let cardRadius: CGFloat = 12
        static let cardOffset = CGSize(width: 0, height: 6)

        static let smallCardOpacity: Float = 0.06
        static let smallCardRadius: CGFloat = 8
        static let smallCardOffset = CGSize(width: 0, height: 4)
    }

    enum Color {
        static let primary = UIColor.systemBlue
        static let surface = UIColor.systemBackground
        static let border = UIColor.systemGray4
        static let fieldBackground = UIColor.secondarySystemBackground
        static let progressTrack = UIColor.systemGray5
        static let textPrimary = UIColor.label
        static let success = UIColor.systemGreen
        static let destructive = UIColor.systemRed
        static let warning = UIColor.systemOrange
    }

    enum Typography {
        static let h1 = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let h2 = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let title = UIFont.systemFont(ofSize: 22, weight: .bold)
        static let bodyStrong = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let subheadline = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let captionStrong = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let caption = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let action = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let button = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let pillSelected = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let pillRegular = UIFont.systemFont(ofSize: 13, weight: .medium)
    }
}

enum AppHaptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private func setMinimumHeight(_ height: CGFloat, for view: UIView) {
    if let existing = view.constraints.first(where: { $0.firstAttribute == .height }) {
        existing.constant = max(existing.constant, height)
    } else {
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}

// MARK: - List Motion
extension UITableView {
    /// Subtle staggered entrance for currently visible rows.
    func animateVisibleCellsStaggered(
        offsetY: CGFloat = 14,
        duration: TimeInterval = 0.32
    ) {
        let visible = visibleCells
        guard !visible.isEmpty else { return }

        if UIAccessibility.isReduceMotionEnabled {
            visible.forEach {
                $0.alpha = 1.0
                $0.transform = .identity
            }
            return
        }

        for cell in visible {
            cell.alpha = 0.0
            cell.transform = CGAffineTransform(translationX: 0, y: offsetY)
        }

        for (idx, cell) in visible.enumerated() {
            UIView.animate(
                withDuration: duration,
                delay: 0.03 * Double(idx),
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.25,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                cell.alpha = 1.0
                cell.transform = .identity
            }
        }
    }
}

// MARK: - Cards / Containers
extension UIView {

    /// Standard app card (used across Home, Offer Ride, Join Ride)
    func applyCardStyle(
        corner: CGFloat = AppDesign.Radius.lg,
        shadowOpacity: Float = AppDesign.Shadow.cardOpacity,
        shadowRadius: CGFloat = AppDesign.Shadow.cardRadius,
        shadowOffset: CGSize = AppDesign.Shadow.cardOffset
    ) {
        layer.cornerRadius = corner
        layer.masksToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        backgroundColor = AppDesign.Color.surface
    }

    /// Smaller card (filters, dropdowns, suggestions)
    func applySmallCard(corner: CGFloat = AppDesign.Radius.md) {
        layer.cornerRadius = corner
        layer.masksToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        backgroundColor = AppDesign.Color.surface
    }
}

// MARK: - Buttons
extension UIButton {
    private static let pressDownActionID = UIAction.Identifier("uniride.press.down")
    private static let pressUpActionID = UIAction.Identifier("uniride.press.up")

    /// Subtle press animation + optional touch-down haptic for consistent button feel.
    func applyPressMicroInteraction(
        scale: CGFloat = 0.97,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .light
    ) {
        if #available(iOS 14.0, *) {
            removeAction(identifiedBy: Self.pressDownActionID, for: .touchDown)
            removeAction(identifiedBy: Self.pressUpActionID, for: .touchUpInside)
            removeAction(identifiedBy: Self.pressUpActionID, for: .touchUpOutside)
            removeAction(identifiedBy: Self.pressUpActionID, for: .touchCancel)
            removeAction(identifiedBy: Self.pressUpActionID, for: .touchDragExit)

            let down = UIAction(identifier: Self.pressDownActionID) { [weak self] _ in
                guard let self else { return }
                if let style = hapticStyle { AppHaptics.impact(style) }
                guard !UIAccessibility.isReduceMotionEnabled else { return }
                UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                    self.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }

            let up = UIAction(identifier: Self.pressUpActionID) { [weak self] _ in
                guard let self else { return }
                guard !UIAccessibility.isReduceMotionEnabled else {
                    self.transform = .identity
                    return
                }
                UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.2, options: [.curveEaseOut, .allowUserInteraction]) {
                    self.transform = .identity
                }
            }

            addAction(down, for: .touchDown)
            addAction(up, for: .touchUpInside)
            addAction(up, for: .touchUpOutside)
            addAction(up, for: .touchCancel)
            addAction(up, for: .touchDragExit)
        }
    }

    /// Primary filled button (Offer / Join)
    func applyPrimaryButton(
        color: UIColor = AppDesign.Color.primary,
        radius: CGFloat = AppDesign.Radius.md
    ) {
        layer.cornerRadius = radius
        backgroundColor = color
        setTitleColor(.white, for: .normal)
        titleLabel?.font = AppDesign.Typography.button
        setMinimumHeight(AppDesign.Size.buttonHeight, for: self)
        applyPressMicroInteraction(scale: 0.97, hapticStyle: .light)
    }

    /// Primary prominent CTA (used for top-level quick actions).
    func applyProminentPrimaryCTA(
        title: String,
        color: UIColor = AppDesign.Color.primary,
        corner: CGFloat = AppDesign.Radius.lg,
        imageSystemName: String? = nil,
        imagePlacement: NSDirectionalRectEdge = .trailing
    ) {
        var config = UIButton.Configuration.filled()
        config.title = title
        if let imageSystemName {
            config.image = UIImage(systemName: imageSystemName)
            config.imagePlacement = imagePlacement
            config.imagePadding = AppDesign.Spacing.xs
        }
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = corner
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.bodyStrong
            return out
        }
        configuration = config
        setMinimumHeight(AppDesign.Size.buttonHeight, for: self)
        applyPressMicroInteraction(scale: 0.97, hapticStyle: .light)
    }

    /// Secondary prominent CTA (brand-tinted with blue outline).
    func applyProminentSecondaryCTA(
        title: String,
        color: UIColor = AppDesign.Color.primary,
        fillAlpha: CGFloat = 0.14,
        corner: CGFloat = AppDesign.Radius.lg,
        borderWidth: CGFloat = 1.5
    ) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = color.withAlphaComponent(fillAlpha)
        config.baseForegroundColor = color
        config.cornerStyle = .fixed
        config.background.cornerRadius = corner
        config.background.strokeColor = color
        config.background.strokeWidth = borderWidth
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.bodyStrong
            return out
        }
        configuration = config
        setMinimumHeight(AppDesign.Size.buttonHeight, for: self)
        applyPressMicroInteraction(scale: 0.97, hapticStyle: .light)
    }

    /// Secondary outline button
    func applyOutlineButton(corner: CGFloat = AppDesign.Radius.sm) {
        layer.cornerRadius = corner
        layer.borderWidth = 1
        layer.borderColor = AppDesign.Color.border.cgColor
        backgroundColor = .clear
        setTitleColor(AppDesign.Color.textPrimary, for: .normal)
        titleLabel?.font = AppDesign.Typography.button
        setMinimumHeight(AppDesign.Size.buttonHeight, for: self)
        applyPressMicroInteraction(scale: 0.98, hapticStyle: .light)
    }

    /// Text-only action button (details, links, secondary CTAs)
    func applyTextActionStyle(
        color: UIColor = AppDesign.Color.primary,
        font: UIFont = AppDesign.Typography.action
    ) {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = color
            config.contentInsets = .zero
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = font
                return outgoing
            }
            configuration = config
        } else {
            backgroundColor = .clear
            setTitleColor(color, for: .normal)
        }
        backgroundColor = .clear
        titleLabel?.font = font
        applyPressMicroInteraction(scale: 0.98, hapticStyle: nil)
    }

    /// Pill-shaped secondary action used for non-primary row actions.
    func applyTintActionStyle(
        title: String,
        imageSystemName: String? = nil,
        color: UIColor = AppDesign.Color.primary
    ) {
        var config = UIButton.Configuration.tinted()
        config.title = title
        if let imageSystemName {
            config.image = UIImage(systemName: imageSystemName)
            config.imagePlacement = .leading
            config.imagePadding = AppDesign.Spacing.xxs
        }
        config.baseBackgroundColor = color
        config.baseForegroundColor = color
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.subheadline
            return out
        }
        configuration = config
        backgroundColor = .clear
        applyPressMicroInteraction(scale: 0.98, hapticStyle: .light)
    }

    /// Standard enabled/disabled appearance for primary CTAs.
    /// Keeps contrast accessible without relying on alpha dimming.
    func setPrimaryCTAEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = 1.0

        if #available(iOS 15.0, *), var config = configuration {
            config.baseBackgroundColor = enabled ? AppDesign.Color.primary : UIColor.systemGray5
            config.baseForegroundColor = enabled ? .white : UIColor.systemGray
            configuration = config
            return
        }

        backgroundColor = enabled ? AppDesign.Color.primary : UIColor.systemGray5
        setTitleColor(enabled ? .white : UIColor.systemGray, for: .normal)
    }
}


// MARK: - TextFields
extension UITextField {

    /// Rounded border + padding
    func applyRoundedField() {
        layer.cornerRadius = AppDesign.Radius.sm
        layer.borderWidth = 1
        layer.borderColor = AppDesign.Color.border.cgColor
        backgroundColor = AppDesign.Color.fieldBackground
        setLeftPaddingPoints(14)
        setMinimumHeight(AppDesign.Size.fieldHeight, for: self)
    }

    /// Add SF Symbol icon inside the left
    func addLeftIcon(_ systemName: String) {
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = .systemGray
        icon.frame = CGRect(x: 0, y: 0, width: 22, height: 22)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 30))
        icon.center = container.center
        container.addSubview(icon)

        leftView = container
        leftViewMode = .always
    }
}

// MARK: - Typography
extension UILabel {
    func applyTextStyle(
        _ font: UIFont,
        color: UIColor = AppDesign.Color.textPrimary,
        lines: Int = 1
    ) {
        self.font = font
        textColor = color
        numberOfLines = lines
    }
}

// MARK: - Route Pills
extension UIButton {

    func applyRoutePill(selected: Bool) {
        titleLabel?.font = selected
            ? AppDesign.Typography.pillSelected
            : AppDesign.Typography.pillRegular

        titleLabel?.numberOfLines = 2
        titleLabel?.textAlignment = .center

        layer.cornerRadius = AppDesign.Radius.sm
        layer.masksToBounds = true

        if selected {
            backgroundColor = AppDesign.Color.primary
            setTitleColor(.white, for: .normal)
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 6
            layer.shadowOffset = CGSize(width: 0, height: 3)
        } else {
            backgroundColor = AppDesign.Color.surface.withAlphaComponent(0.9)
            setTitleColor(AppDesign.Color.textPrimary, for: .normal)
            layer.borderWidth = 1
            layer.borderColor = UIColor.separator.cgColor
            layer.shadowOpacity = 0
        }
    }
}

// MARK: - Avatar Generation
extension UIImage {
    static func generatedAvatar(for name: String, size: CGSize) -> UIImage? {
        let initials = name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            UIColor.systemGray5.setFill()
            path.fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.height * 0.4, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let text = NSString(string: initials)
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

extension UIImageView {
    func loadAndFallback(from url: URL?, name: String) {
        // Clear current image to avoid flicker
        self.image = nil
        
        guard let url = url else {
            self.image = UIImage.generatedAvatar(for: name, size: self.bounds.size.width > 0 ? self.bounds.size : CGSize(width: 40, height: 40))
            return
        }
        
        // Use a background task to load data
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            } else {
                DispatchQueue.main.async {
                    self.image = UIImage.generatedAvatar(for: name, size: self.bounds.size.width > 0 ? self.bounds.size : CGSize(width: 40, height: 40))
                }
            }
        }
    }
}
