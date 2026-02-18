import UIKit

protocol RequestCellDelegate: AnyObject {
    func requestCellApproveTapped(_ cell: RequestCell)
    func requestCellDenyTapped(_ cell: RequestCell)
}

final class RequestCell: UITableViewCell {

    static let identifier = "RequestCell"

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var denyButton: UIButton!

    weak var delegate: RequestCellDelegate?

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
    }

    private func setupUI() {
        profileImageView.clipsToBounds = true

        approveButton.setImage(
            UIImage(systemName: "checkmark.circle.fill"),
            for: .normal
        )
        approveButton.tintColor = .systemGreen

        denyButton.setImage(
            UIImage(systemName: "xmark.circle.fill"),
            for: .normal
        )
        denyButton.tintColor = .systemRed
    }

    func configure(name: String, route: String, photoURL: URL? = nil) {
        nameLabel.text = name
        routeLabel.text = route
        
        profileImageView.loadAndFallback(from: photoURL, name: name)
    }

    @IBAction func approveTapped(_ sender: UIButton) {
        delegate?.requestCellApproveTapped(self)
    }

    @IBAction func denyTapped(_ sender: UIButton) {
        delegate?.requestCellDenyTapped(self)
    }
}
