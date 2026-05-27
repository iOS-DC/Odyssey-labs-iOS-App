//
//  UIStyleExtensions.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 11/12/25.
//

import Foundation
import UIKit
import ObjectiveC

// MARK: - Design System
// UniRide design tokens. All UI must pull values from here — no magic numbers in VCs or views.

enum AppDesign {

    // ─────────────────────────────────────────────
    // MARK: Spacing  (8pt base grid)
    // ─────────────────────────────────────────────
    // Use these for margins, padding, and gaps.
    // Never hard-code a spacing value in a VC or view.
    //
    //  xxs  4   half-unit — icon inner padding, tight badge gaps
    //  xs   8   1 unit    — icon-to-label gap, progress bar insets
    //  sm   12  1.5 units — stack internal spacing, chip padding
    //  md   16  2 units   — standard horizontal margin, field padding
    //  lg   20  2.5 units — card gutters, section-to-CTA gap
    //  xl   24  3 units   — card padding, screen horizontal inset
    //  xxl  32  4 units   — section-to-section gap, hero vertical rhythm
    //  xxxl 48  6 units   — screen breathing room (top/bottom of full-screen cards)

    enum Spacing {
        static let xxs:  CGFloat = 4
        static let xs:   CGFloat = 8
        static let sm:   CGFloat = 12
        static let md:   CGFloat = 16
        static let lg:   CGFloat = 20
        static let xl:   CGFloat = 24
        static let xxl:  CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // ─────────────────────────────────────────────
    // MARK: Corner Radius
    // ─────────────────────────────────────────────
    // xs   8   tags, badges, input accessory chips
    // sm   12  text fields, small inline buttons
    // md   16  standard CTAs, dropdown buttons
    // lg   20  cards, prominent quick-action buttons
    // xl   28  hero cards, bottom sheets
    // pill 999 fully rounded / capsule shape

    enum Radius {
        static let xs:   CGFloat = 8
        static let sm:   CGFloat = 12
        static let md:   CGFloat = 16
        static let lg:   CGFloat = 20
        static let xl:   CGFloat = 28
        static let pill: CGFloat = 999
    }

    // ─────────────────────────────────────────────
    // MARK: Size
    // ─────────────────────────────────────────────
    enum Size {
        // Tap targets
        static let touchTarget:   CGFloat = 44  // HIG minimum for any interactive element
        // Buttons
        static let buttonHeight:  CGFloat = 56  // primary & secondary CTAs
        static let buttonHeightSm: CGFloat = 44 // secondary inline / compact actions
        // Fields
        static let fieldHeight:   CGFloat = 52
        // Icons
        static let iconSm:        CGFloat = 20  // accessory icons in row cells
        static let iconMd:        CGFloat = 28  // card / cell leading icons
        static let iconLg:        CGFloat = 48  // empty-state illustrations
        // Avatars
        static let avatarSm:      CGFloat = 36  // compact list rows
        static let avatarMd:      CGFloat = 48  // standard cells
        static let avatarLg:      CGFloat = 72  // profile header
        // Misc
        static let progressHeight: CGFloat = 4
    }

    // ─────────────────────────────────────────────
    // MARK: Elevation
    // ─────────────────────────────────────────────
    // Three named levels replace the old flat Shadow enum.
    // l1 — chips, small cards, filter pills
    // l2 — standard content cards (use applyCardStyle)
    // l3 — modals, bottom sheets, popovers

    enum Elevation {
        static let l1Opacity: Float   = 0.08;  static let l1Radius: CGFloat = 6;  static let l1Offset = CGSize(width: 0, height: 2)
        static let l2Opacity: Float   = 0.12;  static let l2Radius: CGFloat = 10; static let l2Offset = CGSize(width: 0, height: 4)
        static let l3Opacity: Float   = 0.18;  static let l3Radius: CGFloat = 16; static let l3Offset = CGSize(width: 0, height: 8)
    }

    // Backward-compat aliases — new code should use Elevation directly.
    enum Shadow {
        static let cardOpacity:      Float    = Elevation.l2Opacity
        static let cardRadius:       CGFloat  = Elevation.l2Radius
        static let cardOffset:       CGSize   = Elevation.l2Offset
        static let smallCardOpacity: Float    = Elevation.l1Opacity
        static let smallCardRadius:  CGFloat  = Elevation.l1Radius
        static let smallCardOffset:  CGSize   = Elevation.l1Offset
    }

