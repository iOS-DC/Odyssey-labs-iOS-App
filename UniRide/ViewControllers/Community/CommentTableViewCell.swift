import UIKit

protocol CommentTableViewCellDelegate: AnyObject {
    func commentCellDidTapReport(_ cell: CommentTableViewCell)
}

class CommentTableViewCell: UITableViewCell {
    
    static let identifier = "CommentTableViewCell"
    weak var delegate: CommentTableViewCellDelegate?
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18 // Slightly larger
        iv.backgroundColor = AppDesign.Color.fieldBackground
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = AppDesign.Color.border
        return iv
    }()
    
    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppDesign.Color.fieldBackground
        v.layer.cornerRadius = 14
        return v
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = AppDesign.Typography.captionStrong
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let commentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = AppDesign.Typography.subheadline
        l.numberOfLines = 0
        l.textColor = .label
        return l
    }()

    private lazy var reportButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "flag.fill")
        config.title = "0"
        config.baseForegroundColor = .secondaryLabel
        config.imagePadding = 4
        config.contentInsets = .zero
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppDesign.Typography.micro
            return outgoing
        }
        btn.configuration = config
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        contentView.addSubview(reportButton)
        bubbleView.addSubview(nameLabel)
        bubbleView.addSubview(commentLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            
            bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: reportButton.leadingAnchor, constant: -8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            reportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            reportButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            reportButton.widthAnchor.constraint(equalToConstant: 52),
            reportButton.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            commentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            commentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            commentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            commentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }

    @objc private func reportTapped() {
        delegate?.commentCellDidTapReport(self)
    }
    
    func configure(with comment: CommunityComment, authorName: String? = nil) {
        let name = authorName ?? comment.authorProfile?.fullName ?? "UniRide User"
        nameLabel.text = name
        commentLabel.text = comment.text
        var config = reportButton.configuration ?? UIButton.Configuration.plain()
        config.title = "\(comment.reportCount)"
        reportButton.configuration = config
        
        avatarImageView.loadAndFallback(from: comment.authorProfile?.photoURL, name: name)
    }
}
