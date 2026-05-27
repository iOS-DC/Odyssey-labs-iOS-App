import UIKit

/// Reusable section header for the Home table.
/// Layout (label + optional "See All" button) is in `HomeSectionHeaderView.xib`.
/// Dynamic typography is applied in code because design tokens are runtime values.
final class HomeSectionHeaderView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!

    var onSeeAllTapped: (() -> Void)?

    /// Loads a fresh instance from the XIB.
    static func loadFromNib() -> HomeSectionHeaderView {
        let nib = UINib(nibName: "HomeSectionHeaderView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? HomeSectionHeaderView else {
            fatalError("Could not load HomeSectionHeaderView from XIB")
        }
        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        seeAllButton.titleLabel?.font = AppDesign.Typography.captionStrong
        seeAllButton.tintColor = AppDesign.Color.primary
    }

    func configure(title: String, showSeeAll: Bool) {
        titleLabel.text = title
        seeAllButton.isHidden = !showSeeAll
    }

    @IBAction func seeAllPressed(_ sender: UIButton) {
        onSeeAllTapped?()
    }
}
