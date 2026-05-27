import UIKit

protocol RequestCellDelegate: AnyObject {
    func requestCellApproveTapped(_ cell: RequestCell)
    func requestCellDenyTapped(_ cell: RequestCell)
}

/// Fully programmatic cell — avoids XIB layout bugs (nameLabel had no trailing
/// constraint and approveButton had no leading constraint, causing right-edge clipping).
final class RequestCell: UITableViewCell {

    static let identifier = "RequestCell"

    // MARK: - Subviews
    private let avatarView  = UIImageView()
    private let nameLabel   = UILabel()
    private let subtitleLabel = UILabel()
    private let approveBtn  = UIButton(type: .system)
    private let denyBtn     = UIButton(type: .system)

    weak var delegate: RequestCellDelegate?

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.layer.cornerRadius = avatarView.bounds.height / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        nameLabel.text   = nil
        subtitleLabel.text = nil
    }

    // MARK: - Build
    private func build() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Avatar
        avatarView.clipsToBounds    = true
        avatarView.contentMode      = .scaleAspectFill
        avatarView.backgroundColor  = AppDesign.Color.borderSubtle
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font      = AppDesign.Typography.subheadline
        nameLabel.textColor = AppDesign.Color.textPrimary
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle (role/dept)
        subtitleLabel.font      = AppDesign.Typography.caption
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Approve button
        let approveImg = UIImage(systemName: "checkmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        approveBtn.setImage(approveImg, for: .normal)
        approveBtn.tintColor = AppDesign.Color.success
        approveBtn.translatesAutoresizingMaskIntoConstraints = false
        approveBtn.addTarget(self, action: #selector(approveTapped), for: .touchUpInside)

        // Deny button
        let denyImg = UIImage(systemName: "xmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        denyBtn.setImage(denyImg, for: .normal)
        denyBtn.tintColor = AppDesign.Color.destructive
        denyBtn.translatesAutoresizingMaskIntoConstraints = false
        denyBtn.addTarget(self, action: #selector(denyTapped), for: .touchUpInside)

        // Text stack
        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis    = .vertical
        textStack.spacing = 2
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Button stack
        let btnStack = UIStackView(arrangedSubviews: [approveBtn, denyBtn])
        btnStack.axis    = .horizontal
        btnStack.spacing = 8
        btnStack.alignment = .center
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        approveBtn.setContentHuggingPriority(.required, for: .horizontal)
        approveBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        denyBtn.setContentHuggingPriority(.required, for: .horizontal)
        denyBtn.setContentCompressionResistancePriority(.required, for: .horizontal)

        [avatarView, textStack, btnStack].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            // Avatar — left-pinned, fixed 40×40
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            // Buttons — right-pinned, fixed 36×36 each
            btnStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            btnStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            approveBtn.widthAnchor.constraint(equalToConstant: 36),
            approveBtn.heightAnchor.constraint(equalToConstant: 36),
            denyBtn.widthAnchor.constraint(equalToConstant: 36),
            denyBtn.heightAnchor.constraint(equalToConstant: 36),

            // Text — fills the space between avatar and buttons
            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: btnStack.leadingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // Minimum cell height
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
    }

    // MARK: - Configure
    func configure(name: String, subtitle: String, photoURL: URL? = nil) {
        nameLabel.text     = name
        subtitleLabel.text = subtitle
        avatarView.loadAndFallback(from: photoURL, name: name)
    }

    // MARK: - Actions
    @objc private func approveTapped() { delegate?.requestCellApproveTapped(self) }
    @objc private func denyTapped()    { delegate?.requestCellDenyTapped(self) }

    // Keep IBAction stubs for XIB compatibility (not used at runtime)
    @IBAction func approveTappedIB(_ sender: UIButton) { delegate?.requestCellApproveTapped(self) }
    @IBAction func denyTappedIB(_ sender: UIButton)    { delegate?.requestCellDenyTapped(self) }
}
