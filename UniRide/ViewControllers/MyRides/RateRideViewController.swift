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

    // MARK: - IBOutlets
    @IBOutlet private var avatarView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var promptLabel: UILabel!
    @IBOutlet private var commentView: UITextView!
    @IBOutlet private var submitBtn: UIButton!
    @IBOutlet private var skipBtn: UIButton!

    // Individual star buttons (connected from storyboard)
    @IBOutlet private var starButton1: UIButton!
    @IBOutlet private var starButton2: UIButton!
    @IBOutlet private var starButton3: UIButton!
    @IBOutlet private var starButton4: UIButton!
    @IBOutlet private var starButton5: UIButton!

    private var starButtons: [UIButton] { [starButton1, starButton2, starButton3, starButton4, starButton5] }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureAvatar()
        configureLabels()
        configureCommentView()
        configureSubmitButton()
        configureSkipButton()
        configureStarButtons()
        if let sheet = sheetPresentationController {
            sheet.detents               = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = AppDesign.Radius.lg
        }
    }

    // MARK: - Configuration

    private func configureAvatar() {
        avatarView.layer.cornerRadius = 35
        avatarView.clipsToBounds      = true
        avatarView.layer.borderWidth  = 2.5
        avatarView.layer.borderColor  = AppDesign.Color.primary.withAlphaComponent(0.6).cgColor
        avatarView.loadAndFallback(from: revieweePhotoURL, name: revieweeName)
    }

    private func configureLabels() {
        nameLabel.text   = revieweeName
        nameLabel.font   = AppDesign.Typography.bodyStrong
        promptLabel.font = AppDesign.Typography.subheadline
    }

    private func configureCommentView() {
        commentView.layer.cornerRadius = AppDesign.Radius.sm
        commentView.layer.masksToBounds = true
        commentView.textContainerInset  = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        commentView.delegate            = self
    }

    private func configureSubmitButton() {
        var cfg = UIButton.Configuration.filled()
        cfg.title              = "Submit Rating"
        cfg.image              = UIImage(systemName: "checkmark.circle.fill")
        cfg.imagePlacement     = .leading
        cfg.imagePadding       = 6
        cfg.baseBackgroundColor = AppDesign.Color.primary
        cfg.baseForegroundColor = .white
        cfg.cornerStyle        = .capsule
        submitBtn.configuration = cfg
        submitBtn.setPrimaryCTAEnabled(false)
    }

    private func configureSkipButton() {
        skipBtn.setTitle("Skip", for: .normal)
        skipBtn.setTitleColor(.tertiaryLabel, for: .normal)
        skipBtn.titleLabel?.font = AppDesign.Typography.subheadline
    }

    private func configureStarButtons() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        for btn in starButtons {
            btn.configuration = nil
            btn.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            btn.setImage(UIImage(systemName: "star", withConfiguration: symbolConfig), for: .normal)
            btn.tintColor = .systemGray3
            btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        updateStarUI()
    }

    // MARK: - Star Interaction
    @IBAction private func starTapped(_ sender: UIButton) {
        selectedStars = sender.tag
        updateStarUI()
        UIView.animate(withDuration: 0.2) {
            self.submitBtn.setPrimaryCTAEnabled(true)
        }
        AppHaptics.impact(.light)
    }

    private func updateStarUI() {
        for (i, btn) in starButtons.enumerated() {
            let filled = i < selectedStars
            btn.setImage(UIImage(systemName: filled ? "star.fill" : "star"), for: .normal)
            btn.tintColor = filled ? .systemYellow : .systemGray3

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
    @IBAction private func submitTapped() {
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

    @IBAction private func skipTapped() {
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
