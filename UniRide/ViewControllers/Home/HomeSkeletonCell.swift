import UIKit

/// Shimmer placeholder row shown while the Home feed is loading.
/// Static layout (card + three bars) lives in `HomeSkeletonCell.xib`.
/// Shadow, corner radius, and the shimmer animation are runtime concerns
/// and stay in code.
final class SkeletonCell: UITableViewCell {

    static let reuseID = "SkeletonCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var bar1: UIView!
    @IBOutlet weak var bar2: UIView!
    @IBOutlet weak var bar3: UIView!

    private var shimmerLayers: [CAGradientLayer] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = AppDesign.Radius.lg
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        cardView.layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        cardView.layer.shadowRadius = AppDesign.Shadow.smallCardRadius

        [bar1, bar2, bar3].forEach {
            $0?.backgroundColor = .systemGray5
            $0?.layer.cornerRadius = 6
        }
    }

    func startAnimating() {
        shimmerLayers.forEach { $0.removeFromSuperlayer() }
        shimmerLayers = []

        [bar1, bar2, bar3].forEach { bar in
            guard let bar else { return }
            let shimmer = CAGradientLayer()
            shimmer.colors = [
                UIColor.systemGray5.cgColor,
                UIColor.systemGray4.withAlphaComponent(0.8).cgColor,
                UIColor.systemGray5.cgColor,
            ]
            shimmer.startPoint = CGPoint(x: 0, y: 0.5)
            shimmer.endPoint   = CGPoint(x: 1, y: 0.5)
            shimmer.locations  = [-1, -0.5, 0]
            shimmer.frame      = bar.bounds
            shimmer.cornerRadius = 6
            bar.layer.addSublayer(shimmer)
            shimmerLayers.append(shimmer)

            let anim = CABasicAnimation(keyPath: "locations")
            anim.fromValue = [-1, -0.5, 0]
            anim.toValue   = [1, 1.5, 2]
            anim.duration  = 1.3
            anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            shimmer.add(anim, forKey: "shimmer")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep shimmer layers in sync with bar frames after layout.
        let bars: [UIView] = [bar1, bar2, bar3].compactMap { $0 }
        zip(bars, shimmerLayers).forEach { bar, shimmer in
            shimmer.frame = bar.bounds
        }
    }
}
