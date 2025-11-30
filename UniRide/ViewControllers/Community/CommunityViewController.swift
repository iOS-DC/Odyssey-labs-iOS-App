import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sementedControl: UISegmentedControl!
    @IBOutlet weak var NewPostContainerView: UIView!
    @IBOutlet weak var NewPostTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newPostBottomConstraint: NSLayoutConstraint!

    struct Post {
        let name: String
        let subtitle: String
        let message: String
        let timestamp: String
    }

    var eventPosts: [Post] = [
        Post(name: "Event Admin", subtitle: "Organizing Team", message: "Rangrez 2025 Fest Starts Soon!", timestamp: "Nov 6, 2025 at 14:00")
    ]

    var feedPosts: [Post] = [
        Post(name: "Rehan Khan", subtitle: "3rd Year CSE", message: "Planning a weekend trip to Kasauli! Looking for 3 more people to share the ride and expenses. Comment if interested 🏖️", timestamp: "2 hours ago"),
        Post(name: "Krish", subtitle: "2nd Year IT", message: "Anyone interested in carpooling to the tech fest tomorrow? Sharing fuel and food costs!", timestamp: "1 hour ago")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Community"
        NewPostContainerView.isHidden = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddPost)
        )

        tableView.delegate = self
        tableView.dataSource = self
        newPostBottomConstraint.constant = 250
    }

    @objc func didTapAddPost() {
        NewPostContainerView.isHidden = false
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 90
        UIView.animate(withDuration: 0.3) {
            self.newPostBottomConstraint.constant = -tabBarHeight
            self.view.layoutIfNeeded()
        }
        NewPostTextField.becomeFirstResponder()
    }

    func hidePostSheet() {
        UIView.animate(withDuration: 0.3) {
            self.newPostBottomConstraint.constant = 250
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.NewPostContainerView.isHidden = true
        }
        NewPostTextField.resignFirstResponder()
    }

    @IBAction func closeNewPostView(_ sender: UIButton) {
        hidePostSheet()
    }

    @IBAction func postButtonTapped(_ sender: UIButton) {
        guard let typedText = NewPostTextField.text,
              !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newPost = Post(name: "Rehan Khan", subtitle: "3rd Year CSE", message: typedText, timestamp: "Just now")
        feedPosts.insert(newPost, at: 0)

        if sementedControl.selectedSegmentIndex == 0 {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        } else {
            let alert = UIAlertController(title: "Posted!", message: "Your post has been added to Feed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        NewPostTextField.text = ""
        hidePostSheet()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sementedControl.selectedSegmentIndex == 0 ? feedPosts.count : eventPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sementedControl.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
            let post = feedPosts[indexPath.row]

            if let nameLabel = cell.viewWithTag(2) as? UILabel {
                nameLabel.text = post.name
                nameLabel.adjustsFontSizeToFitWidth = true
                nameLabel.minimumScaleFactor = 0.5
            }

            if let subtitleLabel = cell.viewWithTag(3) as? UILabel {
                subtitleLabel.text = post.subtitle
            }

            if let timeLabel = cell.viewWithTag(4) as? UILabel {
                timeLabel.text = post.timestamp
            }

            if let messageLabel = cell.viewWithTag(5) as? UILabel {
                messageLabel.text = post.message
                messageLabel.numberOfLines = 0
            }

            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
            let post = eventPosts[indexPath.row]

            if let messageLabel = cell.viewWithTag(2) as? UILabel {
                messageLabel.text = post.message
            }

            if let timeLabel = cell.viewWithTag(3) as? UILabel {
                timeLabel.text = post.timestamp
            }

            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sementedControl.selectedSegmentIndex == 0 ? 160 : 150
    }
}
