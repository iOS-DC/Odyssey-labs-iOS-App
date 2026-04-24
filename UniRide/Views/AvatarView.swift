import UIKit

/// Shared avatar image view with consistent sizing, border, and initials fallback.
/// Replaces 9+ duplicated avatar setups across the app.
final class AvatarView: UIImageView {

    enum Size: CGFloat {
        case sm = 36
        case md = 48
        case lg = 72
        case xl = 96
    }

    init(size: Size) {
        super.init(frame: .zero)
        let s = size.rawValue
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = s / 2
        layer.borderWidth = size == .xl ? 3 : (size == .lg ? 2.5 : 2)
        layer.borderColor = AppDesign.Color.primary.withAlphaComponent(0.25).cgColor
        backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.12)
        tintColor = AppDesign.Color.primary
        image = UIImage(systemName: "person.crop.circle.fill")
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: s),
            heightAnchor.constraint(equalToConstant: s),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func load(from url: URL?, name: String) {
        loadAndFallback(from: url, name: name)
    }
}
