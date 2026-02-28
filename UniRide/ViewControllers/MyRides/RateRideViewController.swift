import UIKit

/// Bottom-sheet VC for rating a driver or passenger after a completed ride.
final class RateRideViewController: UIViewController {

    // MARK: - Dependencies
    var rideID: UUID!
    var revieweeID: UUID!
    var revieweeName: String = ""
    var revieweePhotoURL: URL? = nil
    var onSubmitted: (() -> Void)?

    // MARK: - State
    private var selectedStars: Int = 0

    // MARK: - UI
    private let card        = UIView()
    private let grabber     = UIView()
    private let avatarView  = UIImageView()
    private let nameLabel   = UILabel()
    private let promptLabel = UILabel()
    private var starButtons: [UIButton] = []
    private let commentView = UITextView()
    private let submitBtn   = UIButton(type: .system)
    private let skipBtn     = UIButton(type: .system)

    // MARK: - Init
    init(rideID: UUID, revieweeID: UUID, name: String, photoURL: URL?) {
        super.init(nibName: nil, bundle: nil)
        self.rideID          = rideID
        self.revieweeID      = revieweeID
        self.revieweeName    = name
        self.revieweePhotoURL = photoURL
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents           = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = AppDesign.Radius.lg
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
    }

    // MARK: - UI Construction
    private func buildUI() {
        // Avatar
        avatarView.contentMode      = .scaleAspectFill
        avatarView.clipsToBounds    = true
        avatarView.layer.cornerRadius = 35
        avatarView.backgroundColor  = .systemGray5
        avatarView.layer.borderWidth = 2.5
        avatarView.layer.borderColor = AppDesign.Color.primary.withAlphaComponent(0.6).cgColor
        avatarView.loadAndFallback(from: revieweePhotoURL, name: revieweeName)
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.text      = revieweeName
        nameLabel.font      = AppDesign.Typography.bodyStrong
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Prompt
        promptLabel.text    = "How was your ride?"
        promptLabel.font    = AppDesign.Typography.subheadline
        promptLabel.textColor = .secondaryLabel
        promptLabel.textAlignment = .center
        promptLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stars row
        let starStack = UIStackView()
        starStack.axis = .horizontal
        starStack.spacing = 10
        starStack.alignment = .center
        starStack.translatesAutoresizingMaskIntoConstraints = false

        for i in 1...5 {
            let btn = UIButton(type: .system)
            btn.tag = i
            btn.setImage(UIImage(systemName: "star"), for: .normal)
            btn.tintColor = .systemGray3
            btn.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 44),
                btn.heightAnchor.constraint(equalToConstant: 44),
            ])
            btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            starButtons.append(btn)
            starStack.addArrangedSubview(btn)
        }

        // Comment
        commentView.text            = "Add a comment (optional)..."
        commentView.textColor       = .tertiaryLabel
        commentView.font            = AppDesign.Typography.subheadline
        commentView.backgroundColor = AppDesign.Color.fieldBackground
        commentView.layer.cornerRadius = AppDesign.Radius.sm
        commentView.layer.masksToBounds = true
        commentView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        commentView.delegate        = self
        commentView.translatesAutoresizingMaskIntoConstraints = false

        // Submit
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Submit Rating"
        cfg.image = UIImage(systemName: "checkmark.circle.fill")
        cfg.imagePlacement = .leading
        cfg.imagePadding = 6
        cfg.baseBackgroundColor = AppDesign.Color.primary
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        submitBtn.configuration = cfg
        submitBtn.setPrimaryCTAEnabled(false)
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitBtn.translatesAutoresizingMaskIntoConstraints = false

        // Skip
        skipBtn.setTitle("Skip", for: .normal)
        skipBtn.setTitleColor(.tertiaryLabel, for: .normal)
        skipBtn.titleLabel?.font = AppDesign.Typography.subheadline
        skipBtn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipBtn.translatesAutoresizingMaskIntoConstraints = false

        // Layout
        [avatarView, nameLabel, promptLabel, starStack, commentView, submitBtn, skipBtn]
            .forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 70),
            avatarView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            promptLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            promptLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            starStack.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 16),
            starStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            commentView.topAnchor.constraint(equalTo: starStack.bottomAnchor, constant: 16),
            commentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            commentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            commentView.heightAnchor.constraint(equalToConstant: 72),

            submitBtn.topAnchor.constraint(equalTo: commentView.bottomAnchor, constant: 16),
            submitBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            submitBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            submitBtn.heightAnchor.constraint(equalToConstant: 50),

            skipBtn.topAnchor.constraint(equalTo: submitBtn.bottomAnchor, constant: 8),
            skipBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Star Interaction
    @objc private func starTapped(_ sender: UIButton) {
        selectedStars = sender.tag
        updateStarUI()

        // Enable submit
        UIView.animate(withDuration: 0.2) {
            self.submitBtn.setPrimaryCTAEnabled(true)
        }

        // Haptic
        AppHaptics.impact(.light)
    }

    private func updateStarUI() {
        for (i, btn) in starButtons.enumerated() {
            let filled = i < selectedStars
            let imageName = filled ? "star.fill" : "star"
            btn.setImage(UIImage(systemName: imageName), for: .normal)
            btn.tintColor = filled ? .systemYellow : .systemGray3

            // Bounce animation on selected star
            if filled {
                UIView.animate(withDuration: 0.1, animations: {
                    btn.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                }) { _ in
                    UIView.animate(withDuration: 0.1) {
                        btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func submitTapped() {
        guard selectedStars > 0,
              let reviewerID = UserDataModel.shared.getCurrentUser()?.id
        else { return }

        let comment = commentView.textColor == .tertiaryLabel ? nil : commentView.text

        let review = Review(
            id: UUID(),
            rideID: rideID,
            reviewerID: reviewerID,
            revieweeID: revieweeID,
            stars: selectedStars,
            comment: comment?.isEmpty == true ? nil : comment,
            timestamp: Date()
        )

        ReviewDataModel.shared.submit(review: review)

        AppHaptics.success()
        dismiss(animated: true) { [weak self] in
            self?.onSubmitted?()
        }
    }

    @objc private func skipTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onSubmitted?()
        }
    }
}

// MARK: - TextView Delegate (placeholder behaviour)
extension RateRideViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .tertiaryLabel {
            textView.text = ""
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Add a comment (optional)..."
            textView.textColor = .tertiaryLabel
        }
    }
}