    // ─────────────────────────────────────────────
    // MARK: Color
    // ─────────────────────────────────────────────
    enum Color {

        // Brand
        static let primary      = UIColor.systemBlue
        static let onPrimary    = UIColor.white

        // Tonal fills (primary color at reduced opacity — for secondary CTAs, selected states)
        static let primaryTonal  = UIColor.systemBlue.withAlphaComponent(0.12)
        static let primarySubtle = UIColor.systemBlue.withAlphaComponent(0.07)

        // Surfaces (light = white hierarchy; dark = dark hierarchy)
        static let surface         = UIColor.systemBackground           // cards, sheets
        static let surfaceElevated = UIColor.secondarySystemBackground  // elevated cards, input backgrounds
        static let groupedBackground = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.09, blue: 0.12, alpha: 1.0)
                : (UIColor(named: "Color") ?? UIColor.systemGroupedBackground)
        }

        // Semantic
        static let success          = UIColor.systemGreen
        static let successTonal     = UIColor.systemGreen.withAlphaComponent(0.12)
        static let destructive      = UIColor.systemRed
        static let destructiveTonal = UIColor.systemRed.withAlphaComponent(0.12)
        static let warning          = UIColor.systemOrange
        static let warningTonal     = UIColor.systemOrange.withAlphaComponent(0.12)

        // Text
        static let textPrimary   = UIColor.label
        static let textSecondary = UIColor.secondaryLabel
        static let textTertiary  = UIColor.tertiaryLabel
        static let placeholder   = UIColor.placeholderText

        // Borders & dividers
        static let border        = UIColor.systemGray4
        static let borderSubtle  = UIColor.systemGray5
        static let divider       = UIColor.separator

        // Fills
        static let fieldBackground = UIColor.secondarySystemBackground
        static let progressTrack   = UIColor.systemGray5
        static let overlay         = UIColor.black.withAlphaComponent(0.4)

