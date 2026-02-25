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

    /// Standard app card (used across Home, Offer Ride, Join Ride)
    func applyCardStyle(
        corner: CGFloat = 20,
        shadowOpacity: Float = 0.08,
        shadowRadius: CGFloat = 12
    ) {
        layer.cornerRadius = corner
        layer.masksToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 6)
        backgroundColor = .systemBackground
    }

    /// Smaller card (filters, dropdowns, suggestions)
    func applySmallCard(corner: CGFloat = 16) {
        layer.cornerRadius = corner
        layer.masksToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        backgroundColor = .systemBackground
    }
}

// MARK: - Buttons
extension UIButton {

    /// Primary filled button (Offer / Join)
    func applyPrimaryButton(
        color: UIColor = .systemBlue,
        radius: CGFloat = 18
    ) {
        layer.cornerRadius = radius
        backgroundColor = color
        setTitleColor(.white, for: .normal)
    }

    /// Secondary outline button
    func applyOutlineButton(corner: CGFloat = 12) {
        layer.cornerRadius = corner
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .clear
        setTitleColor(.label, for: .normal)
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

// MARK: - Route Pills
extension UIButton {

    func applyRoutePill(selected: Bool) {
        titleLabel?.font = selected
            ? UIFont.systemFont(ofSize: 14, weight: .semibold)
            : UIFont.systemFont(ofSize: 13, weight: .medium)

        titleLabel?.numberOfLines = 2
        titleLabel?.textAlignment = .center

        layer.cornerRadius = 14
        layer.masksToBounds = true

        if selected {
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 6
            layer.shadowOffset = CGSize(width: 0, height: 3)
        } else {
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            setTitleColor(.label, for: .normal)
            layer.borderWidth = 1
//            layer.borderColor = UIColor.systemGray4.cgColor
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
