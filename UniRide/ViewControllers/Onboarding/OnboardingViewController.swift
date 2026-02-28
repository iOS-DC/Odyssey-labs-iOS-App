import UIKit

final class OnboardingViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var nextButton: UIButton!
    private let infoStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWelcomeUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([imageView, titleLabel, subtitleLabel, infoStack, nextButton])
    }

    private func configureWelcomeUI() {
        navigationItem.hidesBackButton = true
        view.backgroundColor = AppDesign.Color.primary

        pageControl.isHidden = true

        imageView.image = UIImage(systemName: "car.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        imageView.layer.cornerRadius = AppDesign.Radius.lg
        imageView.clipsToBounds = true

        titleLabel.text = "UniRide"
        titleLabel.font = AppDesign.Typography.h1
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Your Campus Carpool Community\n\n• Connect with Peers\nShare rides with students and faculty from your university\n\n• Save Money & Environment\nSplit costs and reduce your carbon footprint together"
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        subtitleLabel.font = AppDesign.Typography.body
        subtitleLabel.textAlignment = .center
        buildInfoCards()

        var ctaConfig = UIButton.Configuration.filled()
        ctaConfig.title = "Get Started"
        ctaConfig.baseBackgroundColor = .white
        ctaConfig.baseForegroundColor = AppDesign.Color.primary
        ctaConfig.cornerStyle = .large
        ctaConfig.attributedTitle = AttributedString(
            "Get Started",
            attributes: AttributeContainer([.font: AppDesign.Typography.title])
        )
        nextButton.configuration = ctaConfig
        nextButton.isEnabled = true
        nextButton.alpha = 1
    }

    private func buildInfoCards() {
        guard infoStack.superview == nil else { return }
        infoStack.axis = .vertical
        infoStack.spacing = 14
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        infoStack.addArrangedSubview(makeInfoCard(
            title: "Connect with Peers",
            subtitle: "Share rides with students and faculty from your university",
            icon: "person.3.fill"
        ))
        infoStack.addArrangedSubview(makeInfoCard(
            title: "Save Money & Environment",
            subtitle: "Split costs and reduce your carbon footprint together",
            icon: "leaf.fill"
        ))

        view.addSubview(infoStack)
        NSLayoutConstraint.activate([
            infoStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            infoStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            infoStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: nextButton.topAnchor, constant: -24)
        ])
    }

    private func makeInfoCard(title: String, subtitle: String, icon: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        card.layer.cornerRadius = AppDesign.Radius.md

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = AppDesign.Typography.bodyStrong

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = AppDesign.Typography.subheadline
        subtitleLabel.numberOfLines = 2

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 92),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    @IBAction private func nextTapped(_ sender: UIButton) {
        completeOnboarding()
    }

    @IBAction private func skipTapped(_ sender: UIButton) {
        completeOnboarding()
    }

    @IBAction private func pageChanged(_ sender: UIPageControl) {}

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let emailVC = storyboard.instantiateViewController(withIdentifier: "EmailViewController")
        let nav = UINavigationController(rootViewController: emailVC)

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }
}
