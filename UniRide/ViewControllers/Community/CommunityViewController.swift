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
    var selectedComments: [String] = []          // legacy — kept for comment popup submit
    
    /// Real comments fetched from Supabase for the currently-open popup.
    private var liveCommunityComments: [CommunityComment] = []
    /// Author names keyed by UUID, fetched from Supabase profiles.
    private var liveCommentAuthorNames: [UUID: String] = [:]
    
    private var newPostBarButton: UIBarButtonItem?
    /// Polls Supabase every 30 s so likes/comments from other users appear automatically.
    private var refreshTimer: Timer?
    private let refreshControl = UIRefreshControl()
    /// Tracks posts currently being liked/unliked to prevent auto-refresh flickers
    private var pendingLikeOperations: Set<UUID> = []

    // MARK: - Models
    struct Post {
        var name: String
        let subtitle: String
        let message: String
        let timestamp: String

        var remoteID: UUID?
        var authorUserID: UUID?
        var authorProfile: UserProfile?
        var imageURL: URL?

        var likeCount: Int {
            get { PostRegistry.shared.getLikeCount(for: remoteID) ?? _likeCount }
            set { _likeCount = newValue }
        }
        internal var _likeCount: Int

        var shareCount: Int {
            get { PostRegistry.shared.getShareCount(for: remoteID) ?? _shareCount }
            set { _shareCount = newValue }
        }
        internal var _shareCount: Int

        var commentCount: Int {
            get { PostRegistry.shared.getCommentCount(for: remoteID) ?? _commentCount }
            set { _commentCount = newValue }
        }
        internal var _commentCount: Int

        var hasLiked: Bool = false
        var hasShared: Bool = false
        
        init(name: String, subtitle: String, message: String, timestamp: String, remoteID: UUID? = nil, authorUserID: UUID? = nil, authorProfile: UserProfile? = nil, imageURL: URL? = nil, likeCount: Int = 0, shareCount: Int = 0, commentCount: Int = 0, hasLiked: Bool = false, hasShared: Bool = false) {
            self.name = name
            self.subtitle = subtitle
            self.message = message
            self.timestamp = timestamp
            self.remoteID = remoteID
            self.authorUserID = authorUserID
            self.authorProfile = authorProfile
            self.imageURL = imageURL
            self._likeCount = likeCount
            self._shareCount = shareCount
            self._commentCount = commentCount
            self.hasLiked = hasLiked
            self.hasShared = hasShared
        }
    }


    // MARK: - Data
    var feedPosts: [Post] = []
    var eventPosts: [EventItem] = []


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Feed is now entirely driven by Supabase. 
        // fetchPostsFromSupabase() is called below.
        tableView.reloadData()

        // BUG FIX: Load posts from Supabase on first appearance.
        // Falls back to the seeded defaultPost if network is unavailable.
        fetchPostsFromSupabase()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalCommentUpdate(_:)),
            name: .CommunityCommentDidUpdate,
            object: nil
        )

        segmentedControl.setTitle("Events", forSegmentAt: 0)
        segmentedControl.setTitle("Feed", forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = 0

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false
        
        // Setup Pull-to-Refresh
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControl.tintColor = AppDesign.Color.primary
        tableView.refreshControl = refreshControl

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
        
        // Save reference to button
        newPostBarButton = navigationItem.rightBarButtonItem
        
        // Initial visibility check for the plus button
        segmentChanged(segmentedControl)
        
        setupPopupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Mock events as requested for better visual demonstration
        self.eventPosts = EventDataModel.mockEvents()
        
        // Start polling so other users' likes / comments appear automatically
        startFeedRefreshTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopFeedRefreshTimer()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        let animationCurve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        
        // Robust approach: Let Auto Layout handle the top limit via constraints added in setupPopupConstraints.
        // We simply tell the view to move up by the keyboard height.
        let targetConstant = -(keyboardHeight - safeAreaBottom)

        if !newPostContainerView.isHidden {
            self.newPostBottomConstraint.constant = targetConstant
        }
        if !commentPopupView.isHidden {
            self.commentPopupBottomConstraint.constant = targetConstant
        }

        UIView.animate(withDuration: duration, delay: 0, options: [animationCurve, .beginFromCurrentState]) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let animationCurve = UIView.AnimationOptions(rawValue: curveRaw << 16)

        if !newPostContainerView.isHidden {
            self.newPostBottomConstraint.constant = 0
        }
        if !commentPopupView.isHidden {
            self.commentPopupBottomConstraint.constant = 0
        }

        UIView.animate(withDuration: duration, delay: 0, options: [animationCurve, .beginFromCurrentState]) {
            self.view.layoutIfNeeded()
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


    private func setupPopupConstraints() {
        // Add a "Top Cap" constraint to prevent popups from sliding under/over the navigation tabs.
        // This constraint ensures the top of the popup stays at least 140 points from the safe area top.
        newPostContainerView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 140).isActive = true
        commentPopupView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 140).isActive = true
    }

    // MARK: - NEW POST POPUP
    func showComposer() {
        AppHaptics.impact(.light)
        hideCommentPopup()

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


    @IBAction func segmentChanged(_ sender: Any) {
        AppHaptics.selection()
        
        // Ensure all popups are dismissed when switching tabs
        hideComposer()
        hideCommentPopup()
        
        tableView.reloadData()
        
        // Hide "New Post" button (plus) when in Events tab (index 0)
        if segmentedControl.selectedSegmentIndex == 0 {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = newPostBarButton
        }
    }

    // MARK: - COMMENT POPUP
    func showCommentPopup() {
        AppHaptics.impact(.light)
        hideComposer()

        commentPopupView.isHidden = false
        commentPopupView.alpha = 0
        commentPopupView.transform = CGAffineTransform(translationX: 0, y: 16)
        commentPopupBottomConstraint.constant = 0

        commentTableView.reloadData()
        animateSheetShow(commentPopupView)
    }

    func hideCommentPopup() {
        view.endEditing(true)
        commentPopupBottomConstraint.constant = sheetHiddenOffset
        animateSheetHide(commentPopupView) { [weak self] in
            guard let self = self else { return }
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

        var newPost = Post(name: name,
                           subtitle: role,
                           message: typedText,
                           timestamp: "Just now",
                           likeCount: 0,
                           shareCount: 0)
        newPost.authorProfile = user // Ensure profile pic shows immediately
        newPost.authorUserID = user?.id

        feedPosts.insert(newPost, at: 0)
        tableView.reloadData()

        // BUG FIX: Persist the new post to Supabase and sync the remoteID immediately
        Task {
            if let newID = try? await CommunityRepository.shared.insertPost(text: typedText) {
                await MainActor.run {
                    // Update the local post with its real Supabase ID
                    // Since it was just inserted at 0, it should be there.
                    if self.feedPosts.count > 0 {
                        self.feedPosts[0].remoteID = newID
                    }
                }
            }
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

        // Clear stale data and show popup immediately
        liveCommunityComments = []
        liveCommentAuthorNames = [:]
        commentTextField.text = ""
        commentTableView.reloadData()
        showCommentPopup()

        // Fetch real comments from Supabase in background
        guard let postID = feedPosts[index].remoteID else { return }
        Task {
            await loadLiveComments(for: postID)
        }
    }

    /// Fetches all comments for a post from Supabase and resolves author names.
    private func loadLiveComments(for postID: UUID) async {
        guard let comments = try? await CommunityRepository.shared.fetchComments(postID: postID) else { return }

        await MainActor.run {
            self.liveCommunityComments = comments
            self.commentTableView.reloadData()
        }
    }

    @IBAction func postComment(_ sender: UIButton) {
        guard let text = commentTextField.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        commentTextField.text = ""

        guard let index = selectedPostIndex, let postID = feedPosts[index].remoteID else { return }

        Task {
            // 1. Write to Supabase and get the new definitive total count
            if let newCount = try? await CommunityRepository.shared.insertComment(postID: postID, text: text) {
                await MainActor.run {
                    self.view.endEditing(true)
                    // Update locally + Notify globally
                    NotificationCenter.default.post(
                        name: .CommunityCommentDidUpdate,
                        object: nil,
                        userInfo: ["postID": postID, "newCount": newCount]
                    )
                }
            }

            // 2. Reload live comments in the popup with real names
            await loadLiveComments(for: postID)
        }
    }

    @IBAction func cancelComment(_ sender: Any) {
        print("cancel tapped")
        hideCommentPopup()
    }

    // MARK: - LIKE / SHARE
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        guard let cell = getCell(from: sender),
              let index = tableView.indexPath(for: cell)?.row else { return }

        // Optimistic local toggle so the button feels instant
        let currentlyLiked = feedPosts[index].hasLiked
        feedPosts[index].hasLiked = !currentlyLiked
        feedPosts[index].likeCount += (currentlyLiked ? -1 : 1)
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)

        guard let postID = feedPosts[index].remoteID else { return }
        
        // Track as pending so auto-refresh doesn't overwrite our optimistic state
        pendingLikeOperations.insert(postID)
        
        Task {
            defer {
                Task { @MainActor in
                    self.pendingLikeOperations.remove(postID)
                }
            }
            
            // Write to Supabase and get the final truth (isLiked, newTotalCount)
            if let result = try? await CommunityRepository.shared.toggleLike(postID: postID) {
                await MainActor.run {
                    if let i = self.feedPosts.firstIndex(where: { $0.remoteID == postID }) {
                        // Sync with backend truth
                        self.feedPosts[i].hasLiked = result.isLiked
                        self.feedPosts[i].likeCount = result.count
                        self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                    }
                }
            }
        }
    }

    @IBAction func shareCancelButtonTapped(_ sender: Any) {
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let cell = getCell(from: sender),
              let index = tableView.indexPath(for: cell)?.row else { return }
        
        let post = feedPosts[index]
        openNativeShareSheet(for: post)
    }
    
    @IBAction func EventShareButtonTapped(_ sender: Any) {
        // This seems to be the one connected to EventCell
        guard let button = sender as? UIView,
              let indexPath = getCellIndexPath(sender: button) else { return }
        
        let event = eventPosts[indexPath.row]
        openNativeShareSheet(forEvent: event)
    }
    
    @IBAction func shareEventTapped(_ sender: UIButton) {
        if segmentedControl.selectedSegmentIndex == 0 {
            EventShareButtonTapped(sender)
        } else {
            shareButtonTapped(sender)
        }
    }

    
    @IBAction func shareOptionTapped(_ sender: UIButton) {
        
        // Get the partial message or link to share
        let textToShare: String
        if segmentedControl.selectedSegmentIndex == 1 {
            let post = feedPosts[currentPostIndex]
            textToShare = "Check out this post from \(post.name) on UniRide!"
        } else {
            let event = eventPosts[currentPostIndex]
            textToShare = "Join me at \(event.title) on UniRide! 🚗"
        }
        
        switch sender.tag {
        case 1: // WhatsApp
            let urlString = "whatsapp://send?text=\(textToShare.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    showSystemShareSheet(items: [textToShare])
                }
            }
        case 2: // Instagram
            showSystemShareSheet(items: [textToShare])
        case 3: // Facebook
            showSystemShareSheet(items: [textToShare])
        case 4: // More
            showSystemShareSheet(items: [textToShare])
        default: break
        }

        // Backend Sync
        Task {
            if segmentedControl.selectedSegmentIndex == 1 {
                let post = feedPosts[currentPostIndex]
                guard let postID = post.remoteID else { return }
                
                if let newCount = try? await CommunityRepository.shared.recordShare(postID: postID) {
                    await MainActor.run {
                        self.feedPosts[self.currentPostIndex].shareCount = newCount
                        self.tableView.reloadRows(at: [IndexPath(row: self.currentPostIndex, section: 0)], with: .none)
                    }
                }
            } else {
                let event = eventPosts[currentPostIndex]
                let eventID = event.id
                
                if let newCount = try? await EventsAPI.shared.incrementShareCount(eventID: eventID, currentCount: event.shareCount) {
                    await MainActor.run {
                        self.eventPosts[self.currentPostIndex].shareCount = newCount
                        self.tableView.reloadRows(at: [IndexPath(row: self.currentPostIndex, section: 0)], with: .none)
                    }
                }
            }
        }
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

    // MARK: - Feed auto-refresh
    private func startFeedRefreshTimer() {
        // Fire immediately then every 5 seconds
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, self.segmentedControl.selectedSegmentIndex == 1 else { return }
            self.fetchPostsFromSupabase()
        }
    }

    private func stopFeedRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    @objc private func handleRefresh() {
        // Show spinner if not already refreshing (e.g. if button was tapped)
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
            // Pull the table down slightly to show the spinner
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.size.height), animated: true)
        }

        if segmentedControl.selectedSegmentIndex == 1 {
            fetchPostsFromSupabase()
        } else {
            // Re-trigger event fetch (same logic as viewWillAppear)
            Task {
                if let remote = try? await EventsAPI.shared.fetchTopEvents(limit: 30), !remote.isEmpty {
                    await MainActor.run {
                        self.eventPosts = remote
                        self.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    await MainActor.run { self.refreshControl.endRefreshing() }
                }
            }
        }
    }

    // MARK: - Supabase integration

    /// Fetches posts from the community_posts Supabase table and prepends them to feedPosts.
    /// The local seed/default posts are kept as a fallback if the network is unavailable.
    private func fetchPostsFromSupabase() {
        Task {
            guard let remotePosts = try? await CommunityRepository.shared.fetchPosts() else { 
                await MainActor.run { self.refreshControl.endRefreshing() }
                return 
            }

            // Build initial posts with placeholder names and real counts
            var mapped: [Post] = remotePosts.map { rp in
                let df = RelativeDateTimeFormatter()
                df.unitsStyle = .short
                var when = df.localizedString(for: rp.createdAt, relativeTo: Date())
                // Handle future dates (clock sync issues) and very recent posts
                if when.contains("in ") || when.contains("0 sec") {
                    when = "Just now"
                }
                let isMe = rp.authorUserID == UserDataModel.shared.getCurrentUser()?.id
                let effectiveProfile = isMe ? UserDataModel.shared.getCurrentUser() : rp.authorProfile
                
                return Post(
                    name: effectiveProfile?.fullName ?? "UniRide User",
                    subtitle: (effectiveProfile?.role == .faculty ? "Faculty" : "Student"),
                    message: rp.text,
                    timestamp: when,
                    remoteID: rp.id,
                    authorUserID: rp.authorUserID,
                    authorProfile: effectiveProfile,
                    imageURL: rp.imageURL,
                    likeCount: rp._likeCount,
                    shareCount: rp._shareCount,
                    commentCount: rp._commentCount
                )
            }
            guard !mapped.isEmpty else { return }

            // Merge local session state (likes, counts) into the freshly fetched posts 
            // so we don't flicker or lose optimistic updates.
            await MainActor.run {
                for i in mapped.indices {
                    guard let remoteID = mapped[i].remoteID else { continue }
                    
                    if let existing = self.feedPosts.first(where: { $0.remoteID == remoteID }) {
                        // Preserve hasLiked/hasShared if already true in current session.
                        if existing.hasLiked  { mapped[i].hasLiked = true }
                        if existing.hasShared { mapped[i].hasShared = true }

                        // Take the higher count (server vs local) to avoid flickering
                        // if the server hasn't finished its internal trigger updates.
                        mapped[i]._likeCount    = max(mapped[i]._likeCount, existing._likeCount)
                        mapped[i]._shareCount   = max(mapped[i]._shareCount, existing._shareCount)
                        mapped[i]._commentCount = max(mapped[i]._commentCount, existing._commentCount)
                        
                        // If we are currently in middle of an optimistic like operation,
                        // definitely keep the local state.
                        if self.pendingLikeOperations.contains(remoteID) {
                            mapped[i].hasLiked  = existing.hasLiked
                            mapped[i].likeCount = existing.likeCount
                        }
                    }
                }
                
                self.feedPosts = mapped
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }


    @objc private func handleGlobalCommentUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let postID = userInfo["postID"] as? UUID,
              let newCount = userInfo["newCount"] as? Int else { return }

        DispatchQueue.main.async {
            if let index = self.feedPosts.firstIndex(where: { $0.remoteID == postID }) {
                self.feedPosts[index].commentCount = newCount
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
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
            return liveCommunityComments.count
        }

        return segmentedControl.selectedSegmentIndex == 1
            ? feedPosts.count
            : eventPosts.count
    }
    func getCellIndexPath(sender: UIView) -> IndexPath? {
        let point = sender.convert(CGPoint.zero, to: tableView)
        return tableView.indexPathForRow(at: point)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // COMMENT LIST — real comments from Supabase
        if tableView == commentTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier, for: indexPath) as? CommentTableViewCell else {
                return UITableViewCell()
            }
            let comment = liveCommunityComments[indexPath.row]
            cell.configure(with: comment)
            return cell
        }

        // FEED LIST
        if segmentedControl.selectedSegmentIndex == 1 {
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

            // Avatar: hide the storyboard placeholder and use a programmatic imageview
            // so we always know the bounds (40×40) when calling loadAndFallback.
            if let storyboardAvatar = cell.viewWithTag(100) as? UIImageView {
                storyboardAvatar.isHidden = true
            }

            let avatarTag = 201
            let avatarSize: CGFloat = 40
            let avatarIV: UIImageView
            if let existing = cell.contentView.viewWithTag(avatarTag) as? UIImageView {
                avatarIV = existing
            } else {
                let iv = UIImageView()
                iv.tag = avatarTag
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                iv.layer.cornerRadius = avatarSize / 2
                iv.backgroundColor = AppDesign.Color.fieldBackground
                iv.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(iv)
                // Position it where the storyboard avatar sits (leading 16, top 12)
                NSLayoutConstraint.activate([
                    iv.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    iv.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                    iv.widthAnchor.constraint(equalToConstant: avatarSize),
                    iv.heightAnchor.constraint(equalToConstant: avatarSize)
                ])
                avatarIV = iv
            }
            avatarIV.loadAndFallback(from: post.authorProfile?.photoURL, name: post.name.isEmpty ? "?" : post.name)

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
            // Verified badge logic: Use attributed string with attachment instead of subviews to prevent layout churn
            if let nameLabel = cell.viewWithTag(1) as? UILabel {
                let name = post.name
                let isVerified = UserDataModel.shared.allUsers().first(where: { $0.fullName == name })?.isEmailVerified == true

                if isVerified {
                    let imageAttachment = NSTextAttachment()
                    imageAttachment.image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(AppDesign.Color.primary)
                    // Adjust vertical alignment
                    let font = nameLabel.font ?? AppDesign.Typography.bodyStrong
                    let mid = font.descender + font.capHeight
                    imageAttachment.bounds = CGRect(x: 0, y: font.descender + (mid - 13) / 2, width: 13, height: 13)

                    let fullString = NSMutableAttributedString(string: name + " ")
                    fullString.append(NSAttributedString(attachment: imageAttachment))
                    nameLabel.attributedText = fullString
                } else {
                    nameLabel.text = name
                }
            }

            if let label = cell.viewWithTag(4) as? UILabel {
                label.text = post.message
                label.applyTextStyle(AppDesign.Typography.body, lines: 2)
                label.lineBreakMode = .byTruncatingTail
            }

            if let likeButton = cell.viewWithTag(10) as? UIButton {
                var config = UIButton.Configuration.plain()
                config.title = "❤️ \(post.likeCount)"
                config.baseForegroundColor = .label
                config.titleLineBreakMode = .byTruncatingTail
                config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = AppDesign.Typography.subheadline
                    return outgoing
                }
                likeButton.configuration = config
            }
            if let commentButton = cell.viewWithTag(11) as? UIButton {
                var config = UIButton.Configuration.plain()
                config.title = "💬 \(post.commentCount)"
                config.baseForegroundColor = .label
                config.titleLineBreakMode = .byTruncatingTail
                config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = AppDesign.Typography.subheadline
                    return outgoing
                }
                commentButton.configuration = config
            }
            if let shareButton = cell.viewWithTag(12) as? UIButton {
                var config = UIButton.Configuration.plain()
                config.title = "↪️ \(post.shareCount)"
                config.baseForegroundColor = .label
                config.titleLineBreakMode = .byTruncatingTail
                config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = AppDesign.Typography.subheadline
                    return outgoing
                }
                shareButton.configuration = config
            }

            // Hide the redundant comments label to fix the card layout (excessive whitespace)
            if let commentsLabel = cell.viewWithTag(20) as? UILabel {
                commentsLabel.isHidden = true
                commentsLabel.text = ""
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


    // MARK: - didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Card tap does nothing — only the 💬 comment button opens the comment section.
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Swipe actions (Delete own posts/comments)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let currentUserID = SessionManager.shared.userID

        // ACTION: Delete Comment
        if tableView == commentTableView {
            let comment = liveCommunityComments[indexPath.row]
            // Only allow deleting own comments
            guard comment.authorUserID == currentUserID else { return nil }

            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
                guard let self = self else { completion(false); return }
                let postID = comment.postID

                // 1. Optimistic UI: Remove locally immediately
                self.liveCommunityComments.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)

                // 2. Delete from Supabase and update global count
                Task {
                    do {
                        let newCount = try await CommunityRepository.shared.deleteComment(commentID: comment.id, postID: postID)
                        await MainActor.run {
                            // Update the post's comment count in the main feed
                            if let i = self.feedPosts.firstIndex(where: { $0.remoteID == postID }) {
                                self.feedPosts[i].commentCount = newCount
                                self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                            }
                        }
                        completion(true)
                    } catch {
                        completion(false)
                        // If delete failed, you could optionally re-fetch comments here
                    }
                }
            }
            deleteAction.image = UIImage(systemName: "trash.fill")
            deleteAction.backgroundColor = UIColor.systemRed
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }

        // ACTION: Delete Post
        // Only the feed tab, not events
        guard segmentedControl.selectedSegmentIndex == 1,
              indexPath.row < feedPosts.count else { return nil }

        let post = feedPosts[indexPath.row]

        // Show delete only for the user's own posts
        guard let authorID = post.authorUserID, authorID == currentUserID else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self = self, let postID = post.remoteID else { completion(false); return }

            // 1. Remove locally immediately — snappy feel
            self.feedPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)

            // 2. Delete from Supabase in background
            Task {
                do {
                    try await CommunityRepository.shared.deletePost(postID: postID)
                    completion(true)
                } catch {
                    // Restore by re-fetching if server delete failed
                    self.fetchPostsFromSupabase()
                    completion(false)
                }
            }
        }

        deleteAction.image           = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = UIColor.systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView != commentTableView else { return UITableView.automaticDimension }
        // Event cards have a fixed hero height + metadata — estimate generously
        if segmentedControl.selectedSegmentIndex == 0 { return UITableView.automaticDimension }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView != commentTableView else { return 80 }
        return segmentedControl.selectedSegmentIndex == 0 ? 270 : 160
    }

    private func openNativeShareSheet(for post: Post) {
        guard let postID = post.remoteID else { return }
        
        let shareText = post.message
        var items: [Any] = [shareText]
        
        if let imageURL = post.imageURL {
            items.append(imageURL)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = { [weak self] (_, completed, _, _) in
            if completed {
                Task {
                    if let newCount = try? await CommunityRepository.shared.recordShare(postID: postID) {
                        await MainActor.run {
                            if let index = self?.feedPosts.firstIndex(where: { $0.remoteID == postID }) {
                                self?.feedPosts[index].shareCount = newCount
                                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }
                        }
                    }
                }
            }
        }
        
        present(activityVC, animated: true)
    }

    private func openNativeShareSheet(forEvent event: EventItem) {
        let shareText = "Check out this event: \(event.title) on \(event.startsAt)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(activityVC, animated: true)
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
