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
    
    private var newPostBarButton: UIBarButtonItem?

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
        
        // Register Custom Cell
        commentTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        commentTableView.separatorStyle = .none
        commentTableView.rowHeight = UITableView.automaticDimension
        commentTableView.estimatedRowHeight = 80
        
        setupPopupUI()
        setupNewPostUI()
        setupShareUI()
        
        // Save reference to button
        newPostBarButton = navigationItem.rightBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Adjust bottom constraint to keyboard height
            // Check if NewPost is visible
            if !newPostContainerView.isHidden {
                self.newPostBottomConstraint.constant = keyboardSize.height - view.safeAreaInsets.bottom
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if !newPostContainerView.isHidden {
             self.newPostBottomConstraint.constant = 0
             UIView.animate(withDuration: 0.3) {
                 self.view.layoutIfNeeded()
             }
        }
    }
    
    func setupNewPostUI() {
        // New Post Popup Styling
        newPostContainerView.backgroundColor = .systemBackground
        newPostContainerView.layer.cornerRadius = 24
        newPostContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        newPostContainerView.layer.shadowColor = UIColor.black.cgColor
        newPostContainerView.layer.shadowOpacity = 0.15
        newPostContainerView.layer.shadowOffset = CGSize(width: 0, height: -4)
        newPostContainerView.layer.shadowRadius = 16
        
        // TextView Styling
        newPostTextView.layer.cornerRadius = 16
        newPostTextView.backgroundColor = .secondarySystemBackground
        newPostTextView.layer.borderWidth = 0
        newPostTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        newPostTextView.font = .systemFont(ofSize: 16, weight: .regular)
        newPostTextView.textColor = .label
        
        // Placeholder setup
        newPostTextView.text = "What's on your mind?"
        newPostTextView.textColor = .tertiaryLabel
        
        // Style the Post Button
        if let postBtn = newPostContainerView.viewWithTag(99) as? UIButton {
            postBtn.layer.cornerRadius = 16
            postBtn.backgroundColor = .systemBlue
            postBtn.setTitleColor(.white, for: .normal)
            postBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        }
        
        setupUserHeader()
    }
    
    func setupUserHeader() {
        // Hide "New Post" label if found
        for subview in newPostContainerView.subviews {
            if let label = subview as? UILabel, label.text == "New Post" {
                label.isHidden = true
            }
        }
        
        // Check if header already added
        if newPostContainerView.viewWithTag(1001) != nil { return }
        
        // Add Profile Info
        let avatarIV = UIImageView()
        avatarIV.translatesAutoresizingMaskIntoConstraints = false
        avatarIV.image = UIImage(named: "profile") ?? UIImage(systemName: "person.circle.fill")
        avatarIV.contentMode = .scaleAspectFill
        avatarIV.layer.cornerRadius = 20
        avatarIV.clipsToBounds = true
        avatarIV.tag = 1001
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Rehan Khan"
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        
        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "Post to Community"
        subLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subLabel.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [nameLabel, subLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        newPostContainerView.addSubview(avatarIV)
        newPostContainerView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            avatarIV.leadingAnchor.constraint(equalTo: newPostContainerView.leadingAnchor, constant: 16),
            avatarIV.topAnchor.constraint(equalTo: newPostContainerView.topAnchor, constant: 20),
            avatarIV.widthAnchor.constraint(equalToConstant: 40),
            avatarIV.heightAnchor.constraint(equalToConstant: 40),
            
            stack.leadingAnchor.constraint(equalTo: avatarIV.trailingAnchor, constant: 12),
            stack.centerYAnchor.constraint(equalTo: avatarIV.centerYAnchor)
        ])
    }
    
    func setupPopupUI() {
        // Comment Popup Styling
        commentPopupView.layer.cornerRadius = 24
        commentPopupView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        commentPopupView.layer.shadowColor = UIColor.black.cgColor
        commentPopupView.layer.shadowOpacity = 0.15
        commentPopupView.layer.shadowOffset = CGSize(width: 0, height: -4)
        commentPopupView.layer.shadowRadius = 16
        
        // TextField Styling
        commentTextField.layer.cornerRadius = 20
        commentTextField.layer.borderWidth = 1
        commentTextField.layer.borderColor = UIColor.systemGray5.cgColor
        commentTextField.clipsToBounds = true
        commentTextField.backgroundColor = .secondarySystemBackground
        commentTextField.borderStyle = .none
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 40))
        commentTextField.leftView = paddingView
        commentTextField.leftViewMode = .always
        commentTextField.rightView = paddingView
        commentTextField.rightViewMode = .always
    }

    func setupShareUI() {
        // Container
        sharePopView.backgroundColor = .systemBackground
        sharePopView.layer.cornerRadius = 24
        sharePopView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sharePopView.layer.shadowColor = UIColor.black.cgColor
        sharePopView.layer.shadowOpacity = 0.15
        sharePopView.layer.shadowOffset = CGSize(width: 0, height: -4)
        sharePopView.layer.shadowRadius = 16
        
        // Title (Tag 201)
        if let titleLabel = sharePopView.viewWithTag(201) as? UILabel {
            titleLabel.text = "Share Post"
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = .label
        }
        
        // Style Buttons (Tags 1, 2, 3, 4)
        let socialColors: [Int: UIColor] = [
            1: .systemGreen, // WhatsApp
            2: .systemPink,  // Instagram
            3: .systemBlue,  // Facebook
            4: .systemGray   // More
        ]
        
        for i in 1...4 {
            if let btn = sharePopView.viewWithTag(i) as? UIButton {
                btn.layer.cornerRadius = 12
                btn.backgroundColor = .secondarySystemBackground
                btn.tintColor = socialColors[i] ?? .label
                btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
                
                // Add icons programmatically if needed, or rely on text
                switch i {
                case 1: btn.setImage(UIImage(systemName: "message.fill"), for: .normal)
                case 2: btn.setImage(UIImage(systemName: "camera.fill"), for: .normal)
                case 3: btn.setImage(UIImage(systemName: "safari.fill"), for: .normal) // Facebook-ish
                case 4: btn.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
                default: break
                }
                
                // Padding for icon
                btn.configuration = .borderedTinted()
                btn.configuration?.imagePadding = 8
                btn.configuration?.baseBackgroundColor = socialColors[i]?.withAlphaComponent(0.1)
                btn.configuration?.baseForegroundColor = socialColors[i]
            }
        }
        
        // Cancel Button (Tag 202)
        if let cancelBtn = sharePopView.viewWithTag(202) as? UIButton {
            cancelBtn.layer.cornerRadius = 22 // Pill shape
            cancelBtn.backgroundColor = .systemGray5
            cancelBtn.setTitleColor(.label, for: .normal)
            cancelBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            // Remove defaultFilled if it conflicts
            cancelBtn.configuration = .plain()
            cancelBtn.setTitle("Cancel", for: .normal)
        }
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
        
        // Hide "New Post" button (plus) when in Events tab
        if segmentedControl.selectedSegmentIndex == 1 {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = newPostBarButton
        }
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
        guard let cell = getCell(from: sender),
              let index = tableView.indexPath(for: cell)?.row else { return }
        
        let post = feedPosts[index]
        let textToShare = "Check out this post from \(post.name): \(post.message)"
        
        showSystemShareSheet(items: [textToShare])
        
        // Track share count
        feedPosts[index].shareCount += 1
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    @IBAction func EventShareButtonTapped(_ sender: Any) {
        // This seems to be the one connected to EventCell
        guard let button = sender as? UIView,
              let indexPath = getCellIndexPath(sender: button) else { return }
        
        let event = eventPosts[indexPath.row]
        let textToShare = "Join me at \(event.title) on \(event.startsAt)! 🚗"
        
        showSystemShareSheet(items: [textToShare])
        
        // Track share count
        eventPosts[indexPath.row].shareCount += 1
        tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
    }
    
    @IBAction func shareEventTapped(_ sender: UIButton) {
        // Redundant action or legacy connection?
        // Forwarding to same logic if needed, or ignoring to avoid double presentation if both connected
        // Based on storyboard, FeedCell has this connected too.
        // If this is for FeedCell, shareButtonTapped handles it.
        // If this is for EventCell using a different button...
        // Safest is to do nothing if shareButtonTapped handles feed, and EventShareButtonTapped handles event.
        // But to be safe if this is the ONLY action for some button:
        
        if let indexPath = getCellIndexPath(sender: sender) {
            // Check if it's an event or feed?
            // Since we reused cells logic in datasource, let's just default to logic based on sender location
             // Actually, simplest is to defer to the specific handlers above which extract model cleanly.
        }
    }

    
    @IBAction func shareOptionTapped(_ sender: UIButton) {
        hideSharePopup()
        
        // Get the partial message or link to share
        let textToShare = "Check out this post on UniRide!"
        
        switch sender.tag {
        case 1: // WhatsApp
            let urlString = "whatsapp://send?text=\(textToShare.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback to share sheet
                    showSystemShareSheet(items: [textToShare])
                }
            }
            
        case 2: // Instagram
            // Instagram doesn't support simple text sharing via URL scheme easily, usually requires UIDocumentInteractionController for images.
            // For now, we'll try opening the app, or fallback to system share which handles it better.
            let urlString = "instagram://app"
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    showSystemShareSheet(items: [textToShare])
                }
            }
            
        case 3: // Facebook
            let urlString = "fb://"
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    showSystemShareSheet(items: [textToShare])
                }
            }
            
        case 4: // More
            showSystemShareSheet(items: [textToShare])
            
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
    
    func showSystemShareSheet(items: [Any]) {
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }

    // MARK: - CHAR COUNT & DELEGATE
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .tertiaryLabel {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What's on your mind?"
            textView.textColor = .tertiaryLabel
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        let maxCharacters = 280
        
        // Prevent typing if placeholder is active (though didBegin should handle it)
        if textView.textColor == .tertiaryLabel {
             return
        }

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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier, for: indexPath) as? CommentTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(text: selectedComments[indexPath.row])
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

        // Card Styling (Container Tag 900)
        if let cardView = cell.viewWithTag(900) {
            cardView.backgroundColor = .systemBackground
            cardView.layer.cornerRadius = 16
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.1
            cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
            cardView.layer.shadowRadius = 8
            cardView.clipsToBounds = false 
        }

        if let imgView = cell.viewWithTag(100) as? UIImageView {
            imgView.image = UIImage(named: event.imageName ?? "")
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true

            imgView.layer.cornerRadius = 21
            
        }
        

        // title
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = event.title
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
            titleLabel.textColor = .label
        }

        // date
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy 'at' HH:mm"
        if let dateLabel = cell.viewWithTag(2) as? UILabel {
            dateLabel.text = df.string(from: event.startsAt)
            dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
            dateLabel.textColor = .secondaryLabel
        }

        // location
        if let locLabel = cell.viewWithTag(3) as? UILabel {
            locLabel.text = event.location?.name ?? "No Location"
            locLabel.font = .systemFont(ofSize: 14, weight: .regular)
            locLabel.textColor = .secondaryLabel
        }

        // attendees
        (cell.viewWithTag(4) as? UILabel)?.text = "Attending \(event.attendeeCount)"



        // Buttons
        if let attendButton = cell.viewWithTag(10) as? UIButton {
            attendButton.setTitle("Attend", for: .normal)
            attendButton.layer.cornerRadius = 17.5
            attendButton.clipsToBounds = true
            attendButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            attendButton.setTitleColor(.systemBlue, for: .normal)
            attendButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        }

        let shareButton = cell.viewWithTag(11) as! UIButton
        shareButton.setTitle("Share (\(event.shareCount))", for: .normal)
        shareButton.layer.cornerRadius = 17.5
        shareButton.clipsToBounds = true
        shareButton.backgroundColor = .systemGray6
        shareButton.setTitleColor(.label, for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)

        return cell
    }
}

// MARK: - Custom Cells
class CommentTableViewCell: UITableViewCell {
    
    static let identifier = "CommentTableViewCell"
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.backgroundColor = .systemGray5
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemGray3
        return iv
    }()
    
    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let commentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.numberOfLines = 0
        l.textColor = .label
        return l
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
        bubbleView.addSubview(nameLabel)
        bubbleView.addSubview(commentLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -32),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            commentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            commentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            commentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            commentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(text: String) {
        let randomNames = ["Alex", "Jordan", "Taylor", "Casey", "Riley", "Jamie"]
        nameLabel.text = randomNames.randomElement()
        commentLabel.text = text
    }
}
