import UIKit

struct OnboardingSlide {
    let imageName: String
    let title: String
    let subtitle: String
}

final class OnboardingViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var nextButton: UIButton!

    // MARK: - Data
    private let slides: [OnboardingSlide] = [
        .init(
            imageName: "onboard_1",
            title: "Find rides with your college community",
            subtitle: "Connect with fellow students for safe, affordable rides"
        ),
        .init(
            imageName: "onboard_2",
            title: "Save money & help the planet",
            subtitle: "Split costs and reduce carbon footprint together"
        ),
        .init(
            imageName: "onboard_3",
            title: "Stay safe with verified profiles",
            subtitle: "All members verified through college email"
        )
    ]

    private var currentIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        updateSlide(animated: false)
    }

    // MARK: - UI Setup
    private func configureUI() {
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = currentIndex

        nextButton.layer.cornerRadius = 20

        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true

        navigationItem.hidesBackButton = true
    }

    // MARK: - Slide Update
    private func updateSlide(animated: Bool) {

        let slide = slides[currentIndex]

        pageControl.currentPage = currentIndex

        let buttonTitle = currentIndex == slides.count - 1
            ? "Get Started"
            : "Next"

        nextButton.setTitle(buttonTitle, for: .normal)

        if animated {
            animateSlideChange(slide)
        } else {
            apply(slide)
        }
    }

    private func apply(_ slide: OnboardingSlide) {
        imageView.image = UIImage(named: slide.imageName)
        titleLabel.text = slide.title
        subtitleLabel.text = slide.subtitle
    }

    private func animateSlideChange(_ slide: OnboardingSlide) {

        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve) {
            self.imageView.image = UIImage(named: slide.imageName)
        }

        UIView.transition(with: titleLabel,
                          duration: 0.3,
                          options: .transitionCrossDissolve) {
            self.titleLabel.text = slide.title
        }

        UIView.transition(with: subtitleLabel,
                          duration: 0.3,
                          options: .transitionCrossDissolve) {
            self.subtitleLabel.text = slide.subtitle
        }
    }

    // MARK: - Actions
    @IBAction private func nextTapped(_ sender: UIButton) {
        advance()
    }

    @IBAction private func skipTapped(_ sender: UIButton) {
        completeOnboarding()
    }

    @IBAction private func pageChanged(_ sender: UIPageControl) {
        currentIndex = sender.currentPage
        updateSlide(animated: true)
    }

    private func advance() {
        if currentIndex < slides.count - 1 {
            currentIndex += 1
            updateSlide(animated: true)
        } else {
            completeOnboarding()
        }
    }

    // MARK: - Finish Flow
    private func completeOnboarding() {

        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let emailVC = storyboard.instantiateViewController(
            withIdentifier: "EmailViewController"
        )

        let nav = UINavigationController(rootViewController: emailVC)

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }
}

