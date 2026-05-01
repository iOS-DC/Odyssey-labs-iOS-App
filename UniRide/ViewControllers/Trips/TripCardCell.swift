import UIKit

final class TripCardCell: UITableViewCell {

    static let reuseID = "TripCardCell"

    // MARK: - Subviews

    private let cardView = UIView()
    private let heroImageView = UIImageView()
    private let titleLabel = UILabel()
    private let locationRow = UIStackView()
    private let locationLabel = UILabel()
    private let dateRow = UIStackView()
    private let dateLabel = UILabel()
    private let priceLabel = UILabel()
    private let spotsLabel = UILabel()
    private let organizerLabel = UILabel()
    private let divider = UIView()
    private let likeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let joinButton = UIButton()

    var onLike: (() -> Void)?
    var onShare: (() -> Void)?
    var onJoin: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with trip: Trip) {
        heroImageView.loadImage(from: trip.imageName)
        titleLabel.text = trip.title
        locationLabel.text = trip.location
        dateLabel.text = trip.dateRange
        priceLabel.text = trip.priceFormatted

        if trip.spotsLeft > 0 {
            let msg = "\(trip.spotsLeft) spot\(trip.spotsLeft == 1 ? "" : "s") left"
            let attr = NSAttributedString(string: msg, attributes: [
                .foregroundColor: UIColor.systemOrange,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ])
            spotsLabel.attributedText = attr
            spotsLabel.isHidden = false
        } else {
            spotsLabel.isHidden = true
        }

        organizerLabel.text = "by \(trip.organizer)"

        let heartName = trip.isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: heartName), for: .normal)
        likeButton.tintColor = trip.isLiked ? .systemRed : .secondaryLabel

        var joinCfg = UIButton.Configuration.filled()
        joinCfg.cornerStyle = .capsule
        joinCfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        joinCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        if trip.isPast {
            joinCfg.title = "Completed"
            joinCfg.baseBackgroundColor = .systemGray4
            joinCfg.baseForegroundColor = .white
            joinButton.isEnabled = false
        } else {
            joinCfg.title = "Join Now"
            joinCfg.baseBackgroundColor = AppDesign.Color.primary
            joinCfg.baseForegroundColor = .white
            joinButton.isEnabled = true
        }
        joinButton.configuration = joinCfg
    }

    // MARK: - Actions

    @objc private func likeTapped() { onLike?() }
    @objc private func shareTapped() { onShare?() }
    @objc private func joinTapped() { onJoin?() }

    // MARK: - Layout

    private func build() {
        // Card container
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = AppDesign.Radius.lg
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = AppDesign.Shadow.cardOpacity
        cardView.layer.shadowOffset = AppDesign.Shadow.cardOffset
        cardView.layer.shadowRadius = AppDesign.Shadow.cardRadius
        cardView.clipsToBounds = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Clip inner content
        let innerClip = UIView()
        innerClip.layer.cornerRadius = AppDesign.Radius.lg
        innerClip.clipsToBounds = true
        innerClip.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(innerClip)

        // Hero image
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.backgroundColor = .systemGray5
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(heroImageView)

        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(titleLabel)

        // Location row
        let pinIcon = makeIconView("mappin.and.ellipse", color: .secondaryLabel, size: 15)
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        locationLabel.textColor = .secondaryLabel
        locationRow.axis = .horizontal
        locationRow.spacing = 4
        locationRow.alignment = .center
        locationRow.addArrangedSubview(pinIcon)
        locationRow.addArrangedSubview(locationLabel)
        locationRow.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(locationRow)

        // Date row
        let calIcon = makeIconView("calendar", color: .secondaryLabel, size: 15)
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel
        dateRow.axis = .horizontal
        dateRow.spacing = 4
        dateRow.alignment = .center
        dateRow.addArrangedSubview(calIcon)
        dateRow.addArrangedSubview(dateLabel)
        dateRow.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(dateRow)

        // Price
        priceLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        priceLabel.textColor = AppDesign.Color.primary
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(priceLabel)

        // Spots
        spotsLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        spotsLabel.textColor = .systemOrange
        spotsLabel.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(spotsLabel)

        // Organizer
        organizerLabel.font = UIFont.systemFont(ofSize: 13)
        organizerLabel.textColor = .tertiaryLabel
        organizerLabel.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(organizerLabel)

        // Divider
        divider.backgroundColor = UIColor.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(divider)

        // Like / Share buttons
        likeButton.tintColor = .secondaryLabel
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(likeButton)

        shareButton.tintColor = .secondaryLabel
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(shareButton)

        // Join Now button — use UIButton.Configuration (contentEdgeInsets is deprecated iOS 15+)
        var joinCfg = UIButton.Configuration.filled()
        joinCfg.title = "Join Now"
        joinCfg.baseForegroundColor = .white
        joinCfg.baseBackgroundColor = AppDesign.Color.primary
        joinCfg.cornerStyle = .capsule
        joinCfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        joinCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        joinButton.configuration = joinCfg
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        innerClip.addSubview(joinButton)

        NSLayoutConstraint.activate([
            // Card fills cell with padding
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDesign.Spacing.md),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDesign.Spacing.md),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // innerClip matches card exactly (for shadow to show outside)
            innerClip.topAnchor.constraint(equalTo: cardView.topAnchor),
            innerClip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            innerClip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            innerClip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Hero image
            heroImageView.topAnchor.constraint(equalTo: innerClip.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: innerClip.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 200),

            // Title
            titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: AppDesign.Spacing.md),
            titleLabel.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),
            titleLabel.trailingAnchor.constraint(equalTo: innerClip.trailingAnchor, constant: -AppDesign.Spacing.md),

            // Location
            locationRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppDesign.Spacing.xs),
            locationRow.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),
            locationRow.trailingAnchor.constraint(lessThanOrEqualTo: innerClip.trailingAnchor, constant: -AppDesign.Spacing.md),

            // Date
            dateRow.topAnchor.constraint(equalTo: locationRow.bottomAnchor, constant: AppDesign.Spacing.xxs),
            dateRow.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),

            // Price
            priceLabel.topAnchor.constraint(equalTo: dateRow.bottomAnchor, constant: AppDesign.Spacing.sm),
            priceLabel.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),

            // Spots
            spotsLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            spotsLabel.trailingAnchor.constraint(equalTo: innerClip.trailingAnchor, constant: -AppDesign.Spacing.md),

            // Organizer
            organizerLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: AppDesign.Spacing.xxs),
            organizerLabel.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),

            // Divider
            divider.topAnchor.constraint(equalTo: organizerLabel.bottomAnchor, constant: AppDesign.Spacing.sm),
            divider.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),
            divider.trailingAnchor.constraint(equalTo: innerClip.trailingAnchor, constant: -AppDesign.Spacing.md),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            // Like button — anchored explicitly, determines bottom of card
            likeButton.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: AppDesign.Spacing.sm),
            likeButton.leadingAnchor.constraint(equalTo: innerClip.leadingAnchor, constant: AppDesign.Spacing.md),
            likeButton.widthAnchor.constraint(equalToConstant: 36),
            likeButton.heightAnchor.constraint(equalToConstant: 36),
            likeButton.bottomAnchor.constraint(equalTo: innerClip.bottomAnchor, constant: -AppDesign.Spacing.sm),

            // Share button
            shareButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            shareButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: AppDesign.Spacing.sm),
            shareButton.widthAnchor.constraint(equalToConstant: 36),
            shareButton.heightAnchor.constraint(equalToConstant: 36),

            // Join Now — right-aligned, centered with like/share row
            joinButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            joinButton.trailingAnchor.constraint(equalTo: innerClip.trailingAnchor, constant: -AppDesign.Spacing.md),
        ])
    }

    private func makeIconView(_ systemName: String, color: UIColor, size: CGFloat) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = color
        iv.contentMode = .scaleAspectFit
        iv.widthAnchor.constraint(equalToConstant: size).isActive = true
        iv.heightAnchor.constraint(equalToConstant: size).isActive = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }
}
