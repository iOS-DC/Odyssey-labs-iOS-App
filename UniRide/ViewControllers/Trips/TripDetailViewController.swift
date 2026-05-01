import UIKit

final class TripDetailViewController: UIViewController {

    private let trip: Trip
    private var isLiked: Bool

    private let scrollView = UIScrollView()
    private let heroImageView = UIImageView()
    private let backButton = UIButton(type: .system)
    private let contentStack = UIStackView()
    private let bottomBar = UIView()
    private let bottomPriceLabel = UILabel()
    private let bottomJoinButton = UIButton()

    init(trip: Trip) {
        self.trip = trip
        self.isLiked = trip.isLiked
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        build()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func joinTapped() {
        let vc = TripBookingViewController(trip: trip)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Build

    private func build() {
        // Hero image
        heroImageView.loadImage(from: trip.imageName)
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.backgroundColor = .systemGray5
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heroImageView)

        // Back button
        let backContainer = UIView()
        backContainer.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        backContainer.layer.cornerRadius = 20
        backContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backContainer)

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backContainer.addSubview(backButton)

        NSLayoutConstraint.activate([
            backContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backContainer.widthAnchor.constraint(equalToConstant: 40),
            backContainer.heightAnchor.constraint(equalToConstant: 40),

            backButton.centerXAnchor.constraint(equalTo: backContainer.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backContainer.centerYAnchor),
        ])

        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: view.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 280),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 260),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -90),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        // Header section (white card over hero)
        contentStack.addArrangedSubview(buildHeaderSection())
        contentStack.addArrangedSubview(makeSectionDivider())
        contentStack.addArrangedSubview(buildAboutSection())
        contentStack.addArrangedSubview(makeSectionDivider())
        contentStack.addArrangedSubview(buildItinerarySection())
        contentStack.addArrangedSubview(makeSectionDivider())
        contentStack.addArrangedSubview(buildInclusionsSection())
        contentStack.addArrangedSubview(makeSectionDivider())
        contentStack.addArrangedSubview(buildExclusionsSection())
        contentStack.addArrangedSubview(makeSectionDivider())
        contentStack.addArrangedSubview(buildSlotsSection())

        // Bottom bar
        buildBottomBar()

        view.bringSubviewToFront(backContainer)
    }

    private func buildHeaderSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 20
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let titleLabel = UILabel()
        titleLabel.text = trip.title
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        let locationRow = makeIconRow("mappin.and.ellipse", text: trip.location)
        let dateRow = makeIconRow("calendar", text: trip.dateRange)

        let priceLabel = UILabel()
        priceLabel.text = trip.priceFormatted
        priceLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        priceLabel.textColor = AppDesign.Color.primary

        let spotsLabel = UILabel()
        if trip.spotsLeft > 0 {
            spotsLabel.text = "\(trip.spotsLeft) spot\(trip.spotsLeft == 1 ? "" : "s") left"
            spotsLabel.textColor = .systemOrange
        } else {
            spotsLabel.text = "Fully booked"
            spotsLabel.textColor = .systemRed
        }
        spotsLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, UIView(), spotsLabel])
        priceRow.axis = .horizontal
        priceRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, locationRow, dateRow, priceRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func buildAboutSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let heading = makeSectionHeading("About Trip")

        let bodyLabel = UILabel()
        bodyLabel.text = trip.about
        bodyLabel.font = UIFont.systemFont(ofSize: 15)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [heading, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func buildItinerarySection() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let heading = makeSectionHeading("Itinerary")
        var rows: [UIView] = [heading]

        for day in trip.itinerary {
            rows.append(buildItineraryDay(day))
        }

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func buildItineraryDay(_ day: ItineraryDay) -> UIView {
        let container = UIView()

        let bar = UIView()
        bar.backgroundColor = AppDesign.Color.primary
        bar.layer.cornerRadius = 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bar)

        let titleLabel = UILabel()
        titleLabel.text = day.title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        var activityViews: [UIView] = [titleLabel]
        for activity in day.activities {
            let row = makeActivityRow(activity)
            activityViews.append(row)
        }

        let contentStack = UIStackView(arrangedSubviews: activityViews)
        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bar.widthAnchor.constraint(equalToConstant: 4),

            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            contentStack.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])
        return container
    }

    private func makeActivityRow(_ text: String) -> UIView {
        let dot = UIView()
        dot.backgroundColor = AppDesign.Color.primary
        dot.layer.cornerRadius = 3
        dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .top
        return row
    }

    private func buildInclusionsSection() -> UIView {
        buildChecklistSection(title: "Inclusions", items: trip.inclusions, checked: true)
    }

    private func buildExclusionsSection() -> UIView {
        buildChecklistSection(title: "Exclusions", items: trip.exclusions, checked: false)
    }

    private func buildChecklistSection(title: String, items: [String], checked: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let heading = makeSectionHeading(title)
        var rows: [UIView] = [heading]

        for item in items {
            let row = makeChecklistRow(item, checked: checked)
            rows.append(row)
        }

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func makeChecklistRow(_ text: String, checked: Bool) -> UIView {
        let iconName = checked ? "checkmark" : "xmark"
        let iconColor: UIColor = checked ? .systemGreen : .systemRed

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = iconColor
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .top
        return row
    }

    private func buildSlotsSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let heading = makeSectionHeading("Available Slots")

        let bodyLabel = UILabel()
        if trip.spotsLeft > 0 {
            let full = "Only \(trip.spotsLeft) spots remaining. Book now to secure your place!"
            let attr = NSMutableAttributedString(string: full)
            if let range = full.range(of: "\(trip.spotsLeft) spots") {
                let ns = NSRange(range, in: full)
                attr.addAttributes([
                    .foregroundColor: UIColor.systemOrange,
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
                ], range: ns)
            }
            bodyLabel.attributedText = attr
        } else {
            bodyLabel.text = "This trip is fully booked."
            bodyLabel.textColor = .systemRed
        }
        bodyLabel.font = UIFont.systemFont(ofSize: 15)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [heading, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        ])
        return container
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let totalLabel = UILabel()
        totalLabel.text = "Total Amount"
        totalLabel.font = UIFont.systemFont(ofSize: 12)
        totalLabel.textColor = .secondaryLabel

        bottomPriceLabel.text = trip.priceFormatted
        bottomPriceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        bottomPriceLabel.textColor = AppDesign.Color.primary

        let priceStack = UIStackView(arrangedSubviews: [totalLabel, bottomPriceLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 2
        priceStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(priceStack)

        var joinCfg = UIButton.Configuration.filled()
        joinCfg.title = trip.isPast ? "Completed" : "Join Now"
        joinCfg.baseForegroundColor = .white
        joinCfg.baseBackgroundColor = trip.isPast ? .systemGray4 : AppDesign.Color.primary
        joinCfg.cornerStyle = .capsule
        joinCfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        joinCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.systemFont(ofSize: 16, weight: .semibold); return a
        }
        bottomJoinButton.configuration = joinCfg
        bottomJoinButton.isEnabled = !trip.isPast
        bottomJoinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        bottomJoinButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(bottomJoinButton)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 90),

            priceStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            priceStack.centerYAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 30),

            bottomJoinButton.centerYAnchor.constraint(equalTo: priceStack.centerYAnchor),
            bottomJoinButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Helpers

    private func makeIconRow(_ systemName: String, text: String) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        return row
    }

    private func makeSectionHeading(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        return l
    }

    private func makeSectionDivider() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        let line = UIView()
        line.backgroundColor = UIColor.separator
        line.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 6),
        ])
        container.heightAnchor.constraint(equalToConstant: 6).isActive = true
        let bg = UIView()
        bg.backgroundColor = UIColor.systemGray6
        bg.translatesAutoresizingMaskIntoConstraints = false
        container.insertSubview(bg, at: 0)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }
}
