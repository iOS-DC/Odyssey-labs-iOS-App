import UIKit

class CommunityViewController: UIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource,
                               UITextViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    // SHARE POPUP
    @IBOutlet weak var sharePopView: UIView!
    @IBOutlet weak var sharePopUpBottomConstraint: NSLayoutConstraint!

    // NEW POST POPUP
    @IBOutlet weak var newPostContainerView: UIView!
    @IBOutlet weak var newPostBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var newPostTextView: UITextView!
    @IBOutlet weak var characterCountLabel: UILabel!

    // COMMENT POPUP
    @IBOutlet weak var commentPopupView: UIView!
    @IBOutlet weak var commentPopupBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var commentTableView: UITableView!

    // MARK: - Variables
    var currentPostIndex: Int = 0
    var selectedPostIndex: Int?
    var selectedComments: [String] = []

    // MARK: - Models
    struct Post {
        let name: String
        let subtitle: String
        let message: String
        let timestamp: String

        var likeCount: Int
        var shareCount: Int
        var hasLiked: Bool = false
        var hasShared: Bool = false

        var comments: [String] = []
        var commentCount: Int { comments.count }
    }


    // MARK: - Data
    var feedPosts: [Post] = []
    var eventPosts: [EventItem] = []


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaultPost = Post(
            name: "Admin",
            subtitle: "Community Manager",
            message: "Welcome to the community! Feel free to share your thoughts 👋",
            timestamp: "1h ago",
            likeCount: 2,
            shareCount: 1,
            comments: [
                "This is really helpful 👍",
                "Glad to be here!"
            ]
        )
        eventPosts = EventDataModel.shared.eventList()


        feedPosts.append(defaultPost)
        tableView.reloadData()


        segmentedControl.selectedSegmentIndex = 0

        tableView.delegate = self
        tableView.dataSource = self

        commentTableView.delegate = self
        commentTableView.dataSource = self

        newPostTextView.delegate = self
        characterCountLabel.text = "0/280 characters"

        newPostContainerView.isHidden = true
        commentPopupView.isHidden = true
        sharePopView.isHidden = true

        newPostBottomConstraint.constant = 300
        commentPopupBottomConstraint.constant = 400
        sharePopUpBottomConstraint.constant = 400
    }

    // MARK: - NEW POST POPUP
    func showComposer() {
        hideCommentPopup()
        hideSharePopup()

        newPostContainerView.isHidden = false

        UIView.animate(withDuration: 0.3) {
            self.newPostBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }

        newPostTextView.becomeFirstResponder()
    }

    func hideComposer() {
        newPostTextView.resignFirstResponder()

        UIView.animate(withDuration: 0.3, animations: {
            self.newPostBottomConstraint.constant = 300
            self.view.layoutIfNeeded()
        }) { _ in
            self.newPostContainerView.isHidden = true
        }
    }

    // MARK: - SHARE POPUP
    func showSharePopup() {
        hideComposer()
        hideCommentPopup()

        sharePopView.isHidden = false
        sharePopView.alpha = 0
        sharePopUpBottomConstraint.constant = 0

        UIView.animate(withDuration: 0.30) {
            self.sharePopView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func segmentChanged(_ sender: Any) {
        tableView.reloadData()
    }
    func hideSharePopup() {
        sharePopUpBottomConstraint.constant = 400

        UIView.animate(withDuration: 0.30, animations: {
            self.sharePopView.alpha = 0
            self.view.layoutIfNeeded()
        }) { _ in
            self.sharePopView.isHidden = true
        }
    }

    // MARK: - COMMENT POPUP
    func showCommentPopup() {
        hideComposer()
        hideSharePopup()

        commentPopupView.isHidden = false
        commentPopupView.alpha = 0
        commentPopupBottomConstraint.constant = 0

        commentTableView.reloadData()

        UIView.animate(withDuration: 0.3) {
            self.commentPopupView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    func hideCommentPopup() {
        commentPopupBottomConstraint.constant = 400

        UIView.animate(withDuration: 0.3, animations: {
            self.commentPopupView.alpha = 0
            self.view.layoutIfNeeded()
        }) { _ in
            self.commentPopupView.isHidden = true
        }
    }

    // MARK: - BUTTON ACTIONS
    @IBAction func addNewPostButtonTapped(_ sender: Any) {
        showComposer()
    }

    @IBAction func closeNewPostTapped(_ sender: UIButton) {
        hideComposer()
    }

    @IBAction func postButtonTapped(_ sender: UIButton) {
        guard let typedText = newPostTextView.text,
              !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newPost = Post(name: "Rehan Khan",
                           subtitle: "3rd Year CSE",
                           message: typedText,
                           timestamp: "Just now",
                           likeCount: 0,
                           shareCount: 0)

        feedPosts.insert(newPost, at: 0)
        tableView.reloadData()

        newPostTextView.text = ""
        characterCountLabel.text = "0/280 characters"

        hideComposer()
    }

    // MARK: - COMMENTS
    @IBAction func commentButtonTapped(_ sender: UIButton) {
        guard let cell = getCell(from: sender),
              let index = tableView.indexPath(for: cell)?.row else { return }

        currentPostIndex = index
        selectedPostIndex = index
        selectedComments = feedPosts[index].comments

        commentTextField.text = ""
        commentTableView.reloadData()

        showCommentPopup()
    }

    @IBAction func postComment(_ sender: UIButton) {
        guard let text = commentTextField.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        selectedComments.append(text)

        if let index = selectedPostIndex {
            feedPosts[index].comments = selectedComments
        }

        commentTableView.reloadData()
        tableView.reloadRows(at: [IndexPath(row: currentPostIndex, section: 0)], with: .none)

        hideCommentPopup()
    }

    @IBAction func cancelComment(_ sender: Any) {
        print("cancel tapped")
        hideCommentPopup()
    }

    // MARK: - LIKE / SHARE
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        guard let cell = getCell(from: sender),
              let index = tableView.indexPath(for: cell)?.row else { return }

        if feedPosts[index].hasLiked { return }

        feedPosts[index].hasLiked = true
        feedPosts[index].likeCount += 1

        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }


    @IBAction func shareCancelButtonTapped(_ sender: Any) {
       hideSharePopup()
    }
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        showSharePopup()
    }
    @IBAction func EventShareButtonTapped(_ sender: Any) {
        showSharePopup()
    }
    
    @IBAction func shareEventTapped(_ sender: UIButton) {
        if let indexPath = getCellIndexPath(sender: sender) {
                currentPostIndex = indexPath.row   // ← IMPORTANT
            }

            showSharePopup()
    }

    
    @IBAction func shareOptionTapped(_ sender: UIButton) {
        hideSharePopup()

        switch sender.tag {
        case 1: print("WhatsApp tapped")
        case 2: print("Instagram tapped")
        case 3: print("Facebook tapped")
        case 4: print("More tapped")
        default: break
        }

        // Increase share count for whichever post is currently selected
        if segmentedControl.selectedSegmentIndex == 0 {
            feedPosts[currentPostIndex].shareCount += 1
        } else {
            eventPosts[currentPostIndex].shareCount += 1
        }

        tableView.reloadRows(at: [IndexPath(row: currentPostIndex, section: 0)], with: .none)
    }

    // MARK: - CHAR COUNT
    func textViewDidChange(_ textView: UITextView) {
        let maxCharacters = 280

        if textView.text.count > maxCharacters {
            textView.text = String(textView.text.prefix(maxCharacters))
        }

        characterCountLabel.text = "\(textView.text.count)/280 characters"
    }

    // MARK: - TABLEVIEW HELPERS
    func getCell(from sender: UIView) -> UITableViewCell? {
        var view: UIView? = sender
        while view != nil {
            if let cell = view as? UITableViewCell { return cell }
            view = view?.superview
        }
        return nil
    }

    @IBAction func attendEventButton(_ sender: Any) {
        guard let button = sender as? UIView else { return }
            guard let indexPath = getCellIndexPath(sender: button) else { return }

            let event = eventPosts[indexPath.row]
            openEventDetailsScreen(event: event)    }
    

    func openEventDetailsScreen(event: EventItem) {
        let storyboard = UIStoryboard(name: "Community", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "EventDetailsVC") as! EventDetailsViewController

            vc.event = event   // ← THIS passes the event to next screen

            navigationController?.pushViewController(vc, animated: true)
        }
    

    // MARK: - DATASOURCE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if tableView == commentTableView {
            return selectedComments.count
        }

        return segmentedControl.selectedSegmentIndex == 0
            ? feedPosts.count
            : eventPosts.count
    }
    func getCellIndexPath(sender: UIView) -> IndexPath? {
        let point = sender.convert(CGPoint.zero, to: tableView)
        return tableView.indexPathForRow(at: point)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // COMMENT LIST
        if tableView == commentTableView {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "commentCell")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = selectedComments[indexPath.row]
            return cell
        }

        // FEED LIST
        if segmentedControl.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)

            if let imgView = cell.viewWithTag(100) as? UIImageView {
                imgView.image = UIImage(named: "profile")
                imgView.layer.cornerRadius = 21
                imgView.clipsToBounds = true
            }

            let post = feedPosts[indexPath.row]

            (cell.viewWithTag(1) as? UILabel)?.text = post.name
            (cell.viewWithTag(2) as? UILabel)?.text = post.subtitle
            (cell.viewWithTag(3) as? UILabel)?.text = post.timestamp
            (cell.viewWithTag(4) as? UILabel)?.text = post.message

            (cell.viewWithTag(10) as? UIButton)?.setTitle("❤️ \(post.likeCount)", for: .normal)
            (cell.viewWithTag(11) as? UIButton)?.setTitle("💬 \(post.commentCount)", for: .normal)
            (cell.viewWithTag(12) as? UIButton)?.setTitle("↪️ \(post.shareCount)", for: .normal)

            let commentsLabel = cell.viewWithTag(20) as? UILabel
            commentsLabel?.text = post.comments.joined(separator: "\n")

            return cell
        }

        // EVENT LIST
        let event = eventPosts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)

        if let imgView = cell.viewWithTag(100) as? UIImageView {
            imgView.image = UIImage(named: event.imageName ?? "")
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true

            imgView.layer.cornerRadius = 21
            
        }
        

        // title
        (cell.viewWithTag(1) as? UILabel)?.text = event.title

        // date
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy 'at' HH:mm"
        (cell.viewWithTag(2) as? UILabel)?.text = df.string(from: event.startsAt)

        // location
        (cell.viewWithTag(3) as? UILabel)?.text = event.location?.name ?? "No Location"

        // attendees
        (cell.viewWithTag(4) as? UILabel)?.text = "Attending \(event.attendeeCount)"



        let shareButton = cell.viewWithTag(11) as! UIButton
        shareButton.setTitle("Share (\(event.shareCount))", for: .normal)

        return cell
    }
}