        // Shadow base color
        static let shadow = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.35)
                : UIColor.black.withAlphaComponent(0.12)
        }

        // Backward-compat aliases
        static let elevatedSurface = surfaceElevated
    }

    // ─────────────────────────────────────────────
    // MARK: Typography
    // ─────────────────────────────────────────────
    // Scale (size / weight):
    //   display        28 bold     — splash, onboarding hero moment (use once per screen)
    //   largeTitle     22 bold     — screen/section group titles
    //   cardTitle      18 semibold — card and sheet headings
    //   greeting       22 semibold — home screen greeting (not bold — action should dominate)
    //   bodyStrong     17 semibold — emphasized body, CTA labels
    //   body           17 regular  — default reading text
    //   subheadline    15 medium   — supporting text, row subtitles
    //   captionStrong  13 semibold — tags, status badges, small headers
    //   caption        13 regular  — secondary metadata, timestamps
    //   micro          11 medium   — badge counters, legal (use sparingly — 11pt is the floor)

    enum Typography {
        // Screen-level
        static let display    = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let largeTitle = UIFont.systemFont(ofSize: 22, weight: .bold)
        static let greeting   = UIFont.systemFont(ofSize: 22, weight: .semibold)
        static let cardTitle  = UIFont.systemFont(ofSize: 18, weight: .semibold)

        // Body
        static let bodyStrong = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body       = UIFont.systemFont(ofSize: 17, weight: .regular)

        // Supporting
        static let subheadline        = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let subheadlineRegular = UIFont.systemFont(ofSize: 15, weight: .regular)

        // Small
        static let captionStrong = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let caption       = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let micro         = UIFont.systemFont(ofSize: 11, weight: .medium)

        // Functional
        static let action    = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let button    = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let buttonSm  = UIFont.systemFont(ofSize: 15, weight: .semibold)

        // Route pills
        static let pillSelected = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let pillRegular  = UIFont.systemFont(ofSize: 13, weight: .medium)

        // Backward-compat aliases
        static let h1    = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let h2    = display
        static let title = largeTitle
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

    /// Standard content card — Elevation l2. Used on Home, Offer Ride, Join Ride, onboarding steps.
    func applyCardStyle(
        corner: CGFloat = AppDesign.Radius.lg,
        shadowOpacity: Float = AppDesign.Elevation.l2Opacity,
        shadowRadius: CGFloat = AppDesign.Elevation.l2Radius,
        shadowOffset: CGSize = AppDesign.Elevation.l2Offset
    ) {
        layer.cornerRadius = corner
        layer.masksToBounds = false
        layer.shadowColor = AppDesign.Color.shadow.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        backgroundColor = AppDesign.Color.surface
    }

    /// Chip / filter card — Elevation l1. Used on filter pills, dropdowns, suggestion rows.
    func applySmallCard(corner: CGFloat = AppDesign.Radius.md) {
        layer.cornerRadius = corner
        layer.masksToBounds = false
        layer.shadowColor = AppDesign.Color.shadow.cgColor
        layer.shadowOpacity = AppDesign.Elevation.l1Opacity
        layer.shadowRadius = AppDesign.Elevation.l1Radius
        layer.shadowOffset = AppDesign.Elevation.l1Offset
        backgroundColor = AppDesign.Color.surfaceElevated
    }

    /// Modal / bottom-sheet card — Elevation l3. Used on sheets, alert containers.
    func applySheetStyle(corner: CGFloat = AppDesign.Radius.xl) {
        layer.cornerRadius = corner
        layer.masksToBounds = false
        layer.shadowColor = AppDesign.Color.shadow.cgColor
        layer.shadowOpacity = AppDesign.Elevation.l3Opacity
        layer.shadowRadius = AppDesign.Elevation.l3Radius
        layer.shadowOffset = AppDesign.Elevation.l3Offset
        backgroundColor = AppDesign.Color.surface
    }

    /// Tonal highlight panel — used for status banners, info strips inside cards.
    func applyTonalPanel(color: UIColor = AppDesign.Color.primary, corner: CGFloat = AppDesign.Radius.sm) {
        layer.cornerRadius = corner
        backgroundColor = color.withAlphaComponent(0.08)
    }
}

enum AppTheme {
    static func applyGlobalAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = AppDesign.Color.surface
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigationAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = AppDesign.Color.primary

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = AppDesign.Color.surface
        tabAppearance.shadowColor = .clear

        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = AppDesign.Color.primary

        UISegmentedControl.appearance().selectedSegmentTintColor = AppDesign.Color.primary
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    static func installRuntimeTheming() {
        UIViewController.installAppThemeHooks()
    }
}

private enum LegacyThemePalette {
    static let pageBlue = UIColor(red: 0.937254902, green: 0.97254902, blue: 1.0, alpha: 1.0)
    static let softGray = UIColor(white: 0.866666667, alpha: 1.0)
    static let lightGray = UIColor(red: 0.97254902, green: 0.97254902, blue: 0.97254902, alpha: 1.0)
    static let cardText = UIColor(red: 0.1215686275, green: 0.1607843137, blue: 0.2156862745, alpha: 1.0)
}

private extension UIColor {
    func isClose(to other: UIColor, in traitCollection: UITraitCollection, tolerance: CGFloat = 0.03) -> Bool {
        let lhs = resolvedColor(with: traitCollection)
        let rhs = other.resolvedColor(with: traitCollection)

        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0

        if lhs.getRed(&lr, green: &lg, blue: &lb, alpha: &la),
           rhs.getRed(&rr, green: &rg, blue: &rb, alpha: &ra) {
            return abs(lr - rr) <= tolerance
                && abs(lg - rg) <= tolerance
                && abs(lb - rb) <= tolerance
                && abs(la - ra) <= tolerance
        }

        var lw: CGFloat = 0
        var rw: CGFloat = 0
        if lhs.getWhite(&lw, alpha: &la), rhs.getWhite(&rw, alpha: &ra) {
            return abs(lw - rw) <= tolerance && abs(la - ra) <= tolerance
        }

        return false
    }
}

