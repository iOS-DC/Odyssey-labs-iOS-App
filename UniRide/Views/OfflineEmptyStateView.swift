// OfflineEmptyStateView.swift
// UniRide
// A reusable banner shown whenever there is no internet connection.

import UIKit

final class OfflineEmptyStateView: UIView {

    private let iconImageView = UIImageView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    let retryButton           = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .systemGroupedBackground

        // Icon
        let icon = UIImage(systemName: "wifi.slash")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 52, weight: .light))
        iconImageView.image     = icon
        iconImageView.tintColor = .secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text          = "You're offline"
        titleLabel.font          = AppDesign.Typography.bodyStrong
        titleLabel.textColor     = .label
        titleLabel.textAlignment = .center

        // Subtitle
        subtitleLabel.text          = "Check your Wi-Fi or mobile data, then pull down to refresh."
        subtitleLabel.font          = AppDesign.Typography.subheadline
        subtitleLabel.textColor     = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Retry button
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.backgroundColor  = AppDesign.Color.primary
        retryButton.layer.cornerRadius = 10
        retryButton.contentEdgeInsets  = UIEdgeInsets(top: 10, left: 28, bottom: 10, right: 28)
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel, retryButton])
        stack.axis      = .vertical
        stack.spacing   = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(20, after: iconImageView)
        stack.setCustomSpacing(20, after: subtitleLabel)

        addSubview(stack)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 70),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),
        ])
    }
}
