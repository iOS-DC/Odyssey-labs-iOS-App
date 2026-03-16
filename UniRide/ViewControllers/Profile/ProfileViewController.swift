import UIKit

// MARK: - ProfileViewController
class ProfileViewController: UIViewController {

    // MARK: - Scroll
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

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
        v.backgroundColor = .systemGroupedBackground
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
        setupNavBar()
        buildScrollLayout()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        title = "Profile"

        // Settings gear button (left) → pushes SettingsViewController
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain, target: self, action: #selector(settingsTapped)
        )

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

        // Add Sign In button for guest mode (hidden by default)
        setupGuestSignInButton()

        contentStack.axis    = .vertical
        contentStack.spacing = AppDesign.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.md),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.xl * 2),
        ])

        contentStack.addArrangedSubview(buildHeroCard())
        contentStack.addArrangedSubview(buildContactCard())
        contentStack.addArrangedSubview(buildVehicleCard())

        // Skeleton overlay covers the content until the first profile loads
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
        // Reset banner dismissal so a profile-change refresh can re-surface it
        loadProfile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    // MARK: - Guest Mode
    private let guestSignInButton = UIButton(type: .system)

    private func setupGuestSignInButton() {
        guestSignInButton.translatesAutoresizingMaskIntoConstraints = false
        guestSignInButton.applyPrimaryButton(color: AppDesign.Color.primary)
        guestSignInButton.setTitle("Sign In to UniRide", for: .normal)
        guestSignInButton.isHidden = true
        guestSignInButton.addTarget(self, action: #selector(guestSignInTapped), for: .touchUpInside)
        
        view.addSubview(guestSignInButton)
        NSLayoutConstraint.activate([
            guestSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.xl),
            guestSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.xl),
            guestSignInButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.lg),
            guestSignInButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func guestSignInTapped() {
        AppHaptics.impact(.medium)
        SceneDelegate.setRootToAuth()
    }

    // MARK: - Hero Card
    private func buildHeroCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        // Avatar
        avatarImageView.contentMode    = .scaleAspectFill
        avatarImageView.clipsToBounds  = true
        avatarImageView.layer.cornerRadius = 44
        avatarImageView.backgroundColor = AppDesign.Color.primary.withAlphaComponent(0.15)
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = AppDesign.Color.primary
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 88),
            avatarImageView.heightAnchor.constraint(equalToConstant: 88),
        ])

        // Name
        nameLabel.applyTextStyle(AppDesign.Typography.title)
        nameLabel.textAlignment = .center
        nameLabel.text          = "Your Name"

        // Subtitle (department / year)
        subtitleLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text          = "—"

        // Member since
        memberLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        memberLabel.textAlignment = .center
        memberLabel.text          = "—"

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
        ratingLabel.font          = AppDesign.Typography.bodyStrong
        ratingLabel.textAlignment = .center
        ratingLabel.text          = "—"

        let ratingCol = column(top: ratingLabel, bottom: ratingTitleLbl)

        // Rides stat
        let ridesTitleLbl = makeCaptionLabel("Rides")
        ridesLabel.font          = AppDesign.Typography.bodyStrong
        ridesLabel.textAlignment = .center
        ridesLabel.text          = "0"

        let ridesCol = column(top: ridesLabel, bottom: ridesTitleLbl)

        let statsStack        = UIStackView(arrangedSubviews: [ratingCol, ridesCol])
        statsStack.axis       = .horizontal
        statsStack.alignment  = .center
        statsStack.distribution = .fillEqually
        statsStack.spacing    = 0
        return statsStack
    }

    // MARK: - Contact Card
    private func buildContactCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let titleLabel = UILabel()
        titleLabel.text      = "Contact Information"
        titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong)

        // Email row
        emailValueLabel.applyTextStyle(AppDesign.Typography.subheadline)
        emailValueLabel.numberOfLines = 0
        let emailRow = infoRow(icon: "envelope.fill", titleText: "Email", valueLabel: emailValueLabel)

        // Phone row
        phoneValueLabel.applyTextStyle(AppDesign.Typography.subheadline)
        let phoneRow = infoRow(icon: "phone.fill", titleText: "Phone", valueLabel: phoneValueLabel)

        // Home row (with edit button)
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
        homeValueLabel.text = "Tap Edit to set home"

        let textStack      = UIStackView(arrangedSubviews: [titleLbl, homeValueLabel])
        textStack.axis     = .vertical
        textStack.spacing  = 2

        let editBtn = UIButton(type: .system)
        editBtn.setTitle("Edit", for: .normal)
        editBtn.applyTextActionStyle()
        editBtn.setContentHuggingPriority(.required, for: .horizontal)
        editBtn.addTarget(self, action: #selector(editHomeLocationTapped), for: .touchUpInside)

        let row       = UIStackView(arrangedSubviews: [icon, textStack, editBtn])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    // MARK: - Vehicle Card
    private func buildVehicleCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let titleLabel = UILabel()
        titleLabel.text = "My Vehicles"
        titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        
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
            emptyLabel.text = "No vehicles added. Tap + to add one."
            emptyLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
            emptyLabel.textAlignment = .center
            vehicleStack.addArrangedSubview(emptyLabel)
        }
    }
    
    private func buildVehicleSummaryRow(vehicle: Vehicle) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: vehicle.type == .car ? "car.fill" : "bicycle"))
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        let nameLbl = UILabel()
        nameLbl.text = vehicle.alias ?? vehicle.model
        nameLbl.applyTextStyle(AppDesign.Typography.subheadline)
        
        let regLbl = UILabel()
        regLbl.text = vehicle.registrationNumber
        regLbl.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        
        let textStack = UIStackView(arrangedSubviews: [nameLbl, regLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        
        let row = UIStackView(arrangedSubviews: [icon, textStack, chevron])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let tap = UIAction { [weak self] _ in
            let vc = VehicleRegistrationViewController()
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
        // 1. Show whatever we have locally right now (fast path)
        if let profile = UserDataModel.shared.getCurrentUser() {
            applyProfile(profile)
            hideSkeleton()
        }

        // 2. Always refresh from Supabase in the background (stale-while-revalidate).
        //    This ensures freshly-registered accounts with an empty local cache (or any
        //    profile updated on another device) are reflected immediately.
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
        subtitleLabel.text = "Sign in to join the community"
        memberLabel.text = "You are browsing as a guest"
        ratingLabel.text = "—"
        ridesLabel.text = "0"
        
        emailValueLabel.text = "guest@uniride.com"
        phoneValueLabel.text = "Login Required"
        homeValueLabel.text  = "Sign in to set home"
        
        vehicleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let emptyLabel = UILabel()
        emptyLabel.text = "Sign in to add vehicles"
        emptyLabel.applyTextStyle(AppDesign.Typography.caption, color: .tertiaryLabel)
        emptyLabel.textAlignment = .center
        vehicleStack.addArrangedSubview(emptyLabel)
        
        guestSignInButton.isHidden = false
        tabBarItem.badgeValue = nil
        completionBanner?.removeFromSuperview()
        
        // Hide edit buttons
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func applyProfile(_ profile: UserProfile) {
        guestSignInButton.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = true

        // Avatar — force a known size so loadAndFallback generates correct initials image
        // (view may not be laid out yet on first viewWillAppear call)
        let avatarSize = CGSize(width: 88, height: 88)
        if avatarImageView.bounds.width < 4 {
            // Provide an explicit size hint before layout pass
            let placeholder = UIImage.generatedAvatar(for: profile.fullName.isEmpty ? "?" : profile.fullName, size: avatarSize)
            avatarImageView.image = placeholder
        }
        avatarImageView.loadAndFallback(from: profile.photoURL, name: profile.fullName.isEmpty ? "?" : profile.fullName)

        // Name
        nameLabel.text = profile.fullName.isEmpty ? "Your Name" : profile.fullName

        // Subtitle
        if let role = profile.role {
            if role == .student {
                let course = profile.courseName ?? ""
                let year   = profile.year.map { " · Year \($0)" } ?? ""
                subtitleLabel.text = course.isEmpty ? "Student" : (course + year)
            } else {
                subtitleLabel.text = "Faculty · \(profile.courseName ?? "")"
            }
        }

        // Member Since — derived from the session's loginDate or current year as fallback
        let yearStr: String
        if let date = SessionManager.shared.loginDate {
            let cal = Calendar.current
            yearStr = "\(cal.component(.year, from: date))"
        } else {
            let cal = Calendar.current
            yearStr = "\(cal.component(.year, from: Date()))"
        }
        memberLabel.text = "Member Since \(yearStr)"

        // Stats — rating from ReviewDataModel, rides from RideDataModel
        let avg = ReviewDataModel.shared.averageRating(for: profile.id)
        ratingLabel.text = avg.map { String(format: "%.1f ★", $0) } ?? "—"
        let total = ReviewDataModel.shared.totalRides(for: profile.id)
        ridesLabel.text = "\(total)"

        // Contact
        emailValueLabel.text = profile.email
        phoneValueLabel.text = (profile.phone?.isEmpty == false) ? profile.phone : "Not set"

        if let home = UserDataModel.shared.preferredHomeLocation() {
            homeValueLabel.text = home.address
        } else {
            homeValueLabel.text = "Tap Edit to set home"
        }

        // Tab badge — "!" when profile is incomplete
        let completion = ProfileCompletionCalculator.compute(for: profile)
        tabBarItem.badgeValue = completion.isComplete ? nil : "!"

        // Banner — re-show if profile became incomplete again (e.g. after logout/login)
        if completion.isComplete {
            // Profile is now complete — reset dismissed state so banner shows next time a step regresses
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

    @objc private func openVehicleDetails() {
        let vc = VehicleRegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        openEditProfile()
    }

    @objc private func settingsTapped() {
        let vc = SettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func editHomeLocationTapped() {
        let vc = EditHomeLocationViewController()
        navigationController?.pushViewController(vc, animated: true)
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

        let row       = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
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