private extension UIView {
    func applyLegacyDarkModeFixesIfNeeded() {
        guard traitCollection.userInterfaceStyle == .dark else { return }
        applyLegacyDarkModeFixesRecursively(isRootView: true)
    }

    func applyLegacyDarkModeFixesRecursively(isRootView: Bool) {
        if let currentBackgroundColor = backgroundColor {
            if currentBackgroundColor.isClose(to: LegacyThemePalette.pageBlue, in: traitCollection) {
                backgroundColor = AppDesign.Color.groupedBackground
            } else if currentBackgroundColor.isClose(to: LegacyThemePalette.softGray, in: traitCollection) {
                backgroundColor = AppDesign.Color.fieldBackground
            } else if currentBackgroundColor.isClose(to: LegacyThemePalette.lightGray, in: traitCollection) {
                backgroundColor = isRootView ? AppDesign.Color.groupedBackground : AppDesign.Color.elevatedSurface
            } else if currentBackgroundColor.isClose(to: .white, in: traitCollection) {
                backgroundColor = isRootView ? AppDesign.Color.groupedBackground : AppDesign.Color.surface
            }
        }

        if let label = self as? UILabel,
           let currentTextColor = label.textColor,
           currentTextColor.isClose(to: LegacyThemePalette.cardText, in: traitCollection) {
            label.textColor = .label
        }

        if let textField = self as? UITextField,
           let currentBackgroundColor = textField.backgroundColor,
           (currentBackgroundColor.isClose(to: LegacyThemePalette.softGray, in: traitCollection)
            || currentBackgroundColor.isClose(to: LegacyThemePalette.lightGray, in: traitCollection)) {
            textField.backgroundColor = AppDesign.Color.fieldBackground
            textField.textColor = .label
        }

        if let textView = self as? UITextView,
           let currentBackgroundColor = textView.backgroundColor,
           currentBackgroundColor.isClose(to: LegacyThemePalette.lightGray, in: traitCollection) {
            textView.backgroundColor = AppDesign.Color.fieldBackground
            textView.textColor = .label
        }

        if let tableView = self as? UITableView,
           let currentBackgroundColor = tableView.backgroundColor,
           (currentBackgroundColor.isClose(to: .white, in: traitCollection)
            || currentBackgroundColor.isClose(to: LegacyThemePalette.pageBlue, in: traitCollection)
            || currentBackgroundColor.isClose(to: LegacyThemePalette.lightGray, in: traitCollection)) {
            tableView.backgroundColor = AppDesign.Color.groupedBackground
        }

        if let collectionView = self as? UICollectionView,
           let currentBackgroundColor = collectionView.backgroundColor,
           (currentBackgroundColor.isClose(to: .white, in: traitCollection)
            || currentBackgroundColor.isClose(to: LegacyThemePalette.pageBlue, in: traitCollection)) {
            collectionView.backgroundColor = AppDesign.Color.groupedBackground
        }

        for subview in subviews {
            subview.applyLegacyDarkModeFixesRecursively(isRootView: false)
        }
    }
}

