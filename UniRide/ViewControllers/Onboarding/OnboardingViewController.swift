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

    private func configureWelcomeUI() {
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor(red: 0.13, green: 0.46, blue: 0.97, alpha: 1)

        pageControl.isHidden = true

        imageView.image = UIImage(systemName: "car.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        imageView.layer.cornerRadius = 22
        imageView.clipsToBounds = true

        titleLabel.text = "UniRide"
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Your Campus Carpool Community\n\n• Connect with Peers\nShare rides with students and faculty from your university\n\n• Save Money & Environment\nSplit costs and reduce your carbon footprint together"
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.textAlignment = .center
        buildInfoCards()

        var ctaConfig = UIButton.Configuration.filled()
        ctaConfig.title = "Get Started"
        ctaConfig.baseBackgroundColor = .white
        ctaConfig.baseForegroundColor = UIColor(red: 0.13, green: 0.46, blue: 0.97, alpha: 1)
        ctaConfig.cornerStyle = .large
        ctaConfig.attributedTitle = AttributedString(
            "Get Started",
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 20, weight: .bold)])
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
        card.layer.cornerRadius = 18

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
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
