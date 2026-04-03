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
    @IBOutlet private weak var gradientView: GradientView!
    @IBOutlet private weak var decorativeCircle1: UIView!
    @IBOutlet private weak var decorativeCircle2: UIView!
    @IBOutlet private weak var decorativeCircle3: UIView!
    @IBOutlet private weak var decorativeCircle4: UIView!
    @IBOutlet private weak var decorativeCircle5: UIView!
    @IBOutlet private weak var iconContainer: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var bottomPanel: UIView!
    @IBOutlet private weak var eyebrowLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var progressIndicator: UIView!
    @IBOutlet private weak var progressLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var skipButton: UIButton!

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

    private var currentPage = 0
    private var hasStartedFloatingAnimation = false

    private var floatingCircles: [UIView] {
        [decorativeCircle1, decorativeCircle2, decorativeCircle3, decorativeCircle4, decorativeCircle5]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticUI()
        installGestures()
        applyPage(pages[0], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStartedFloatingAnimation else { return }
        hasStartedFloatingAnimation = true
        startFloatAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for circle in floatingCircles {
            circle.layer.cornerRadius = circle.bounds.width / 2
        }
        bottomPanel.layer.shadowPath = UIBezierPath(
            roundedRect: bottomPanel.bounds,
            cornerRadius: 36
        ).cgPath
        updateProgressBar(animated: false)
    }

    private func configureStaticUI() {
        view.backgroundColor = UIColor(red: 0.937254902, green: 0.97254902, blue: 1, alpha: 1)

        let alphas: [CGFloat] = [0.12, 0.10, 0.08, 0.09, 0.07]
        for (index, circle) in floatingCircles.enumerated() {
            circle.backgroundColor = UIColor.white.withAlphaComponent(alphas[index])
            circle.layer.cornerRadius = circle.bounds.width / 2
        }

        iconContainer.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        iconContainer.layer.cornerRadius = 42
        iconContainer.layer.borderWidth = 1.5
        iconContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        bottomPanel.backgroundColor = .systemBackground
        bottomPanel.layer.cornerRadius = 36
        bottomPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomPanel.layer.shadowColor = UIColor.black.cgColor
        bottomPanel.layer.shadowOpacity = 0.12
        bottomPanel.layer.shadowOffset = CGSize(width: 0, height: -4)
        bottomPanel.layer.shadowRadius = 20

        eyebrowLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        eyebrowLabel.textColor = AppDesign.Color.primary.withAlphaComponent(0.7)
        eyebrowLabel.letterSpacing(2.0)

        titleLabel.numberOfLines = 2
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        progressIndicator.backgroundColor = AppDesign.Color.primary
        progressIndicator.layer.cornerRadius = 2.5

        nextButton.layer.cornerRadius = 16
        nextButton.clipsToBounds = true
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nextButton.backgroundColor = AppDesign.Color.primary
        nextButton.setTitleColor(.white, for: .normal)

        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.isHidden = false
        skipButton.alpha = 1
        if let skipContainer = skipButton.superview {
            skipContainer.isHidden = false
            skipContainer.alpha = 1
            view.bringSubviewToFront(skipContainer)
        } else {
            view.bringSubviewToFront(skipButton)
        }
    }

    // MARK: - Decorative Circles

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

    private func installGestures() {
        let swipeLeft  = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        gradientView.addGestureRecognizer(swipeLeft)
        gradientView.addGestureRecognizer(swipeRight)
        let panelSwipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        panelSwipeLeft.direction = .left
        bottomPanel.addGestureRecognizer(panelSwipeLeft)
        let panelSwipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        panelSwipeRight.direction = .right
        bottomPanel.addGestureRecognizer(panelSwipeRight)
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
                self.titleLabel.alpha = 0
                self.subtitleLabel.alpha = 0
            }) { _ in
                self.updateTextContent(page: page, isLast: isLast)
                UIView.animate(withDuration: 0.28) {
                    self.eyebrowLabel.alpha = 1
                    self.titleLabel.alpha = 1
                    self.subtitleLabel.alpha = 1
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
        eyebrowLabel.text = page.eyebrow
        eyebrowLabel.letterSpacing(2.0)
        titleLabel.attributedText = makeTitle(page.title)
        subtitleLabel.text = page.subtitle
        nextButton.setTitle(isLast ? "Get Started →" : "Continue →", for: .normal)
        UIView.animate(withDuration: 0.2, animations: {
            self.skipButton.alpha = isLast ? 0 : 1
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

        progressLeadingConstraint.constant = offset
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0) {
                track.layoutIfNeeded()
            }
        }
    }

    // MARK: - Actions

    @IBAction private func nextTapped(_ sender: UIButton)    { advance() }
    @IBAction private func skipTapped(_ sender: UIButton)   { performSkip() }

    @objc private func performSkip() {
        AppHaptics.selection()
        completeOnboarding(openEmail: true)
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
            completeOnboarding(openEmail: true)
        }
        // Button bounce
        UIView.animate(withDuration: 0.1, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: [], animations: {
                self.nextButton.transform = .identity
            }, completion: nil)
        }
    }

    private func completeOnboarding(openEmail: Bool) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let rootVC: UIViewController
        let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
        rootVC = UINavigationController(rootViewController: emailVC)
        
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
        configureGradient()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGradient()
    }

    private func configureGradient() {
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.85, y: 1)
    }

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