private extension UIViewController {
    static let appThemeHooksInstalled: Void = {
        let originalViewDidLoad = class_getInstanceMethod(UIViewController.self, #selector(viewDidLoad))
        let themedViewDidLoad = class_getInstanceMethod(UIViewController.self, #selector(uniride_viewDidLoad))
        if let originalViewDidLoad, let themedViewDidLoad {
            method_exchangeImplementations(originalViewDidLoad, themedViewDidLoad)
        }

        let originalTraitCollectionDidChange = class_getInstanceMethod(
            UIViewController.self,
            #selector(traitCollectionDidChange(_:))
        )
        let themedTraitCollectionDidChange = class_getInstanceMethod(
            UIViewController.self,
            #selector(uniride_traitCollectionDidChange(_:))
        )
        if let originalTraitCollectionDidChange, let themedTraitCollectionDidChange {
            method_exchangeImplementations(originalTraitCollectionDidChange, themedTraitCollectionDidChange)
        }
    }()

    static func installAppThemeHooks() {
        _ = appThemeHooksInstalled
    }

    @objc func uniride_viewDidLoad() {
        uniride_viewDidLoad()
        applyRuntimeThemeIfNeeded()
    }

    @objc func uniride_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        uniride_traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
        applyRuntimeThemeIfNeeded()
    }

    func applyRuntimeThemeIfNeeded() {
        guard isViewLoaded else { return }
        guard Bundle(for: type(of: self)) == .main else { return }
        view.applyLegacyDarkModeFixesIfNeeded()
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

    /// Secondary prominent CTA — tonal fill (primary@12%) + primary border.
    /// Use for co-equal actions like "Offer Ride" paired with a primary "Find a Ride".
    func applyProminentSecondaryCTA(
        title: String,
        color: UIColor = AppDesign.Color.primary,
        corner: CGFloat = AppDesign.Radius.lg,
        borderWidth: CGFloat = 1.5
    ) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = AppDesign.Color.primaryTonal
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

    /// Compact secondary action — 44pt height, smaller font. Use inside cards or rows.
    func applyCompactSecondaryButton(
        title: String,
        color: UIColor = AppDesign.Color.primary,
        corner: CGFloat = AppDesign.Radius.md
    ) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = AppDesign.Color.primaryTonal
        config.baseForegroundColor = color
        config.cornerStyle = .fixed
        config.background.cornerRadius = corner
        config.background.strokeColor = color.withAlphaComponent(0.4)
        config.background.strokeWidth = 1
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.buttonSm
            return out
        }
        configuration = config
        setMinimumHeight(AppDesign.Size.buttonHeightSm, for: self)
        applyPressMicroInteraction(scale: 0.97, hapticStyle: .light)
    }

    /// Destructive primary CTA — red fill. Use only for irreversible actions (Delete, Cancel Ride).
    func applyDestructiveButton(corner: CGFloat = AppDesign.Radius.md) {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AppDesign.Color.destructive
        config.baseForegroundColor = AppDesign.Color.onPrimary
        config.cornerStyle = .fixed
        config.background.cornerRadius = corner
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.bodyStrong
            return out
        }
        configuration = config
        setMinimumHeight(AppDesign.Size.buttonHeight, for: self)
        applyPressMicroInteraction(scale: 0.97, hapticStyle: .medium)
    }

    /// Non-interactive disabled-state button (offered, already requested, full, conflict).
    /// Use instead of hardcoding .systemGray4 / .systemGray5.
    func applyDisabledCTA(title: String, corner: CGFloat = AppDesign.Radius.md) {
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseBackgroundColor = AppDesign.Color.borderSubtle
        cfg.baseForegroundColor = AppDesign.Color.textSecondary
        cfg.cornerStyle = .fixed
        cfg.background.cornerRadius = corner
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = AppDesign.Typography.bodyStrong
            return out
        }
        configuration = cfg
        isEnabled = false
        isUserInteractionEnabled = false
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
        layer.cornerRadius = AppDesign.Radius.md
        backgroundColor = AppDesign.Color.fieldBackground
        setLeftPaddingPoints(14)
        setMinimumHeight(AppDesign.Size.fieldHeight, for: self)
    }

    /// Add SF Symbol icon inside the left
    func addLeftIcon(_ systemName: String, tint: UIColor = .systemGray) {
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = tint
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

    /// Base setter — use named semantic wrappers below wherever possible.
    func applyTextStyle(
        _ font: UIFont,
        color: UIColor = AppDesign.Color.textPrimary,
        lines: Int = 1
    ) {
        self.font = font
        textColor = color
        numberOfLines = lines
    }

    /// Screen/section group title (22pt bold). For section headers and nav push titles.
    func applyLargeTitleStyle(lines: Int = 1) {
        applyTextStyle(AppDesign.Typography.largeTitle, lines: lines)
    }

    /// Card or sheet heading (18pt semibold). The primary label inside a card.
    func applyCardTitleStyle(lines: Int = 1) {
        applyTextStyle(AppDesign.Typography.cardTitle, lines: lines)
    }

    /// Home screen greeting (22pt semibold, not bold — lets actions dominate).
    func applyGreetingStyle() {
        applyTextStyle(AppDesign.Typography.greeting)
    }

    /// Supporting metadata under a title (15pt medium, secondaryLabel).
    func applySubheadlineStyle(lines: Int = 1) {
        applyTextStyle(AppDesign.Typography.subheadline, color: AppDesign.Color.textSecondary, lines: lines)
    }

    /// Tag / badge label (13pt semibold). For status chips, category labels.
    func applyCaptionStrongStyle(color: UIColor = AppDesign.Color.textSecondary) {
        applyTextStyle(AppDesign.Typography.captionStrong, color: color)
    }

    /// Secondary metadata (13pt regular, tertiaryLabel). For timestamps, ride distance, etc.
    func applyCaptionStyle(lines: Int = 0) {
        applyTextStyle(AppDesign.Typography.caption, color: AppDesign.Color.textTertiary, lines: lines)
    }
}

