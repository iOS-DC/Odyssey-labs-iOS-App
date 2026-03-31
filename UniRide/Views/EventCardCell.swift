// EventCardCell.swift
// UniRide

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

    private let gradientView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()
    private var gradientLayer: CAGradientLayer?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        return l
    }()

    private let metaStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 6
        return s
    }()

    private let dateLabel  = EventCardCell.metaLabel()
    private let locLabel   = EventCardCell.metaLabel()

    private let attendeesBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.layer.masksToBounds = true
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return l
    }()

    let attendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        
        var attTitle = AttributedString("Attend")
        attTitle.font = .systemFont(ofSize: 16, weight: .bold)
        config.attributedTitle = attTitle
        
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        
        let b = UIButton(configuration: config)
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
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        // Hero image
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.layer.cornerRadius = 20
        heroImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.addSubview(heroImageView)

        // Gradient overlay
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(gradientView)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // Meta stack
        metaStack.addArrangedSubview(dateLabel)
        metaStack.addArrangedSubview(locLabel)
        metaStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(metaStack)

        // Bottom bar
        attendeesBadge.translatesAutoresizingMaskIntoConstraints = false
        attendButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(attendeesBadge)
        card.addSubview(attendButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Hero image - 16:9 ratio
            heroImageView.topAnchor.constraint(equalTo: card.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 9.0/16.0),

            // Gradient covers bottom half
            gradientView.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: heroImageView.heightAnchor, multiplier: 0.5),

            // Title bottom-left on image
            titleLabel.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            // Meta stack 16pt below image
            metaStack.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 16),
            metaStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            metaStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            // Bottom bar
            attendButton.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 16),
            attendButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            attendButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            attendButton.heightAnchor.constraint(equalToConstant: 38),
            attendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),

            attendeesBadge.centerYAnchor.constraint(equalTo: attendButton.centerYAnchor),
            attendeesBadge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
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
        g.frame = gradientView.bounds
        g.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.40).cgColor]
        g.locations = [0, 1]
        gradientView.layer.insertSublayer(g, at: 0)
        gradientLayer = g
    }

    // MARK: - Configure

    func configure(with event: EventItem, primaryColor: UIColor) {
        if let name = event.imageName, let img = UIImage(named: name) {
            heroImageView.image = img
            heroImageView.backgroundColor = .systemGray6
        } else {
            heroImageView.image = nil
            heroImageView.backgroundColor = primaryColor.withAlphaComponent(0.2)
        }

        titleLabel.text = event.title

        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy  •  h:mm a"
        dateLabel.attributedText = makeMetaString(
            icon: "calendar",
            text: df.string(from: event.startsAt)
        )

        locLabel.attributedText = makeMetaString(
            icon: "mappin.and.ellipse",
            text: event.location?.name ?? "TBA"
        )

        attendeesBadge.text = "  \(event.attendeeCount) attending  "
        attendeesBadge.textColor = primaryColor
        attendeesBadge.backgroundColor = primaryColor.withAlphaComponent(0.10)

        attendButton.configuration?.baseBackgroundColor = primaryColor
    }

    @objc private func attendTapped() {
        delegate?.eventCardCellDidTapAttend(self)
    }

    private func makeMetaString(icon: String, text: String) -> NSAttributedString {
        let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: icon, withConfiguration: cfg)?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
        let result = NSMutableAttributedString(attachment: attachment)
        result.append(NSAttributedString(
            string: "  " + text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
        ))
        return result
    }

    private static func metaLabel() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        return l
    }
}
