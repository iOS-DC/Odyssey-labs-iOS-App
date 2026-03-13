// EventCardCell.swift
// UniRide
// Fully programmatic event card: hero image on top, gradient overlay,
// compact metadata row, and a pill Attend button — no storyboard required.

import UIKit

protocol EventCardCellDelegate: AnyObject {
    func eventCardCellDidTapAttend(_ cell: EventCardCell)
}

final class EventCardCell: UITableViewCell {

    static let reuseID = "EventCardCell_v2"

    weak var delegate: EventCardCellDelegate?

    // MARK: - Subviews

    private let card = UIView()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    // Gradient layer drawn over the bottom of the hero image
    private let gradientView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()
    private var gradientLayer: CAGradientLayer?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        return l
    }()

    private let metaStack: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 4
        return s
    }()

    private let dateLabel  = EventCardCell.metaLabel()
    private let locLabel   = EventCardCell.metaLabel()

    private let attendeesBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textAlignment = .center
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return l
    }()

    let attendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Attend →", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 14
        b.layer.masksToBounds = true
        b.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return b
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func buildLayout() {
        // Card container
        card.backgroundColor    = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = false
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius  = 16
        card.layer.shadowOffset  = CGSize(width: 0, height: 6)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        // Hero image (clips inside card)
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.layer.cornerRadius = 20
        heroImageView.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner
        ]
        card.addSubview(heroImageView)

        // Gradient overlay
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(gradientView)

        // Title lives at bottom of hero
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // Meta stack
        metaStack.addArrangedSubview(dateLabel)
        metaStack.addArrangedSubview(locLabel)
        metaStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(metaStack)

        // Bottom bar: attendees badge + attend button
        attendeesBadge.translatesAutoresizingMaskIntoConstraints = false
        attendButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(attendeesBadge)
        card.addSubview(attendButton)

        // Card edge constraints
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Hero image
            heroImageView.topAnchor.constraint(equalTo: card.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 160),

            // Gradient covers bottom 80pt of hero
            gradientView.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 90),

            // Title — sits at bottom of hero, horizontally inset
            titleLabel.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            // Meta stack below image
            metaStack.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 12),
            metaStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            metaStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            // Bottom bar
            attendButton.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 12),
            attendButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            attendButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            attendButton.heightAnchor.constraint(equalToConstant: 34),
            attendButton.widthAnchor.constraint(equalToConstant: 100),

            attendeesBadge.centerYAnchor.constraint(equalTo: attendButton.centerYAnchor),
            attendeesBadge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            attendeesBadge.heightAnchor.constraint(equalToConstant: 24),
        ])

        attendButton.addTarget(self, action: #selector(attendTapped), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
    }

    private func applyGradient() {
        gradientLayer?.removeFromSuperlayer()
        let g = CAGradientLayer()
        g.frame  = gradientView.bounds
        g.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.68).cgColor]
        g.locations = [0, 1]
        gradientView.layer.insertSublayer(g, at: 0)
        gradientLayer = g
    }

    // MARK: - Configure

    func configure(with event: EventItem, primaryColor: UIColor) {
        // Image
        if let name = event.imageName, let img = UIImage(named: name) {
            heroImageView.image = img
            heroImageView.backgroundColor = .systemGray6
        } else {
            heroImageView.image = nil
            heroImageView.backgroundColor = primaryColor.withAlphaComponent(0.2)
        }

        titleLabel.text = event.title

        // Date
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy  •  h:mm a"
        dateLabel.attributedText = makeMetaString(
            icon: "calendar",
            text: df.string(from: event.startsAt)
        )

        // Location
        locLabel.attributedText = makeMetaString(
            icon: "mappin.and.ellipse",
            text: event.location?.name ?? "TBA"
        )

        // Attendees badge
        attendeesBadge.text = "  \(event.attendeeCount) attending  "
        attendeesBadge.textColor = primaryColor
        attendeesBadge.backgroundColor = primaryColor.withAlphaComponent(0.10)

        // Attend button
        attendButton.backgroundColor = primaryColor
    }

    // MARK: - Actions

    @objc private func attendTapped() {
        delegate?.eventCardCellDidTapAttend(self)
    }

    // MARK: - Helpers

    private func makeMetaString(icon: String, text: String) -> NSAttributedString {
        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: icon, withConfiguration: cfg)?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
        let result = NSMutableAttributedString(attachment: attachment)
        result.append(NSAttributedString(
            string: "  " + text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
        ))
        return result
    }

    private static func metaLabel() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        return l
    }
}
