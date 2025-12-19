import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        bubbleView.layer.cornerRadius = 12
        bubbleView.clipsToBounds = true
    }

    func configure(with message: Message) {

        messageLabel.text = message.text
        timeLabel.text = message.time

        let isDriver = message.senderId == "driver"

        if isDriver {
            // RIGHT side
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true

            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            timeLabel.textColor = .white.withAlphaComponent(0.7)
        } else {
            // LEFT side
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true

            bubbleView.backgroundColor = .systemGray5
            messageLabel.textColor = .black
            timeLabel.textColor = .gray
        }
    }
}

