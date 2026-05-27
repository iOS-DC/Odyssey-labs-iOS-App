import UIKit

/// Reusable empty-state row used by the Home table.
/// Layout (a container view that hosts an `EmptyStateView`) comes from
/// `HomeEmptyStateCell.xib`. The actual `EmptyStateView` is built in code
/// because its own typography/colors are dynamic.
final class HomeEmptyStateCell: UITableViewCell {

    static let reuseID = "HomeEmptyStateCell"

    @IBOutlet weak var container: UIView!

    private weak var hostedView: EmptyStateView?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }

    func configure(
        systemImage: String,
        title: String,
        body: String,
        actionTitle: String? = nil,
        tintColor: UIColor = AppDesign.Color.primary,
        onAction: (() -> Void)? = nil
    ) {
        hostedView?.removeFromSuperview()
        let esv = EmptyStateView(
            systemImage: systemImage,
            title: title,
            body: body,
            actionTitle: actionTitle,
            tintColor: tintColor
        )
        esv.onAction = onAction
        esv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(esv)
        NSLayoutConstraint.activate([
            esv.topAnchor.constraint(equalTo: container.topAnchor),
            esv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            esv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            esv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        hostedView = esv
    }
}
