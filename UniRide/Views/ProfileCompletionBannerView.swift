import UIKit

/// Compact banner shown at the top of the Profile screen when the user's profile is incomplete.
/// Attach to the view above the scroll view and update `scrollView.contentInset.top` accordingly.
final class ProfileCompletionBannerView: UIView {

    // MARK: - Public
    /// Called when the user taps a step row. The caller handles navigation.
    var onStepTapped: ((ProfileCompletionStep) -> Void)?
    /// Called when the user taps ✕ to dismiss.
    var onDismiss: (() -> Void)?

    // MARK: - Private UI
    private let progressView   = UIProgressView(progressViewStyle: .default)
    private let fractionLabel  = UILabel()
    private let stepsStack     = UIStackView()

    // MARK: - Init

    init(completion: ProfileCompletion) {
        super.init(frame: .zero)
        buildUI(completion: completion)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildUI(completion: ProfileCompletion) {
        backgroundColor     = .systemBackground
        layer.cornerRadius  = 16
        layer.shadowColor   = AppDesign.Color.shadow.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius  = 8
        layer.shadowOffset  = CGSize(width: 0, height: 3)
        clipsToBounds       = false

        // ── Header row ──────────────────────────────────────────
        let titleLabel         = UILabel()
        titleLabel.text        = "Your profile is \(completion.percentage)% complete"
        titleLabel.font        = AppDesign.Typography.bodyStrong
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stepsLeft = completion.steps.count - completion.completedSteps.count
        fractionLabel.text     = "\(stepsLeft) step\(stepsLeft == 1 ? "" : "s") left"
        fractionLabel.font     = AppDesign.Typography.caption
        fractionLabel.textColor = .secondaryLabel
        fractionLabel.translatesAutoresizingMaskIntoConstraints = false

        let dismissBtn         = UIButton(type: .system)
        dismissBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        dismissBtn.tintColor   = .systemGray3
        dismissBtn.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, fractionLabel, dismissBtn])
        headerStack.axis      = .horizontal
        headerStack.spacing   = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // ── Progress bar ─────────────────────────────────────────
        progressView.progressTintColor   = .systemGreen
        progressView.trackTintColor      = UIColor.systemGreen.withAlphaComponent(0.15)
        progressView.layer.cornerRadius  = 3
        progressView.clipsToBounds       = true
        progressView.progress            = Float(completion.percentage) / 100
        progressView.translatesAutoresizingMaskIntoConstraints = false

        let pctLabel         = UILabel()
        pctLabel.text        = "\(completion.percentage)%"
        pctLabel.font        = AppDesign.Typography.caption
        pctLabel.textColor   = .systemGreen
        pctLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Step rows ────────────────────────────────────────────
        stepsStack.axis         = .vertical
        stepsStack.spacing      = 0
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        for step in completion.steps {
            let isDone = completion.completedSteps.contains(step)
            stepsStack.addArrangedSubview(makeStepRow(step, done: isDone))
        }

        // ── Main vertical stack ──────────────────────────────────
        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            progressView,
            pctLabel,
            stepsStack,
        ])
        mainStack.axis    = .vertical
        mainStack.spacing = 8
        mainStack.setCustomSpacing(3, after: progressView)
        mainStack.setCustomSpacing(10, after: pctLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            progressView.heightAnchor.constraint(equalToConstant: 5),
            dismissBtn.widthAnchor.constraint(equalToConstant: 44),
            dismissBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Step Row Factory

    private func makeStepRow(_ step: ProfileCompletionStep, done: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let icon = UIImageView()
        icon.image = done
            ? UIImage(systemName: "checkmark.circle.fill")
            : UIImage(systemName: step.systemImage)
        icon.tintColor = done ? .systemGreen : .systemOrange
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        // Title + subtitle
        let titleLbl = UILabel()
        titleLbl.text = step.title
        titleLbl.font = done ? AppDesign.Typography.caption : AppDesign.Typography.captionStrong
        titleLbl.textColor = done ? .secondaryLabel : .label

        let subLbl = UILabel()
        subLbl.text = step.subtitle
        subLbl.font = AppDesign.Typography.caption
        subLbl.textColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical; textStack.spacing = 1

        // Chevron (hidden when done)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .systemGray3
        chevron.contentMode = .scaleAspectFit
        chevron.isHidden = done

        let row = UIStackView(arrangedSubviews: [icon, textStack, chevron])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14),

            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        // Separator line (not for last row — handled by caller)
        let sep = UIView()
        sep.backgroundColor = .systemGray6
        sep.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 38),
            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // Tap gesture for incomplete steps
        if !done {
            let tap = StepTapGestureRecognizer(step: step, target: self, action: #selector(stepTapped(_:)))
            container.addGestureRecognizer(tap)
            container.isUserInteractionEnabled = true
        }

        return container
    }

    // MARK: - Actions

    @objc private func stepTapped(_ gesture: StepTapGestureRecognizer) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onStepTapped?(gesture.step)
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }
}

// MARK: - Step Tap Helper

private final class StepTapGestureRecognizer: UITapGestureRecognizer {
    let step: ProfileCompletionStep
    init(step: ProfileCompletionStep, target: Any?, action: Selector?) {
        self.step = step
        super.init(target: target, action: action)
    }
}
