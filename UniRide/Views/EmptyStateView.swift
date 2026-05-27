import UIKit

/// Reusable empty-state view. Drop into any UITableView.backgroundView or UIView.
final class EmptyStateView: UIView {

    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    // MARK: - Init

    init(systemImage: String,
         title: String,
         body: String,
         actionTitle: String? = nil,
         tintColor: UIColor = .systemGreen) {
        super.init(frame: .zero)
        configure(systemImage: systemImage,
                  title: title,
                  body: body,
                  actionTitle: actionTitle,
                  tintColor: tintColor)
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(systemImage: String,
                   title: String,
                   body: String,
                   actionTitle: String? = nil,
                   tintColor: UIColor = .systemGreen) {
        iconView.image = UIImage(systemName: systemImage)?
            .withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor.withAlphaComponent(0.6)

        titleLabel.text = title
        bodyLabel.text  = body

        if let actionTitle {
            actionButton.applyTintActionStyle(title: actionTitle, imageSystemName: "arrow.right", color: tintColor)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        backgroundColor = .clear

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 14
        iconView.clipsToBounds = false

        titleLabel.font = AppDesign.Typography.bodyStrong
        titleLabel.textColor = .label.withAlphaComponent(0.6)
        titleLabel.textAlignment = .center

        bodyLabel.font = AppDesign.Typography.subheadline
        bodyLabel.textColor = .tertiaryLabel
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0

        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        stack.axis      = .vertical
        stack.alignment = .center
        stack.spacing   = 10
        stack.setCustomSpacing(6,  after: titleLabel)
        stack.setCustomSpacing(16, after: bodyLabel)
        [iconView, titleLabel, bodyLabel, actionButton].forEach { stack.addArrangedSubview($0) }
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let centerY = stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8)
        centerY.priority = .defaultHigh
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerY,
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 24),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
        ])
    }

    @objc private func buttonTapped() { onAction?() }
}
