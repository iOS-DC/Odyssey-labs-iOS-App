import UIKit

// MARK: - ProfileViewController
class ProfileViewController: UIViewController {

    // MARK: - IBOutlets (wired in Profile.storyboard)
    @IBOutlet private var customHeaderView: UIView!
    @IBOutlet private var headerTitleLabel: UILabel!
    @IBOutlet private var headerGearButton: UIButton!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var contentStack: UIStackView!
    @IBOutlet private var guestSignInButton: UIButton!

    // Pull-to-refresh
    private let refreshControl = UIRefreshControl()

    // MARK: - Completion banner
    private var completionBanner: ProfileCompletionBannerView?

    /// Banner is dismissed per-user so re-login or profile changes can re-surface it.
    private var bannerDismissedKey: String {
        let uid = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "unknown"
        return "profileBannerDismissed_\(uid)"
    }
    private var isBannerDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: bannerDismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: bannerDismissedKey) }
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

    // MARK: - Vehicle card
    private let vehicleStack     = UIStackView()

    // MARK: - Loading skeleton
    private lazy var skeletonOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = AppDesign.Color.groupedBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        v.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomHeader()
        buildScrollLayout()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadProfile()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = defaultAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = defaultAppearance
        navigationController?.navigationBar.compactAppearance = nil
    }

    // MARK: - Custom Header
    private func setupCustomHeader() {
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        headerTitleLabel.font = AppDesign.Typography.display
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        headerGearButton.configuration = nil
        headerGearButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: symbolConfig), for: .normal)
        headerGearButton.tintColor = AppDesign.Color.primary
        headerGearButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        headerGearButton.backgroundColor = .clear
    }

    // MARK: - Build scroll layout
    private func buildScrollLayout() {
        view.backgroundColor = AppDesign.Color.groupedBackground
        scrollView.alwaysBounceVertical = true
        guestSignInButton.setTitle("Sign In to Continue", for: .normal)
        guestSignInButton.applyPrimaryButton(color: AppDesign.Color.primary)
        contentStack.axis    = .vertical
        contentStack.spacing = AppDesign.Spacing.md
        contentStack.addArrangedSubview(buildHeroCard())
        contentStack.addArrangedSubview(buildContactCard())
        contentStack.addArrangedSubview(buildVehicleCard())

        // Skeleton overlay covers the content until the first profile loads (dynamic runtime subview)
        view.addSubview(skeletonOverlay)
        NSLayoutConstraint.activate([
            skeletonOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            skeletonOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skeletonOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupRefreshControl() {
        refreshControl.tintColor = AppDesign.Color.primary
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    @objc private func handleRefresh() {
        AppHaptics.selection()
        loadProfile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    // MARK: - Hero Card
    private func buildHeroCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        avatarImageView.contentMode    = .scaleAspectFill
        avatarImageView.clipsToBounds  = true
        avatarImageView.layer.cornerRadius = 48
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = AppDesign.Color.primary.withAlphaComponent(0.25).cgColor
        avatarImageView.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.15)
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = AppDesign.Color.primary
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 96),
            avatarImageView.heightAnchor.constraint(equalToConstant: 96),
        ])

        nameLabel.applyTextStyle(AppDesign.Typography.largeTitle)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.text          = "Your Name"

        subtitleLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text          = "—"

        memberLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        memberLabel.textAlignment = .center
        memberLabel.numberOfLines = 0
        memberLabel.text          = "—"

        let divider = UIView.makeDivider()

        let statsStack = buildStatsRow()

        let stack = UIStackView(arrangedSubviews: [
            centeredView(avatarImageView), nameLabel, subtitleLabel,
            memberLabel, divider, statsStack
        ])
        stack.axis         = .vertical
        stack.spacing      = 8
        stack.setCustomSpacing(4, after: nameLabel)
        stack.setCustomSpacing(2, after: subtitleLabel)
        stack.setCustomSpacing(20, after: memberLabel)
        stack.setCustomSpacing(16, after: divider)
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.xl),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.xl),
        ])
        return card
    }

    private func buildStatsRow() -> UIView {
        let ratingTitleLbl = makeCaptionLabel("Rating")
        ratingLabel.font          = AppDesign.Typography.bodyStrong
        ratingLabel.textAlignment = .center
        ratingLabel.text          = "No reviews yet"

        let ratingCol = column(top: ratingLabel, bottom: ratingTitleLbl)

        let ridesTitleLbl = makeCaptionLabel("Rides")
        ridesLabel.font          = AppDesign.Typography.bodyStrong
        ridesLabel.textAlignment = .center
        ridesLabel.text          = "0"

        let ridesCol = column(top: ridesLabel, bottom: ridesTitleLbl)

        let verticalDivider = UIView()
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false
        verticalDivider.backgroundColor = AppDesign.Color.divider
        verticalDivider.widthAnchor.constraint(equalToConstant: 0.5).isActive = true

        let innerStack = UIStackView(arrangedSubviews: [ratingCol, verticalDivider, ridesCol])
        innerStack.axis        = .horizontal
        innerStack.alignment   = .center
        innerStack.distribution = .fill
        innerStack.spacing     = 0
        ratingCol.widthAnchor.constraint(equalTo: ridesCol.widthAnchor).isActive = true

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.applyTonalPanel(color: AppDesign.Color.primary, corner: AppDesign.Radius.sm)
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(innerStack)
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            innerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            innerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        return container
    }

    // MARK: - Contact Card
    private func buildContactCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let titleLabel = UILabel()
        titleLabel.text      = "Contact Information"
        titleLabel.applyTextStyle(AppDesign.Typography.cardTitle)

        emailValueLabel.applyTextStyle(AppDesign.Typography.subheadline)
        emailValueLabel.numberOfLines = 0
        let emailRow = infoRow(icon: "envelope.fill", titleText: "Email", valueLabel: emailValueLabel)

        phoneValueLabel.applyTextStyle(AppDesign.Typography.subheadline)
        let phoneRow = infoRow(icon: "phone.fill", titleText: "Phone", valueLabel: phoneValueLabel)

        homeValueLabel.applyTextStyle(AppDesign.Typography.subheadline)
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
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive  = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = makeCaptionLabel("Home Location")
        homeValueLabel.text = "Add your home address to find rides faster."

        let textStack      = UIStackView(arrangedSubviews: [titleLbl, homeValueLabel])
        textStack.axis     = .vertical
        textStack.spacing  = 2
        textStack.alignment = .fill
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let editBtn = UIButton(type: .system)
        editBtn.setTitle("Edit", for: .normal)
        editBtn.applyTextActionStyle()
        editBtn.setContentHuggingPriority(.required, for: .horizontal)
        editBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        editBtn.addTarget(self, action: #selector(editHomeLocationTapped), for: .touchUpInside)

        let row       = UIStackView(arrangedSubviews: [icon, textStack, editBtn])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .top
        return row
    }

    // MARK: - Vehicle Card
    private func buildVehicleCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let titleLabel = UILabel()
        titleLabel.text = "My Vehicles"
        titleLabel.applyTextStyle(AppDesign.Typography.cardTitle)

        let addBtn = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "plus.circle.fill")
        cfg.baseForegroundColor = AppDesign.Color.primary
        addBtn.configuration = cfg
        addBtn.addTarget(self, action: #selector(openVehicleDetails), for: .touchUpInside)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, addBtn])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing

        vehicleStack.axis    = .vertical
        vehicleStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [headerRow, makeSeparator(), vehicleStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func refreshVehicles(for profile: UserProfile) {
        vehicleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let vehicles = profile.vehicles, !vehicles.isEmpty {
            for v in vehicles {
                let row = buildVehicleSummaryRow(vehicle: v)
                vehicleStack.addArrangedSubview(row)
                if v != vehicles.last {
                    vehicleStack.addArrangedSubview(makeSeparator())
                }
            }
        } else {
            let emptyLabel = UILabel()
            emptyLabel.text = "No vehicles yet. Tap + to add one."
            emptyLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            vehicleStack.addArrangedSubview(emptyLabel)
        }
    }

    private func buildVehicleSummaryRow(vehicle: Vehicle) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: vehicle.type == .car ? "car.fill" : "bicycle"))
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let nameLbl = UILabel()
        nameLbl.text = vehicle.alias ?? vehicle.model
        nameLbl.applyTextStyle(AppDesign.Typography.subheadline)
        nameLbl.numberOfLines = 0

        let regLbl = UILabel()
        regLbl.text = vehicle.registrationNumber
        regLbl.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        regLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [nameLbl, regLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .fill
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 10).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [icon, textStack, spacer, chevron])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top

        let tap = UIAction { [weak self] _ in
            let sb = UIStoryboard(name: "VehicleRegistration", bundle: nil)
            guard let vc = sb.instantiateViewController(withIdentifier: "VehicleRegistrationViewController") as? VehicleRegistrationViewController else { return }
            vc.vehicleToEdit = vehicle
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        let btn = UIButton(type: .system, primaryAction: tap)
        btn.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: row.topAnchor),
            btn.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])

        return row
    }

    // MARK: - Load Profile
    private func loadProfile() {
        if let profile = UserDataModel.shared.getCurrentUser() {
            applyProfile(profile)
            hideSkeleton()
        }

        guard SessionManager.shared.isLoggedIn else {
            applyGuestState()
            hideSkeleton()
            return
        }
        Task { @MainActor in
            await UserDataModel.shared.restoreSessionUser()
            if let fresh = UserDataModel.shared.getCurrentUser() {
                applyProfile(fresh)
                ReviewDataModel.shared.fetchAndMerge(for: fresh.id)
            }
            hideSkeleton()
        }
    }

    private func hideSkeleton() {
        guard !skeletonOverlay.isHidden else { return }
        UIView.animate(withDuration: 0.25) {
            self.skeletonOverlay.alpha = 0
        } completion: { _ in
            self.skeletonOverlay.isHidden = true
        }
    }

    private func applyGuestState() {
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemGray4
        nameLabel.text = "Guest User"
        subtitleLabel.text = "Join UniRide to find rides near you"
        memberLabel.text = "Browsing as a guest"
        ratingLabel.text = "No reviews yet"
        ridesLabel.text = "0"

        emailValueLabel.text = "guest@uniride.com"
        phoneValueLabel.text = "Sign in to add"
        homeValueLabel.text  = "Sign in to add"

        vehicleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let emptyLabel = UILabel()
        emptyLabel.text = "Sign in to add your vehicles"
        emptyLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        vehicleStack.addArrangedSubview(emptyLabel)

        guestSignInButton.isHidden = false
        tabBarItem.badgeValue = nil
        completionBanner?.removeFromSuperview()

        headerGearButton.isEnabled = false
    }

    private func applyProfile(_ profile: UserProfile) {
        guestSignInButton.isHidden = true
        headerGearButton.isEnabled = true

        let avatarSize = CGSize(width: 88, height: 88)
        if avatarImageView.bounds.width < 4 {
            let placeholder = UIImage.generatedAvatar(for: profile.fullName.isEmpty ? "?" : profile.fullName, size: avatarSize)
            avatarImageView.image = placeholder
        }
        avatarImageView.loadAndFallback(from: profile.photoURL, name: profile.fullName.isEmpty ? "?" : profile.fullName)

        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName

        if let role = profile.role {
            if role == .student {
                let course = profile.courseName ?? ""
                let year   = profile.year.map { " · Year \($0)" } ?? ""
                subtitleLabel.text = course.isEmpty ? "Student" : (course + year)
            } else {
                subtitleLabel.text = "Faculty · \(profile.courseName ?? "")"
            }
        }

        let yearStr: String
        if let date = SessionManager.shared.loginDate {
            let cal = Calendar.current
            yearStr = "\(cal.component(.year, from: date))"
        } else {
            let cal = Calendar.current
            yearStr = "\(cal.component(.year, from: Date()))"
        }
        memberLabel.text = "Member Since \(yearStr)"

        let avg = ReviewDataModel.shared.averageRating(for: profile.id)
        ratingLabel.text = avg.map { String(format: "%.1f ★", $0) } ?? "No reviews yet"
        let total = ReviewDataModel.shared.totalRides(for: profile.id)
        ridesLabel.text = "\(total)"

        emailValueLabel.text = profile.email
        phoneValueLabel.text = (profile.phone?.isEmpty == false) ? profile.phone : "Add a phone number"

        if let home = UserDataModel.shared.preferredHomeLocation() {
            homeValueLabel.text = home.address
        } else {
            homeValueLabel.text = "Add your home address to find rides faster."
        }

        let completion = ProfileCompletionCalculator.compute(for: profile)
        tabBarItem.badgeValue = completion.isComplete ? nil : "!"

        if completion.isComplete {
            UserDefaults.standard.removeObject(forKey: bannerDismissedKey)
        }
        refreshCompletionBanner(for: profile)
        refreshVehicles(for: profile)
    }

    // MARK: - Completion Banner
    private func refreshCompletionBanner(for user: UserProfile) {
        let completion = ProfileCompletionCalculator.compute(for: user)

        completionBanner?.removeFromSuperview()
        completionBanner = nil

        guard !completion.isComplete && !isBannerDismissed else { return }

        let banner = ProfileCompletionBannerView(completion: completion)
        banner.translatesAutoresizingMaskIntoConstraints = false

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

    @objc private func openVehicleDetails() {
        let sb = UIStoryboard(name: "VehicleRegistration", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "VehicleRegistrationViewController") as? VehicleRegistrationViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions
    @IBAction private func settingsTapped() {
        let sb = UIStoryboard(name: "Settings", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func guestSignInTapped() {
        AppHaptics.impact(.medium)
        SceneDelegate.setRootToAuth()
    }

    @objc private func editHomeLocationTapped() {
        let sb = UIStoryboard(name: "EditHomeLocation", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "EditHomeLocationViewController") as? EditHomeLocationViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Sign Out?", message: "You'll need to sign in again to access your rides.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await AuthService.shared.signOut()
            UserDataModel.shared.logout()
            let sb      = UIStoryboard(name: "Main", bundle: nil)
            let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
            let nav     = UINavigationController(rootViewController: emailVC)
            if let scene = self.view.window?.windowScene?.delegate as? SceneDelegate {
                scene.window?.rootViewController = nav
                scene.window?.makeKeyAndVisible()
            }
        }
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
        lbl.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        return lbl
    }

    private func infoRow(icon iconName: String, titleText: String, valueLabel: UILabel) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor    = AppDesign.Color.primary
        icon.contentMode  = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive  = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = makeCaptionLabel(titleText)

        let textStack     = UIStackView(arrangedSubviews: [titleLbl, valueLabel])
        textStack.axis    = .vertical
        textStack.spacing = 2
        textStack.alignment = .fill
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.numberOfLines = 0

        let row       = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .top
        return row
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = AppDesign.Color.border
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }
}
