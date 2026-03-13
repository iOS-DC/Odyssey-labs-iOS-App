import UIKit

class CommunityViewController: UIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource,
                               UITextViewDelegate {
    private let sheetHiddenOffset: CGFloat = 400
    private let sheetShowDuration: TimeInterval = 0.34
    private let sheetHideDuration: TimeInterval = 0.24

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

        /// Remote Supabase ID — non-nil for posts fetched from or inserted into the backend.
        /// Used to target like / comment / share calls to the correct row.
        var remoteID: UUID?

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

        // BUG FIX: Load posts from Supabase on first appearance.
        // Falls back to the seeded defaultPost if network is unavailable.
        fetchPostsFromSupabase()


        segmentedControl.selectedSegmentIndex = 0

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false

        commentTableView.delegate = self
        commentTableView.dataSource = self

        newPostTextView.delegate = self
        characterCountLabel.text = "0/280 characters"

        newPostContainerView.isHidden = true
        commentPopupView.isHidden = true
        sharePopView.isHidden = true

        newPostBottomConstraint.constant = 300
        commentPopupBottomConstraint.constant = sheetHiddenOffset
        sharePopUpBottomConstraint.constant = sheetHiddenOffset
        
        // Register Custom Cells
        commentTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        tableView.register(EventCardCell.self, forCellReuseIdentifier: EventCardCell.reuseID)
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
        // Refresh events from Supabase so the Events tab shows real data
        Task {
            if let remote = try? await EventsAPI.shared.fetchTopEvents(limit: 30), !remote.isEmpty {
                await MainActor.run {
                    self.eventPosts = remote
                    if self.segmentedControl.selectedSegmentIndex == 1 {
                        self.tableView.reloadData()
                    }
                }
            }
        }
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
        newPostContainerView.layer.cornerRadius = AppDesign.Radius.lg
        newPostContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        newPostContainerView.layer.shadowColor = UIColor.black.cgColor
        newPostContainerView.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        newPostContainerView.layer.shadowOffset = CGSize(width: 0, height: -AppDesign.Spacing.xs)
        newPostContainerView.layer.shadowRadius = AppDesign.Shadow.cardRadius
        
        // TextView Styling
        newPostTextView.layer.cornerRadius = AppDesign.Radius.md
        newPostTextView.backgroundColor = .secondarySystemBackground
        newPostTextView.layer.borderWidth = 0
        newPostTextView.textContainerInset = UIEdgeInsets(top: AppDesign.Spacing.md, left: AppDesign.Spacing.md, bottom: AppDesign.Spacing.md, right: AppDesign.Spacing.md)
        newPostTextView.font = AppDesign.Typography.body
        newPostTextView.textColor = .label
        
        // Placeholder setup
        newPostTextView.text = "What's on your mind?"
        newPostTextView.textColor = .tertiaryLabel
        
        // Style the Post Button
        if let postBtn = newPostContainerView.viewWithTag(99) as? UIButton {
            let title = postBtn.currentTitle ?? "Post"
            postBtn.applyProminentPrimaryCTA(title: title, corner: AppDesign.Radius.md)
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
        avatarIV.contentMode = .scaleAspectFill
        avatarIV.layer.cornerRadius = AppDesign.Radius.lg
        avatarIV.clipsToBounds = true
        avatarIV.tag = 1001

        // Load the current user's avatar and name (non-blocking)
        let currentUser = UserDataModel.shared.getCurrentUser()
        let displayName = currentUser?.fullName.isEmpty == false ? currentUser!.fullName : "You"
        avatarIV.loadAndFallback(from: currentUser?.photoURL, name: displayName)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = displayName
        nameLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        
        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "Post to Community"
        subLabel.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
        
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
        commentPopupView.layer.cornerRadius = AppDesign.Radius.lg
        commentPopupView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        commentPopupView.layer.shadowColor = UIColor.black.cgColor
        commentPopupView.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        commentPopupView.layer.shadowOffset = CGSize(width: 0, height: -AppDesign.Spacing.xs)
        commentPopupView.layer.shadowRadius = AppDesign.Shadow.cardRadius

        // TextField Styling
        commentTextField.applyRoundedField()
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
        sharePopView.layer.cornerRadius = AppDesign.Radius.lg
        sharePopView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sharePopView.layer.shadowColor = UIColor.black.cgColor
        sharePopView.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        sharePopView.layer.shadowOffset = CGSize(width: 0, height: -AppDesign.Spacing.xs)
        sharePopView.layer.shadowRadius = AppDesign.Shadow.cardRadius
        
        // Title (Tag 201)
        if let titleLabel = sharePopView.viewWithTag(201) as? UILabel {
            titleLabel.text = "Share Post"
            titleLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        }
        
        // Style Buttons (Tags 1, 2, 3, 4)
        let socialColors: [Int: UIColor] = [
            1: AppDesign.Color.success, // WhatsApp
            2: AppDesign.Color.primary, // Instagram
            3: AppDesign.Color.primary, // Facebook
            4: AppDesign.Color.textPrimary.withAlphaComponent(0.7) // More
        ]
        
        for i in 1...4 {
            if let btn = sharePopView.viewWithTag(i) as? UIButton {
                btn.layer.cornerRadius = AppDesign.Radius.sm
                btn.backgroundColor = .secondarySystemBackground
                btn.tintColor = socialColors[i] ?? .label
                btn.titleLabel?.font = AppDesign.Typography.subheadline
                
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
            cancelBtn.layer.cornerRadius = AppDesign.Radius.md
            cancelBtn.backgroundColor = AppDesign.Color.fieldBackground
            cancelBtn.setTitleColor(.label, for: .normal)
            cancelBtn.titleLabel?.font = AppDesign.Typography.button
            // Remove defaultFilled if it conflicts
            cancelBtn.configuration = .plain()
            cancelBtn.setTitle("Cancel", for: .normal)
        }
    }

    // MARK: - NEW POST POPUP
    func showComposer() {
        AppHaptics.impact(.light)
        hideCommentPopup()
        hideSharePopup()

        newPostContainerView.isHidden = false
        newPostContainerView.alpha = 0
        newPostContainerView.transform = CGAffineTransform(translationX: 0, y: 16)
        newPostBottomConstraint.constant = 0
        animateSheetShow(newPostContainerView)

        newPostTextView.becomeFirstResponder()
    }

    func hideComposer() {
        newPostTextView.resignFirstResponder()
        newPostBottomConstraint.constant = 300
        animateSheetHide(newPostContainerView) { [weak self] in
            guard let self else { return }
            self.newPostContainerView.isHidden = true
        }
    }

    // MARK: - SHARE POPUP
    func showSharePopup() {
        AppHaptics.impact(.light)
        hideComposer()
        hideCommentPopup()

        sharePopView.isHidden = false
        sharePopView.alpha = 0
        sharePopView.transform = CGAffineTransform(translationX: 0, y: 16)
        sharePopUpBottomConstraint.constant = 0
        animateSheetShow(sharePopView)
    }

    @IBAction func segmentChanged(_ sender: Any) {
        AppHaptics.selection()
        tableView.reloadData()
        
        // Hide "New Post" button (plus) when in Events tab
        if segmentedControl.selectedSegmentIndex == 1 {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = newPostBarButton
        }
    }
    func hideSharePopup() {
        sharePopUpBottomConstraint.constant = sheetHiddenOffset
        animateSheetHide(sharePopView) { [weak self] in
            guard let self else { return }
            self.sharePopView.isHidden = true
        }
    }

    // MARK: - COMMENT POPUP
    func showCommentPopup() {
        AppHaptics.impact(.light)
        hideComposer()
        hideSharePopup()

        commentPopupView.isHidden = false
        commentPopupView.alpha = 0
        commentPopupView.transform = CGAffineTransform(translationX: 0, y: 16)
        commentPopupBottomConstraint.constant = 0

        commentTableView.reloadData()
        animateSheetShow(commentPopupView)
    }

    func hideCommentPopup() {
        commentPopupBottomConstraint.constant = sheetHiddenOffset
        animateSheetHide(commentPopupView) { [weak self] in
            guard let self else { return }
            self.commentPopupView.isHidden = true
        }
    }

    private func animateSheetShow(_ sheet: UIView) {
        if UIAccessibility.isReduceMotionEnabled {
            sheet.alpha = 1
            sheet.transform = .identity
            view.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: sheetShowDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.25,
                       options: [.curveEaseOut, .allowUserInteraction]) {
            sheet.alpha = 1
            sheet.transform = .identity
            self.view.layoutIfNeeded()
        }
    }

    private func animateSheetHide(_ sheet: UIView, completion: (() -> Void)? = nil) {
        if UIAccessibility.isReduceMotionEnabled {
            sheet.alpha = 0
            view.layoutIfNeeded()
            completion?()
            return
        }
        UIView.animate(withDuration: sheetHideDuration, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
            sheet.alpha = 0
            sheet.transform = CGAffineTransform(translationX: 0, y: 12)
            self.view.layoutIfNeeded()
        } completion: { _ in
            sheet.transform = .identity
            completion?()
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

        let user    = UserDataModel.shared.getCurrentUser()
        let name    = user?.fullName.isEmpty == false ? user!.fullName : "You"
        let role    = user?.role == .faculty ? "Faculty" :
                      (user?.courseName.flatMap { c in user?.year.map { y in "\(c) · Year \(y)" } } ?? "Student")

        let newPost = Post(name: name,
                           subtitle: role,
                           message: typedText,
                           timestamp: "Just now",
                           likeCount: 0,
                           shareCount: 0)

        feedPosts.insert(newPost, at: 0)
        tableView.reloadData()

        // BUG FIX: Persist the new post to Supabase community_posts table.
        Task {
            try? await CommunityRepository.shared.insertPost(text: typedText)
        }

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
            // Persist comment to Supabase community_comments table
            if let postID = feedPosts[index].remoteID {
                Task { try? await CommunityRepository.shared.insertComment(postID: postID, text: text) }
            }
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

        // Persist like to Supabase (requires a remote post ID)
        if let postID = feedPosts[index].remoteID {
            Task { try? await CommunityRepository.shared.toggleLike(postID: postID) }
        }
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
        if segmentedControl.selectedSegmentIndex == 1 {
            EventShareButtonTapped(sender)
        } else {
            shareButtonTapped(sender)
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

    // MARK: - Supabase integration

    /// Fetches posts from the community_posts Supabase table and prepends them to feedPosts.
    /// The local seed/default posts are kept as a fallback if the network is unavailable.
    private func fetchPostsFromSupabase() {
        Task {
            guard let remotePosts = try? await CommunityRepository.shared.fetchPosts() else { return }
            let mapped: [Post] = remotePosts.map { rp in
                // Resolve author name from local profile cache, fall back to "Community Member"
                let author = UserDataModel.shared.getUser(by: rp.authorUserID)
                let authorName = author?.fullName.isEmpty == false ? author!.fullName : "Community Member"
                let role: String
                if let r = author?.role { role = r == .faculty ? "Faculty" : "Student" }
                else { role = "Community Member" }

                let df = RelativeDateTimeFormatter()
                df.unitsStyle = .short
                let when = df.localizedString(for: rp.createdAt, relativeTo: Date())
                return Post(
                    name: authorName,
                    subtitle: role,
                    message: rp.text,
                    timestamp: when,
                    remoteID: rp.id,        // ← store remote ID so likes/comments can target the right row
                    likeCount: rp.likeCount,
                    shareCount: rp.shareCount
                )
            }
            guard !mapped.isEmpty else { return }
            await MainActor.run {
                // Replace local seed posts with remote data
                self.feedPosts = mapped
                self.tableView.reloadData()
            }
        }
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
            let post = feedPosts[indexPath.row]

            if let feedCard = cell.contentView.subviews.first {
                feedCard.applyCardStyle(
                    corner: AppDesign.Radius.lg,
                    shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                    shadowRadius: AppDesign.Shadow.smallCardRadius,
                    shadowOffset: AppDesign.Shadow.smallCardOffset
                )
            }

            if let imgView = cell.viewWithTag(100) as? UIImageView {
                imgView.layer.cornerRadius = AppDesign.Radius.lg
                imgView.clipsToBounds = true
                // Use initials-based avatar for the post author
                imgView.image = UIImage.generatedAvatar(for: post.name, size: CGSize(width: 40, height: 40))
            }

            if let label = cell.viewWithTag(1) as? UILabel {
                label.text = post.name
                label.applyTextStyle(AppDesign.Typography.bodyStrong)
            }
            if let label = cell.viewWithTag(2) as? UILabel {
                label.text = post.subtitle
                label.applyTextStyle(AppDesign.Typography.caption, color: .secondaryLabel)
            }
            if let label = cell.viewWithTag(3) as? UILabel {
                label.text = post.timestamp
                label.applyTextStyle(AppDesign.Typography.body, color: .secondaryLabel)
            }
            if let label = cell.viewWithTag(4) as? UILabel {
                label.text = post.message
                label.applyTextStyle(AppDesign.Typography.body, lines: 2)
            }

            if let likeButton = cell.viewWithTag(10) as? UIButton {
                likeButton.setTitle("❤️ \(post.likeCount)", for: .normal)
                likeButton.titleLabel?.font = AppDesign.Typography.subheadline
            }
            if let commentButton = cell.viewWithTag(11) as? UIButton {
                commentButton.setTitle("💬 \(post.commentCount)", for: .normal)
                commentButton.titleLabel?.font = AppDesign.Typography.subheadline
            }
            if let shareButton = cell.viewWithTag(12) as? UIButton {
                shareButton.setTitle("↪️ \(post.shareCount)", for: .normal)
                shareButton.titleLabel?.font = AppDesign.Typography.subheadline
            }

            let commentsLabel = cell.viewWithTag(20) as? UILabel
            commentsLabel?.text = post.comments.joined(separator: "\n")

            // Verified badge — injected programmatically next to the name label (tag 1)
            let badgeTag = 9001
            cell.viewWithTag(badgeTag)?.removeFromSuperview()
            if let nameLabel = cell.viewWithTag(1) as? UILabel {
                // Look up whether this post's author is verified
                let authorIDForPost: UUID? = post.remoteID.flatMap { pid in
                    feedPosts.first(where: { $0.remoteID == pid }).flatMap { _ in nil }
                }
                // Simplified: check if the locally-known user matching this post's name is verified
                let isVerifiedAuthor = UserDataModel.shared.allUsers()
                    .first(where: { $0.fullName == post.name })?.isEmailVerified == true
                if isVerifiedAuthor {
                    let badge = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
                    badge.tag = badgeTag
                    badge.tintColor = AppDesign.Color.primary
                    badge.translatesAutoresizingMaskIntoConstraints = false
                    badge.widthAnchor.constraint(equalToConstant: 13).isActive = true
                    badge.heightAnchor.constraint(equalToConstant: 13).isActive = true
                    if let parent = nameLabel.superview {
                        parent.addSubview(badge)
                        NSLayoutConstraint.activate([
                            badge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
                            badge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
                        ])
                    }
                }
            }

            return cell
        }

        // EVENT LIST — use the fully programmatic EventCardCell
        let event = eventPosts[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EventCardCell.reuseID, for: indexPath) as? EventCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: event, primaryColor: AppDesign.Color.primary)
        cell.delegate = self
        return cell
    }


    // MARK: - didSelectRowAt (feed posts → PostDetailVC)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard tableView != commentTableView,
              segmentedControl.selectedSegmentIndex == 0,
              indexPath.row < feedPosts.count else { return }

        let localPost = feedPosts[indexPath.row]
        guard let remoteID = localPost.remoteID else { return }

        // Map local Post → CommunityPost for PostDetailVC
        let communityPost = CommunityPost(
            id: remoteID,
            authorUserID: UserDataModel.shared.allUsers()
                .first(where: { $0.fullName == localPost.name })?.id ?? UUID(),
            text: localPost.message,
            imageURL: nil,
            likeCount: localPost.likeCount,
            shareCount: localPost.shareCount,
            commentCount: localPost.commentCount,
            createdAt: Date()
        )
        let vc = PostDetailViewController()
        vc.post = communityPost
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView != commentTableView else { return UITableView.automaticDimension }
        // Event cards have a fixed hero height + metadata — estimate generously
        if segmentedControl.selectedSegmentIndex == 1 { return UITableView.automaticDimension }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView != commentTableView else { return 80 }
        return segmentedControl.selectedSegmentIndex == 1 ? 270 : 160
    }
}

// MARK: - EventCardCellDelegate
extension CommunityViewController: EventCardCellDelegate {
    func eventCardCellDidTapAttend(_ cell: EventCardCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              indexPath.row < eventPosts.count else { return }
        openEventDetailsScreen(event: eventPosts[indexPath.row])
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
        iv.layer.cornerRadius = AppDesign.Radius.md
        iv.backgroundColor = AppDesign.Color.fieldBackground
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = AppDesign.Color.border
        return iv
    }()
    
    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppDesign.Color.fieldBackground
        v.layer.cornerRadius = AppDesign.Radius.sm
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
