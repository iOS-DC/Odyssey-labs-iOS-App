import UIKit

// MARK: - ProfileViewController
class ProfileViewController: UIViewController {

    // MARK: - Scroll
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: - Completion banner
    private var completionBanner: ProfileCompletionBannerView?
    private static let dismissedKey = "profileCompletionBannerDismissed"

    private var isBannerDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: Self.dismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.dismissedKey) }
    }

    // MARK: - Hero card views (kept as properties for update)
    private let avatarImageView  = UIImageView()
    private let nameLabel        = UILabel()
    private let subtitleLabel    = UILabel()
    private let memberLabel      = UILabel()
    private let ratingLabel      = UILabel()
    private let ridesLabel       = UILabel()

    // MARK: - Contact card
    private let emailValueLabel  = UILabel()
    private let phoneValueLabel  = UILabel()
    private let homeValueLabel   = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        buildScrollLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        title = "Profile"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            style: .plain, target: self, action: #selector(logoutTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemRed

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain, target: self, action: #selector(editButtonTapped)
        )
    }

    // MARK: - Build scroll layout
    private func buildScrollLayout() {
        view.backgroundColor = .systemGroupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        contentStack.addArrangedSubview(buildHeroCard())
        contentStack.addArrangedSubview(buildContactCard())
    }

    // MARK: - Hero Card
    private func buildHeroCard() -> UIView {
        let card = UIView()
        card.backgroundColor  = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 12
        card.layer.shadowOffset  = CGSize(width: 0, height: 4)
        card.layer.masksToBounds = false

        // Avatar
        avatarImageView.contentMode    = .scaleAspectFill
        avatarImageView.clipsToBounds  = true
        avatarImageView.layer.cornerRadius = 44
        avatarImageView.backgroundColor = .systemPurple.withAlphaComponent(0.15)
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemPurple
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 88),
            avatarImageView.heightAnchor.constraint(equalToConstant: 88),
        ])

        // Name
        nameLabel.font          = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.textColor     = .label
        nameLabel.text          = "Your Name"

        // Subtitle (department / year)
        subtitleLabel.font          = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor     = .secondaryLabel
        subtitleLabel.text          = "—"

        // Member since
        memberLabel.font          = .systemFont(ofSize: 13)
        memberLabel.textAlignment = .center
        memberLabel.textColor     = .tertiaryLabel
        memberLabel.text          = "Member Since 2025"

        // Divider
        let divider            = UIView()
        divider.backgroundColor = .systemGray5
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // Stats row
        let statsStack = buildStatsRow()

        // Summary stack (avatar → name → subtitle → member → divider → stats)
        let stack = UIStackView(arrangedSubviews: [
            centeredView(avatarImageView), nameLabel, subtitleLabel,
            memberLabel, divider, statsStack
        ])
        stack.axis         = .vertical
        stack.spacing      = 6
        stack.setCustomSpacing(16, after: memberLabel)
        stack.setCustomSpacing(12, after: divider)
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])
        return card
    }

    private func buildStatsRow() -> UIView {
        // Rating stat
        let ratingTitleLbl = makeCaptionLabel("Rating")
        ratingLabel.font          = .systemFont(ofSize: 18, weight: .semibold)
        ratingLabel.textAlignment = .center
        ratingLabel.text          = "—"

        let ratingCol = column(top: ratingLabel, bottom: ratingTitleLbl)

        // Separator
        let sep          = UIView()
        sep.backgroundColor = .systemGray5
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive  = true
        sep.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Rides stat
        let ridesTitleLbl = makeCaptionLabel("Rides")
        ridesLabel.font          = .systemFont(ofSize: 18, weight: .semibold)
        ridesLabel.textAlignment = .center
        ridesLabel.text          = "0"

        let ridesCol = column(top: ridesLabel, bottom: ridesTitleLbl)

        let statsStack        = UIStackView(arrangedSubviews: [ratingCol, sep, ridesCol])
        statsStack.axis       = .horizontal
        statsStack.alignment  = .center
        statsStack.distribution = .fillEqually
        statsStack.spacing    = 0
        return statsStack
    }

    // MARK: - Contact Card
    private func buildContactCard() -> UIView {
        let card = UIView()
        card.backgroundColor    = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 12
        card.layer.shadowOffset  = CGSize(width: 0, height: 4)
        card.layer.masksToBounds = false

        let titleLabel = UILabel()
        titleLabel.text      = "Contact Information"
        titleLabel.font      = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label

        // Email row
        emailValueLabel.font      = .systemFont(ofSize: 15, weight: .medium)
        emailValueLabel.textColor = .label
        emailValueLabel.numberOfLines = 0
        let emailRow = infoRow(icon: "envelope.fill", titleText: "Email", valueLabel: emailValueLabel)

        // Phone row
        phoneValueLabel.font      = .systemFont(ofSize: 15, weight: .medium)
        phoneValueLabel.textColor = .label
        let phoneRow = infoRow(icon: "phone.fill", titleText: "Phone", valueLabel: phoneValueLabel)

        // Home row (with edit button)
        homeValueLabel.font      = .systemFont(ofSize: 15, weight: .medium)
        homeValueLabel.textColor = .label
        homeValueLabel.numberOfLines = 0
        let homeRow = buildHomeRow()

        let mainStack       = UIStackView(arrangedSubviews: [titleLabel, makeSeparator(), emailRow, makeSeparator(), phoneRow, makeSeparator(), homeRow])
        mainStack.axis      = .vertical
        mainStack.spacing   = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])
        return card
    }

    private func buildHomeRow() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "house.fill"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive  = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = makeCaptionLabel("Home Location")
        homeValueLabel.text = "Tap Edit to set home"

        let textStack      = UIStackView(arrangedSubviews: [titleLbl, homeValueLabel])
        textStack.axis     = .vertical
        textStack.spacing  = 2

        let editBtn = UIButton(type: .system)
        editBtn.setTitle("Edit", for: .normal)
        editBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        editBtn.setContentHuggingPriority(.required, for: .horizontal)
        editBtn.addTarget(self, action: #selector(editHomeLocationTapped), for: .touchUpInside)

        let row       = UIStackView(arrangedSubviews: [icon, textStack, editBtn])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    // MARK: - Load Profile
    private func loadProfile() {
        guard let profile = UserDataModel.shared.getCurrentUser() else { return }

        // Avatar
        if let url = profile.photoURL {
            loadImageAsync(from: url)
        } else {
            avatarImageView.image     = UIImage.generatedAvatar(for: profile.fullName.isEmpty ? "?" : profile.fullName,
                                                                size: CGSize(width: 88, height: 88))
            avatarImageView.tintColor = nil
        }

        // Name
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName

        // Subtitle
        if let role = profile.role {
            if role == .student {
                let course = profile.courseName ?? ""
                let year   = profile.year.map { " · Year \($0)" } ?? ""
                subtitleLabel.text = course + year
            } else {
                subtitleLabel.text = "Faculty · \(profile.courseName ?? "")"
            }
        }

        memberLabel.text = "Member Since 2025"

        // Stats
        let avg        = ReviewDataModel.shared.averageRating(for: profile.id)
        ratingLabel.text = avg.map { String(format: "%.1f ★", $0) } ?? "—"
        let total      = ReviewDataModel.shared.totalRides(for: profile.id)
        ridesLabel.text = "\(total)"

        // Contact
        emailValueLabel.text = profile.email
        phoneValueLabel.text = (profile.phone?.isEmpty == false) ? profile.phone : "Not set"

        if let home = UserDataModel.shared.preferredHomeLocation() {
            homeValueLabel.text = home.address
        } else {
            homeValueLabel.text = "Tap Edit to set home"
        }

        // Tab badge
        let completion = ProfileCompletionCalculator.compute(for: profile)
        tabBarItem.badgeValue = completion.isComplete ? nil : "!"

        // Banner
        refreshCompletionBanner(for: profile)
    }

    // MARK: - Completion Banner
    private func refreshCompletionBanner(for user: UserProfile) {
        let completion = ProfileCompletionCalculator.compute(for: user)

        completionBanner?.removeFromSuperview()
        completionBanner = nil

        guard !completion.isComplete && !isBannerDismissed else { return }

        let banner = ProfileCompletionBannerView(completion: completion)
        banner.translatesAutoresizingMaskIntoConstraints = false

        // Insert banner at top of contentStack (index 0)
        contentStack.insertArrangedSubview(banner, at: 0)

        completionBanner = banner

        banner.onStepTapped = { [weak self] step in self?.handleStep(step) }
        banner.onDismiss    = { [weak self] in
            guard let self else { return }
            self.isBannerDismissed = true
            UIView.animate(withDuration: 0.3) {
                banner.alpha  = 0
                banner.isHidden = true
            } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }

    // MARK: - Step Navigation
    private func handleStep(_ step: ProfileCompletionStep) {
        switch step {
        case .photo, .phone: openEditProfile()
        case .vehicle:       openVehicleDetails()
        }
    }

    private func openEditProfile() {
        let sb = UIStoryboard(name: "EditProfile", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openVehicleDetails() {
        let vc = VehicleRegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        openEditProfile()
    }

    @objc private func editHomeLocationTapped() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "ProfileStep3ViewController") as? ProfileStep3ViewController {
            vc.isEditingMode = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        UserDataModel.shared.logout()
        let sb     = UIStoryboard(name: "Main", bundle: nil)
        let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
        let nav    = UINavigationController(rootViewController: emailVC)
        if let scene = view.window?.windowScene?.delegate as? SceneDelegate {
            scene.window?.rootViewController = nav
            scene.window?.makeKeyAndVisible()
        }
    }

    // MARK: - Async image loader
    private func loadImageAsync(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if let data, let image = UIImage(data: data) {
                    self.avatarImageView.image = image
                } else {
                    guard let profile = UserDataModel.shared.getCurrentUser() else { return }
                    self.avatarImageView.image = UIImage.generatedAvatar(for: profile.fullName, size: CGSize(width: 88, height: 88))
                }
            }
        }.resume()
    }

    // MARK: - Helpers
    private func centeredView(_ child: UIView) -> UIView {
        let wrapper = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(child)
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            child.topAnchor.constraint(equalTo: wrapper.topAnchor),
            child.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func column(top: UILabel, bottom: UILabel) -> UIStackView {
        top.textAlignment    = .center
        bottom.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [top, bottom])
        stack.axis    = .vertical
        stack.spacing = 2
        return stack
    }

    private func makeCaptionLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = .secondaryLabel
        return lbl
    }

    private func infoRow(icon iconName: String, titleText: String, valueLabel: UILabel) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor    = .systemBlue
        icon.contentMode  = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive  = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = makeCaptionLabel(titleText)

        let textStack     = UIStackView(arrangedSubviews: [titleLbl, valueLabel])
        textStack.axis    = .vertical
        textStack.spacing = 2

        let row       = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .systemGray6
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }
}
