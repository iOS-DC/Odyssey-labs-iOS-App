import UIKit

protocol PastRideCellDelegate: AnyObject {
    func pastRideCellDidTapPerson(_ cell: PastRideCell, user: UserProfile)
}

final class PastRideCell: UITableViewCell {

    static let reuseIdentifier = "PastRideCell"

    // MARK: - Card subviews (all programmatic, no XIB)
    private let cardView       = UIView()
    private let roleChip       = UILabel()
    private let statusChip     = UILabel()
    private let dateLabel      = UILabel()
    private let divider1       = UIView()
    private let fromLabel      = UILabel()
    private let arrowIcon      = UIImageView()
    private let toLabel        = UILabel()
    private let timeLabel      = UILabel()
    private let divider2       = UIView()
    private let sectionHeader  = UILabel()   // "Your driver" / "Passengers (N)"
    private let peopleStack    = UIStackView()
    private let divider3       = UIView()
    private let priceLabel     = UILabel()
    private let totalLabel     = UILabel()
    private var rateBtn: UIButton?
    // Kept so we can restore it in prepareForReuse after addRateButtonIfNeeded deactivates it
    private var priceLabelBottomConstraint: NSLayoutConstraint?

    // MARK: - Data
    var onRateTapped: ((RideDataModel.MyTrip) -> Void)?
    weak var delegate: PastRideCellDelegate?
    private var currentTrip: RideDataModel.MyTrip?

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildCard()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); buildCard() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Robust clearing of stack view
        peopleStack.arrangedSubviews.forEach {
            peopleStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        // Remove rate button if exists
        rateBtn?.removeFromSuperview()
        rateBtn = nil
        onRateTapped = nil
        currentTrip = nil
        // Restore the card's bottom anchor
        priceLabelBottomConstraint?.isActive = true
    }

    // MARK: - Build UI

    private func buildCard() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Card container
        cardView.backgroundColor = .systemBackground
        cardView.applyCardStyle(
            corner: AppDesign.Radius.lg,
            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
            shadowRadius: AppDesign.Shadow.smallCardRadius,
            shadowOffset: AppDesign.Shadow.smallCardOffset
        )
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // People stack (rows of avatar + name)
        peopleStack.axis = .vertical
        peopleStack.spacing = 8
        peopleStack.translatesAutoresizingMaskIntoConstraints = false

        [roleChip, statusChip, dateLabel, divider1,
         fromLabel, arrowIcon, toLabel, timeLabel,
         divider2, sectionHeader, peopleStack,
         divider3, priceLabel, totalLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        // Style & constraints
        styleComponents()
        addConstraints()
    }

    private func styleComponents() {
        // Role chip
        roleChip.font = AppDesign.Typography.captionStrong
        roleChip.textAlignment = .center
        roleChip.layer.cornerRadius = 10
        roleChip.layer.masksToBounds = true

        // Status chip
        statusChip.font = AppDesign.Typography.captionStrong
        statusChip.textAlignment = .center
        statusChip.layer.cornerRadius = 10
        statusChip.layer.masksToBounds = true

        // Date
        dateLabel.font = AppDesign.Typography.caption
        dateLabel.textColor = .tertiaryLabel
        dateLabel.textAlignment = .right
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Dividers
        [divider1, divider2, divider3].forEach { $0.backgroundColor = AppDesign.Color.border }

        // From / To / Arrow
        fromLabel.font = AppDesign.Typography.bodyStrong
        fromLabel.numberOfLines = 2
        fromLabel.adjustsFontSizeToFitWidth = true
        fromLabel.minimumScaleFactor = 0.8
        fromLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        arrowIcon.image = UIImage(systemName: "arrow.right")
        arrowIcon.tintColor = AppDesign.Color.primary
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)

        toLabel.font = AppDesign.Typography.bodyStrong
        toLabel.numberOfLines = 2
        toLabel.adjustsFontSizeToFitWidth = true
        toLabel.minimumScaleFactor = 0.8
        toLabel.textAlignment = .right
        toLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Time
        timeLabel.font = AppDesign.Typography.caption
        timeLabel.textColor = .secondaryLabel

        // Section header
        sectionHeader.font = AppDesign.Typography.captionStrong
        sectionHeader.textColor = .tertiaryLabel

        // Price labels
        priceLabel.font = AppDesign.Typography.subheadline
        priceLabel.textColor = .label

        totalLabel.font = AppDesign.Typography.subheadline
        totalLabel.textColor = AppDesign.Color.success
        totalLabel.textAlignment = .right
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func addConstraints() {
        let P: CGFloat = 16  // padding

        // Card bottom anchored to priceLabel — stored so prepareForReuse can restore it
        let priceBottom = priceLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -P)
        priceLabelBottomConstraint = priceBottom
        NSLayoutConstraint.activate([
            // Card insets
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // ── Row 1: role + date + status ──
            roleChip.topAnchor.constraint(equalTo: cardView.topAnchor, constant: P),
            roleChip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            roleChip.heightAnchor.constraint(equalToConstant: 24),

            statusChip.topAnchor.constraint(equalTo: cardView.topAnchor, constant: P),
            statusChip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),
            statusChip.heightAnchor.constraint(equalToConstant: 24),
            statusChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),

            dateLabel.centerYAnchor.constraint(equalTo: roleChip.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: statusChip.leadingAnchor, constant: -8),

            // ── Divider 1 ──
            divider1.topAnchor.constraint(equalTo: roleChip.bottomAnchor, constant: 12),
            divider1.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            divider1.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            // ── From → To ──
            fromLabel.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 12),
            fromLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            fromLabel.widthAnchor.constraint(lessThanOrEqualTo: cardView.widthAnchor, multiplier: 0.4),

            arrowIcon.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            arrowIcon.leadingAnchor.constraint(equalTo: fromLabel.trailingAnchor, constant: 6),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),

            toLabel.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            toLabel.leadingAnchor.constraint(equalTo: arrowIcon.trailingAnchor, constant: 6),
            toLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),

            // Time
            timeLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),

            // ── Divider 2 ──
            divider2.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            divider2.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            divider2.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),
            divider2.heightAnchor.constraint(equalToConstant: 1),

            // ── Section header ──
            sectionHeader.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 10),
            sectionHeader.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),

            // ── People stack ──
            peopleStack.topAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: 8),
            peopleStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            peopleStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),

            // ── Divider 3 ──
            divider3.topAnchor.constraint(equalTo: peopleStack.bottomAnchor, constant: 12),
            divider3.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),
            divider3.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),
            divider3.heightAnchor.constraint(equalToConstant: 1),

            // ── Price row ──
            priceLabel.topAnchor.constraint(equalTo: divider3.bottomAnchor, constant: 12),
            priceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: P),

            totalLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            totalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -P),
            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: priceLabel.trailingAnchor, constant: 8),

            priceBottom,
        ])
    }

    // MARK: - Configure

    func configure(with trip: RideDataModel.MyTrip) {
        currentTrip = trip
        let ride   = trip.ride
        let isHost = trip.role == .hosting

        // Role chip
        roleChip.text = isHost ? "  Hosting  " : "  Passenger  "
        if isHost {
            roleChip.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.12)
            roleChip.textColor = AppDesign.Color.primary
        } else {
            roleChip.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.12)
            roleChip.textColor = AppDesign.Color.primary
        }

        // Status chip
        let isCompleted = ride.status == .completed
        statusChip.text = isCompleted ? "  Completed  " : "  Cancelled  "
        statusChip.backgroundColor = isCompleted
            ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.12)
            : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 0.12)
        statusChip.textColor = isCompleted
            ? UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
            : UIColor(red: 0.94, green: 0.36, blue: 0.27, alpha: 1.0)

        // Date
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        dateLabel.text = df.string(from: ride.departureTime)

        // Route
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text   = ride.destination.address ?? "To"

        // Time
        let tf = DateFormatter(); tf.dateFormat = "HH:mm"
        let endSeconds = ride.selectedRoute?.expectedTravelTime ?? 3600
        let endTime = tf.string(from: ride.departureTime.addingTimeInterval(endSeconds))
        timeLabel.text = "\(tf.string(from: ride.departureTime))  ·  Arrives ~\(endTime)"

        // People
        populatePeople(trip: trip, ride: ride, isHost: isHost)

        // Fare
        if isHost {
            let confirmed = RideDataModel.shared.listBookings(for: ride.id).filter { $0.status == .confirmed }
            priceLabel.text  = "₹\(Int(ride.farePerSeat)) per seat"
            totalLabel.text  = "Earned ₹\(Int(ride.farePerSeat * Double(confirmed.count)))"
        } else {
            priceLabel.text  = "₹\(Int(ride.farePerSeat)) paid"
            totalLabel.text  = ""
        }

        // Rate button
        if isCompleted { addRateButtonIfNeeded(trip: trip) }
    }

    private var displayedProfiles: [UserProfile] = []

    private func populatePeople(trip: RideDataModel.MyTrip, ride: Ride, isHost: Bool) {
        peopleStack.arrangedSubviews.forEach {
            peopleStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        displayedProfiles.removeAll()

        var profiles: [UserProfile?]
        if isHost {
            let bookings = RideDataModel.shared.listBookings(for: ride.id).filter { $0.status == .confirmed }
            profiles = bookings.map { b in b.passengerProfile ?? UserDataModel.shared.getUser(by: b.passengerUserID) }
            sectionHeader.text = "PASSENGERS (\(bookings.count))"
        } else {
            profiles = [ride.driverProfile ?? UserDataModel.shared.getUser(by: ride.driverUserID)]
            sectionHeader.text = "YOUR DRIVER"
        }

        if profiles.isEmpty {
            let empty = UILabel()
            empty.text = "No passengers"
            empty.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
            peopleStack.addArrangedSubview(empty)
            return
        }

        for profile in profiles {
            if let p = profile {
                displayedProfiles.append(p)
                peopleStack.addArrangedSubview(makePersonRow(profile: p))
            }
        }
    }

    private func makePersonRow(profile: UserProfile) -> UIView {
        let row = UIView()

        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = AppDesign.Radius.md
        avatar.backgroundColor = .systemGray5
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.loadAndFallback(from: profile.photoURL, name: profile.fullName)

        let nameLabel = UILabel()
        nameLabel.text = profile.fullName
        nameLabel.font = AppDesign.Typography.subheadline
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text = profile.role == .student ? "Student" : "Faculty"
        subLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        [avatar, nameLabel, subLabel].forEach { row.addSubview($0) }
        row.translatesAutoresizingMaskIntoConstraints = false

        // Tap interaction
        let tap = UITapGestureRecognizer(target: self, action: #selector(personTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            avatar.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),

            subLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            subLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -2),

            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
        ])
        return row
    }

    @objc private func personTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let delegate = delegate else { return }
        if let index = peopleStack.arrangedSubviews.firstIndex(of: view),
           index < displayedProfiles.count {
            delegate.pastRideCellDidTapPerson(self, user: displayedProfiles[index])
        }
    }

    // MARK: - Rate Button

    private func addRateButtonIfNeeded(trip: RideDataModel.MyTrip) {
        guard let myID = UserDataModel.shared.getCurrentUser()?.id else { return }
        let ride = trip.ride

        let toReviewIDs: [UUID]
        if trip.role == .hosting {
            toReviewIDs = RideDataModel.shared.listBookings(for: ride.id)
                .filter { $0.status == .confirmed }.map { $0.passengerUserID }
        } else {
            toReviewIDs = [ride.driverUserID]
        }

        let pending = ReviewDataModel.shared.pendingReviewees(
            rideID: ride.id, reviewerID: myID, allRevieweeIDs: toReviewIDs)
        guard !pending.isEmpty else { return }

        // Detach priceLabel from cardView.bottom so button can push card down
        priceLabelBottomConstraint?.isActive = false

        let btn = UIButton(type: .system)
        btn.applyTintActionStyle(title: "Rate this ride", imageSystemName: "star.fill", color: AppDesign.Color.primary)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(rateTapped), for: .touchUpInside)
        cardView.addSubview(btn)

        NSLayoutConstraint.activate([
            // price bottom → gap → button top
            btn.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 14),
            btn.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            btn.heightAnchor.constraint(equalToConstant: 46),
            // button bottom → card bottom
            btn.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])
        rateBtn = btn
    }

    @objc private func rateTapped() {
        guard let trip = currentTrip else { return }
        onRateTapped?(trip)
    }

    // MARK: - Shadow path
    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }
}
