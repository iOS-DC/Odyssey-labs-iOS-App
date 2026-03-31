//
//  UpcomingTableViewCell.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 17/12/25.
//

import UIKit

class UpcomingTableHomeViewCell: UITableViewCell {

    // MARK: - Storyboard outlets (kept for backward compat, hidden)
    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var viewDetailsButton: UIButton!

    var onTap: (() -> Void)?

    // MARK: - Programmatic views
    private let card         = UIView()
    private let fromIcon     = UIImageView()
    private let fromLbl      = UILabel()
    private let toIcon       = UIImageView()
    private let toLbl        = UILabel()
    private let clockIcon    = UIImageView()
    private let timeLbl      = UILabel()
    private let dateLbl      = UILabel()
    private let detailsBtn   = UIButton(type: .system)
    private let liveBadge    = UILabel()

    private var didSetupUI = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Hide old XIB views
        cardContainerView?.isHidden = true

        selectionStyle  = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupProgrammaticUI()
    }

    // MARK: - UI Setup

    private func setupProgrammaticUI() {
        guard !didSetupUI else { return }
        didSetupUI = true

        // Card
        card.backgroundColor = .systemBackground
        card.applyCardStyle()
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        // Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        // ── Route row ──────────────────────────────────────────
        // From icon
        fromIcon.image = UIImage(systemName: "circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 7, weight: .bold))
        fromIcon.tintColor = AppDesign.Color.primary
        fromIcon.contentMode = .scaleAspectFit
        fromIcon.translatesAutoresizingMaskIntoConstraints = false
        fromIcon.setContentHuggingPriority(.required, for: .horizontal)

        // From label
        fromLbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        fromLbl.textColor = .label
        fromLbl.lineBreakMode = .byWordWrapping
        fromLbl.numberOfLines = 2
        fromLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // To icon
        toIcon.image = UIImage(systemName: "circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 7, weight: .bold))
        toIcon.tintColor = UIColor(red: 0.92, green: 0.35, blue: 0.35, alpha: 1)
        toIcon.contentMode = .scaleAspectFit
        toIcon.translatesAutoresizingMaskIntoConstraints = false
        toIcon.setContentHuggingPriority(.required, for: .horizontal)

        toLbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        toLbl.textColor = .label
        toLbl.lineBreakMode = .byWordWrapping
        toLbl.numberOfLines = 2
        toLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Route row — give from and to equal halves with arrow centered
        let fromStack = UIStackView(arrangedSubviews: [fromIcon, fromLbl])
        fromStack.axis = .horizontal
        fromStack.spacing = 6
        fromStack.alignment = .center

        let toStack = UIStackView(arrangedSubviews: [toIcon, toLbl])
        toStack.axis = .horizontal
        toStack.spacing = 6
        toStack.alignment = .center

        let routeRow = UIStackView(arrangedSubviews: [fromStack, toStack])
        routeRow.axis = .horizontal
        routeRow.alignment = .top
        routeRow.distribution = .fillEqually
        routeRow.spacing = 12

        // ── Details row ────────────────────────────────────────
        // Clock + time
        clockIcon.image = UIImage(systemName: "clock")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        clockIcon.tintColor = .tertiaryLabel
        clockIcon.contentMode = .scaleAspectFit
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true

        timeLbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        timeLbl.textColor = .tertiaryLabel
        timeLbl.adjustsFontSizeToFitWidth = true
        timeLbl.minimumScaleFactor = 0.8

        dateLbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLbl.textColor = .tertiaryLabel
        dateLbl.adjustsFontSizeToFitWidth = true
        dateLbl.minimumScaleFactor = 0.8

        let timeStack = UIStackView(arrangedSubviews: [clockIcon, timeLbl, dateLbl])
        timeStack.axis = .horizontal
        timeStack.spacing = 4
        timeStack.alignment = .center
        timeStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // View details
        detailsBtn.setTitle("View Details ›", for: .normal)
        detailsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        detailsBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        detailsBtn.titleLabel?.minimumScaleFactor = 0.8
        detailsBtn.setTitleColor(AppDesign.Color.primary, for: .normal)
        detailsBtn.setContentHuggingPriority(.required, for: .horizontal)
        detailsBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailsBtn.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        let detailsRow = UIStackView(arrangedSubviews: [timeStack, spacer, detailsBtn])
        detailsRow.axis = .horizontal
        detailsRow.alignment = .center

        // ── Separator ──────────────────────────────────────────
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        // ── Main stack ─────────────────────────────────────────
        let mainStack = UIStackView(arrangedSubviews: [routeRow, sep, detailsRow])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(mainStack)

        // Live badge (hidden by default)
        liveBadge.text = "  ● Live  "
        liveBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        liveBadge.textColor = .white
        liveBadge.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        liveBadge.layer.cornerRadius = 10
        liveBadge.layer.masksToBounds = true
        liveBadge.isHidden = true
        liveBadge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(liveBadge)

        // Constraints
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            liveBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            liveBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: -6)
        ])
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        let ride = trip.ride

        let fromText = formatLocation(ride.source.address)
        let toText   = formatLocation(ride.destination.address)

        fromLbl.text = fromText
        toLbl.text   = (fromText == toText) ? "Nearby" : toText

        // Also set XIB labels in case anything else reads them
        fromLabel?.text = fromLbl.text
        toLabel?.text   = toLbl.text

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        timeLbl.text = timeFormatter.string(from: ride.departureTime)
        timeLabel?.text = timeLbl.text

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateStr = dateFormatter.string(from: ride.departureTime)
        if Calendar.current.isDateInToday(ride.departureTime) {
            dateLbl.text = "• Today"
        } else if Calendar.current.isDateInTomorrow(ride.departureTime) {
            dateLbl.text = "• Tomorrow"
        } else {
            dateLbl.text = "• \(dateStr)"
        }

        // Live badge
        liveBadge.isHidden = ride.status != .ongoing

        viewDetailsButton?.setTitle("View More Details", for: .normal)
    }

    @objc private func handleTap() {
        onTap?()
    }

    private func formatLocation(_ address: String?) -> String {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else { return "Campus" }
        // Take text before the first comma
        let shortName = address.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces) ?? address
        // If it fits comfortably, use it; otherwise use just the first word
        if shortName.count <= 15 {
            return shortName
        }
        return shortName.components(separatedBy: " ").first ?? shortName
    }
}
