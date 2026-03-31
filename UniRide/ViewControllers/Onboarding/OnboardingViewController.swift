import UIKit

// MARK: - Data

struct OnboardingPage {
    let systemIcon:  String
    let topColor:    UIColor
    let bottomColor: UIColor
    let eyebrow:     String     // small uppercase label above title
    let title:       String
    let subtitle:    String
}

// MARK: - OnboardingViewController

final class OnboardingViewController: UIViewController {

    // Storyboard outlets — kept so IB wires don't crash; all hidden below
    @IBOutlet private weak var imageView:     UIImageView!
    @IBOutlet private weak var titleLabel:    UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var pageControl:   UIPageControl!
    @IBOutlet private weak var nextButton:    UIButton!

    // MARK: Pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemIcon:  "car.2.fill",
            topColor:    UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1),
            bottomColor: UIColor(red: 0.05, green: 0.20, blue: 0.75, alpha: 1),
            eyebrow:     "CAMPUS COMMUTE",
            title:       "Ride Together,\nSave Together",
            subtitle:    "UniRide connects Chitkara students and faculty for safe, affordable carpools — right to your doorstep."
        ),
        OnboardingPage(
            systemIcon:  "checkmark.shield.fill",
            topColor:    UIColor(red: 0.38, green: 0.18, blue: 0.92, alpha: 1),
            bottomColor: UIColor(red: 0.18, green: 0.06, blue: 0.68, alpha: 1),
            eyebrow:     "100% VERIFIED",
            title:       "Only University\nMembers",
            subtitle:    "Every rider and driver signs in with their Chitkara email — no strangers, just trusted peers from your campus."
        ),
        OnboardingPage(
            systemIcon:  "indianrupeesign.circle.fill",
            topColor:    UIColor(red: 0.08, green: 0.68, blue: 0.55, alpha: 1),
            bottomColor: UIColor(red: 0.04, green: 0.45, blue: 0.38, alpha: 1),
            eyebrow:     "SMART PRICING",
            title:       "Fare Split That's\nActually Fair",
            subtitle:    "Our pricing engine accounts for distance, seats, and peak hours — so everyone pays exactly their share."
        ),
        OnboardingPage(
            systemIcon:  "leaf.circle.fill",
            topColor:    UIColor(red: 0.16, green: 0.76, blue: 0.28, alpha: 1),
            bottomColor: UIColor(red: 0.06, green: 0.50, blue: 0.18, alpha: 1),
            eyebrow:     "GO GREEN",
            title:       "Fewer Cars,\nCleaner Campus",
            subtitle:    "Every shared ride removes one more car from the road. Small choices add up to a greener Chitkara."
        )
    ]

    // MARK: Programmatic Views
    private let gradientView = GradientView()

    // Floating decorative circles
    private var floatingCircles: [UIView] = []

    // Icon container (sits in gradient area)
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()

    // Bottom sliding panel
    private let bottomPanel   = UIView()
    private let eyebrowLabel  = UILabel()
    private let pageTitleLabel = UILabel()
    private let pageSubtitle   = UILabel()
    private let progressBar    = UIView()
    private var progressIndicator = UIView()
    private let ctaButton      = UIButton(type: .system)
    private let skipLabel      = UIButton(type: .system)

    private var currentPage = 0
    private var progressLeading: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        hideStoryboardOutlets()
        buildGradient()
        buildDecorativeCircles()
        buildIconArea()
        buildBottomPanel()
        applyPage(pages[0], animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomPanel.layer.shadowPath = UIBezierPath(
            roundedRect: bottomPanel.bounds,
            cornerRadius: 36
        ).cgPath
        updateProgressBar(animated: false)
    }

    private func hideStoryboardOutlets() {
        imageView?.isHidden     = true
        titleLabel?.isHidden    = true
        subtitleLabel?.isHidden = true
        pageControl?.isHidden   = true
        nextButton?.isHidden    = true
    }

    // MARK: - Build Gradient (Top 65%)

    private func buildGradient() {
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.64)
        ])
    }

    // MARK: - Decorative Circles

    private func buildDecorativeCircles() {
        let specs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            // size, x-multiplier, y-multiplier, alpha
            (220, 0.78, 0.08, 0.12),
            (140, 0.10, 0.20, 0.10),
            (80,  0.85, 0.52, 0.08),
            (60,  0.05, 0.55, 0.09),
            (100, 0.50, 0.02, 0.07)
        ]
        let screenW = UIScreen.main.bounds.width
        let gradH   = UIScreen.main.bounds.height * 0.64  // matches the 0.64 height multiplier

        for spec in specs {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(spec.3)
            circle.translatesAutoresizingMaskIntoConstraints = false
            gradientView.addSubview(circle)
            circle.layer.cornerRadius = spec.0 / 2
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: spec.0),
                circle.heightAnchor.constraint(equalToConstant: spec.0),
                circle.centerXAnchor.constraint(equalTo: gradientView.leadingAnchor,
                                                constant: screenW * spec.1),
                circle.centerYAnchor.constraint(equalTo: gradientView.topAnchor,
                                                constant: gradH   * spec.2)
            ])
            floatingCircles.append(circle)
        }
        startFloatAnimation()
    }

    private func startFloatAnimation() {
        for (i, circle) in floatingCircles.enumerated() {
            let delay = Double(i) * 0.4
            let duration = 2.8 + Double(i) * 0.5
            UIView.animate(withDuration: duration, delay: delay,
                           options: [.autoreverse, .repeat, .allowUserInteraction],
                           animations: {
                circle.transform = CGAffineTransform(translationX: CGFloat.random(in: -14...14),
                                                     y: CGFloat.random(in: -14...14))
            })
        }
    }

    // MARK: - Icon Area

    private func buildIconArea() {
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        iconContainer.layer.cornerRadius = 42
        iconContainer.layer.borderWidth  = 1.5
        iconContainer.layer.borderColor  = UIColor.white.withAlphaComponent(0.35).cgColor
        gradientView.addSubview(iconContainer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconContainer.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 146),
            iconContainer.heightAnchor.constraint(equalToConstant: 146),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 72),
            iconImageView.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    // MARK: - Bottom Panel

    private func buildBottomPanel() {
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.backgroundColor = .systemBackground
        bottomPanel.layer.cornerRadius    = 36
        bottomPanel.layer.maskedCorners   = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomPanel.layer.shadowColor     = UIColor.black.cgColor
        bottomPanel.layer.shadowOpacity   = 0.12
        bottomPanel.layer.shadowOffset    = CGSize(width: 0, height: -4)
        bottomPanel.layer.shadowRadius    = 20
        view.addSubview(bottomPanel)

        NSLayoutConstraint.activate([
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height * 0.57)
        ])

        // Eyebrow
        eyebrowLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        eyebrowLabel.textColor = AppDesign.Color.primary.withAlphaComponent(0.7)
        eyebrowLabel.letterSpacing(2.0)
        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false

        // Title
        pageTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        pageTitleLabel.textColor    = .label
        pageTitleLabel.numberOfLines = 2
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        pageSubtitle.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        pageSubtitle.textColor = .secondaryLabel
        pageSubtitle.numberOfLines = 0
        pageSubtitle.lineBreakMode = .byWordWrapping
        pageSubtitle.translatesAutoresizingMaskIntoConstraints = false

        // Progress bar track
        let track = UIView()
        track.backgroundColor = .systemGray5
        track.layer.cornerRadius = 2.5
        track.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.addSubview(track)

        // Progress fill
        progressIndicator.backgroundColor = AppDesign.Color.primary
        progressIndicator.layer.cornerRadius = 2.5
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(progressIndicator)

        progressLeading = progressIndicator.leadingAnchor.constraint(equalTo: track.leadingAnchor)
        NSLayoutConstraint.activate([
            track.topAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: 24),
            track.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 28),
            track.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -28),
            track.heightAnchor.constraint(equalToConstant: 5),

            progressIndicator.topAnchor.constraint(equalTo: track.topAnchor),
            progressIndicator.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            progressIndicator.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: 1.0 / CGFloat(pages.count)),
            progressLeading!
        ])

        // Skip button top right
        skipLabel.setTitle("Skip", for: .normal)
        skipLabel.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        skipLabel.setTitleColor(.white, for: .normal)
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        skipLabel.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipLabel)

        NSLayoutConstraint.activate([
            skipLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        // Text content
        let textStack = UIStackView(arrangedSubviews: [eyebrowLabel, pageTitleLabel, pageSubtitle])
        textStack.axis = .vertical
        textStack.spacing = 10
        textStack.setCustomSpacing(6, after: eyebrowLabel)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.addSubview(textStack)

        // CTA Button
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.layer.cornerRadius = 16
        ctaButton.clipsToBounds = true
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        ctaButton.backgroundColor = AppDesign.Color.primary
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        bottomPanel.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 28),
            textStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 28),
            textStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -28),

            ctaButton.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 24),
            ctaButton.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -24),
            ctaButton.bottomAnchor.constraint(equalTo: bottomPanel.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Swipe gesture on gradient area
        let swipeLeft  = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        gradientView.addGestureRecognizer(swipeLeft)
        gradientView.addGestureRecognizer(swipeRight)
        bottomPanel.addGestureRecognizer(UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft)))
    }

    // MARK: - Apply Page

    private func applyPage(_ page: OnboardingPage, animated: Bool) {
        let isLast = currentPage == pages.count - 1
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .medium)
        iconImageView.image = UIImage(systemName: page.systemIcon, withConfiguration: config)

        if animated {
            // Icon bounce
            UIView.animate(withDuration: 0.15, animations: {
                self.iconContainer.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
                self.iconContainer.alpha = 0
            }) { _ in
                UIView.animate(withDuration: 0.35, delay: 0,
                               usingSpringWithDamping: 0.6,
                               initialSpringVelocity: 0.6, options: [], animations: {
                    self.iconContainer.transform = .identity
                    self.iconContainer.alpha = 1
                })
            }

            // Text crossfade
            UIView.animate(withDuration: 0.18, animations: {
                self.eyebrowLabel.alpha = 0
                self.pageTitleLabel.alpha = 0
                self.pageSubtitle.alpha = 0
            }) { _ in
                self.updateTextContent(page: page, isLast: isLast)
                UIView.animate(withDuration: 0.28) {
                    self.eyebrowLabel.alpha = 1
                    self.pageTitleLabel.alpha = 1
                    self.pageSubtitle.alpha = 1
                }
            }

            // Gradient
            gradientView.animate(to: [page.topColor, page.bottomColor], duration: 0.5)
        } else {
            iconContainer.alpha = 1
            iconContainer.transform = .identity
            updateTextContent(page: page, isLast: isLast)
            gradientView.animate(to: [page.topColor, page.bottomColor], duration: 0)
        }

        updateProgressBar(animated: animated)
    }

    private func updateTextContent(page: OnboardingPage, isLast: Bool) {
        eyebrowLabel.text               = page.eyebrow
        pageTitleLabel.attributedText   = makeTitle(page.title)
        pageSubtitle.text               = page.subtitle
        ctaButton.setTitle(isLast ? "Get Started →" : "Continue →", for: .normal)
        UIView.animate(withDuration: 0.2, animations: {
            self.skipLabel.alpha = isLast ? 0 : 1
        })
    }

    private func makeTitle(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ])
    }

    private func updateProgressBar(animated: Bool) {
        guard let track = progressIndicator.superview else { return }
        let barWidth = track.bounds.width
        guard barWidth > 0 else { return }
        let stepWidth = barWidth / CGFloat(pages.count)
        let offset = stepWidth * CGFloat(currentPage)

        progressLeading?.constant = offset
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0) {
                track.layoutIfNeeded()
            }
        }
    }

    // MARK: - Actions

    @IBAction private func nextTapped(_ sender: UIButton)    { advance() }
    @IBAction private func pageChanged(_ sender: UIPageControl) {}
    @IBAction private func skipTapped(_ sender: UIButton)   { performSkip() }

    @objc private func primaryTapped() { advance() }

    @objc private func performSkip() {
        AppHaptics.selection()
        completeOnboarding()
    }

    @objc private func handleSwipeLeft()  { advance() }
    @objc private func handleSwipeRight() {
        guard currentPage > 0 else { return }
        currentPage -= 1
        AppHaptics.selection()
        applyPage(pages[currentPage], animated: true)
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            AppHaptics.selection()
            applyPage(pages[currentPage], animated: true)
        } else {
            AppHaptics.success()
            completeOnboarding()
        }
        // Button bounce
        UIView.animate(withDuration: 0.1, animations: {
            self.ctaButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: [], animations: {
                self.ctaButton.transform = .identity
            }, completion: nil)
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let rootVC: UIViewController
        
        // If guest (skipped), go directly to Tab Bar. Otherwise (Get Started), go to Email.
        if currentPage < pages.count - 1 {
            // "Skip" tapped
            rootVC = sb.instantiateViewController(withIdentifier: "MainTabBarController")
        } else {
            // "Get Started" tapped
            let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
            rootVC = UINavigationController(rootViewController: emailVC)
        }
        
        if let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = scene.window {
            window.rootViewController = rootVC
            UIView.transition(with: window, duration: 0.45, options: .transitionCrossDissolve, animations: nil)
        }
    }
}

// MARK: - UILabel letter spacing helper
private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let t = text else { return }
        let attr = NSMutableAttributedString(string: t)
        attr.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: t.count))
        attributedText = attr
    }
}

// MARK: - Animated Gradient View

final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.85, y: 1)
    }
    required init?(coder: NSCoder) { fatalError() }

    func animate(to colors: [UIColor], duration: TimeInterval) {
        let newColors = colors.map { $0.cgColor }
        if duration > 0 {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = gradientLayer.colors
            anim.toValue   = newColors
            anim.duration  = duration
            anim.fillMode  = .forwards
            anim.isRemovedOnCompletion = false
            gradientLayer.add(anim, forKey: "grad")
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.colors = newColors
        CATransaction.commit()
    }
}
