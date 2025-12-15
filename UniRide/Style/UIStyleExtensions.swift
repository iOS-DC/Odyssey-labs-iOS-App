//
//  UIStyleExtensions.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 11/12/25.
//

import Foundation
import UIKit

// MARK: - Cards / Containers
extension UIView {

    /// Rounded card with soft shadow
    func applyCardStyle(corner: CGFloat = 20) {
        layer.cornerRadius = corner
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    /// Small rounded style (e.g. route suggestions / dropdown cards)
    func applySmallCard(corner: CGFloat = 12) {
        layer.cornerRadius = corner
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)
    }
}

// MARK: - Buttons
extension UIButton {

    /// Primary filled button
    func applyPrimaryButton(color: UIColor = .systemGreen, radius: CGFloat = 18) {
        layer.cornerRadius = radius
        setTitleColor(.white, for: .normal)
    }

    /// Secondary outline button
    func applyOutlineButton(corner: CGFloat = 12) {
        layer.cornerRadius = corner
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .clear
    }
}

// MARK: - TextFields
extension UITextField {

    /// Rounded border + padding
    func applyRoundedField() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = UIColor(white: 0.97, alpha: 1)
        setLeftPaddingPoints(14)
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