// MARK: - Divider
extension UIView {
    /// One-line horizontal rule. Pin leading/trailing to parent and call this.
    static func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = AppDesign.Color.divider
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
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
    private struct Associated {
        static var currentURL = "uniride.currentURL"
    }

    private static let imageCache = NSCache<NSURL, UIImage>()

    func loadAndFallback(from url: URL?, name: String) {
        let prevURL = objc_getAssociatedObject(self, &Associated.currentURL) as? URL
        
        // If it's the same URL already loaded, don't clear or reload
        if let url = url, url == prevURL { return }
        
        // Update the tracked URL
        objc_setAssociatedObject(self, &Associated.currentURL, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Clear current image to avoid flicker of OLD post content on a reused cell
        self.image = nil
        
        guard let url = url else {
            self.image = UIImage.generatedAvatar(for: name, size: self.bounds.size.width > 0 ? self.bounds.size : CGSize(width: 40, height: 40))
            return
        }
        
        // Check Cache
        if let cached = UIImageView.imageCache.object(forKey: url as NSURL) {
            self.image = cached
            return
        }
        
        // Use a background task to load data
        let currentID = url // capture for verification
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                UIImageView.imageCache.setObject(image, forKey: url as NSURL)
                DispatchQueue.main.async {
                    // Only apply if the URL hasn't changed on this reused cell
                    let latestURL = objc_getAssociatedObject(self as Any, &Associated.currentURL) as? URL
                    if latestURL == currentID {
                        self?.image = image
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let latestURL = objc_getAssociatedObject(self as Any, &Associated.currentURL) as? URL
                    if latestURL == currentID {
                        self?.image = UIImage.generatedAvatar(for: name, size: self?.bounds.size.width ?? 0 > 0 ? self?.bounds.size ?? .zero : CGSize(width: 40, height: 40))
                    }
                }
            }
        }
    }
}

// MARK: - Loading Overlay
extension UIViewController {
    private struct LoadingConstants {
        static let loaderTag = 999123
    }

    /// Shows a elegant fullscreen loading overlay with a blur effect and message
    func showAppLoading(message: String = "Please wait...") {
        // Ensure only one loader is shown at a time
        if view.viewWithTag(LoadingConstants.loaderTag) != nil {
            hideAppLoading()
        }

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .clear
        overlay.tag = LoadingConstants.loaderTag
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        
        let blurEffect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .dark ? .dark : .extraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlay.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.addSubview(blurView)

        let container = UIView()
        container.backgroundColor = AppDesign.Color.surface.withAlphaComponent(0.85)
        container.layer.cornerRadius = AppDesign.Radius.md
        container.applySmallCard() // Adds subtle shadow
        container.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(container)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppDesign.Color.primary
        spinner.startAnimating()
        stack.addArrangedSubview(spinner)

        let label = UILabel()
        label.text = message
        label.font = AppDesign.Typography.subheadline
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        stack.addArrangedSubview(label)

        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            container.widthAnchor.constraint(lessThanOrEqualTo: overlay.widthAnchor, constant: -80),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])

        UIView.animate(withDuration: 0.25) {
            overlay.alpha = 1.0
        }
    }

    /// Dismisess the loading overlay with an animation
    func hideAppLoading() {
        guard let loader = view.viewWithTag(LoadingConstants.loaderTag) else { return }
        UIView.animate(withDuration: 0.2, animations: {
            loader.alpha = 0
        }) { _ in
            loader.removeFromSuperview()
        }
    }
}
