// PostDetailViewController.swift
// UniRide
// Full thread view: post body header + comments list + compose bar.

import UIKit

final class PostDetailViewController: UIViewController {

    // MARK: - Data
    var post: CommunityPost!

    private var comments: [CommunityComment] = []
    /// Real names fetched from Supabase `profiles` table — always preferred over local cache.
    private var authorNames: [UUID: String] = [:]

    // MARK: - UI (wired in PostDetail.storyboard)
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var composeBar: UIView!
    @IBOutlet private var commentTextField: UITextField!
    @IBOutlet private var sendButton: UIButton!
    @IBOutlet private var spinner: UIActivityIndicatorView!
    /// Bottom constraint of the compose bar — animated when keyboard appears/disappears.
    @IBOutlet var composeBarBottom: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post"
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        setupComposeBar()
        setupKeyboardObservers()
        _ = NetworkMonitor.shared // ensure monitor is started
        loadComments()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.dataSource         = self
        tableView.delegate           = self
        tableView.separatorStyle     = .singleLine
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .interactive
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostHeaderCell")
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
    }

    private func setupComposeBar() {
        // Top separator (0.5pt) — dynamic runtime subview, acceptable exception
        let topSep = UIView()
        topSep.backgroundColor = .separator
        topSep.translatesAutoresizingMaskIntoConstraints = false
        composeBar.addSubview(topSep)
        NSLayoutConstraint.activate([
            topSep.topAnchor.constraint(equalTo: composeBar.topAnchor),
            topSep.leadingAnchor.constraint(equalTo: composeBar.leadingAnchor),
            topSep.trailingAnchor.constraint(equalTo: composeBar.trailingAnchor),
            topSep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
        commentTextField.placeholder   = "Add a comment…"
        commentTextField.borderStyle   = .none
        commentTextField.font          = .systemFont(ofSize: 15)
        commentTextField.returnKeyType = .send
        commentTextField.delegate      = self
        sendButton.tintColor = AppDesign.Color.primary
        spinner.hidesWhenStopped = true
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let info = note.userInfo,
              let frame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        let keyboardHeight = max(0, view.bounds.height - frame.origin.y)
        let safeBottom = view.safeAreaInsets.bottom
        composeBarBottom.constant = -(keyboardHeight > 0 ? keyboardHeight - safeBottom : 0)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - Data loading

    private func loadComments() {
        Task { @MainActor in
            do {
                comments = try await CommunityRepository.shared.fetchComments(postID: post.id)
                tableView.reloadData()
                // Fetch real names from Supabase for all comment authors
                await fetchRealAuthorNames()
            } catch {
                // Silently fail — offline users still see post header
            }
        }
    }

    /// Fetches real `full_name` values from Supabase `profiles` for every unique
    /// author UUID in the current comments list. Populates `authorNames` and
    /// reloads the table so mock/stale names are replaced with real ones.
    private func fetchRealAuthorNames() async {
        // Collect unique author IDs (include post author for the header cell too)
        var ids = Set(comments.map { $0.authorUserID })
        ids.insert(post.authorUserID)

        // Also include current user so their name is always correct
        if let currentID = UserDataModel.shared.getCurrentUser()?.id {
            ids.insert(currentID)
        }

        await withTaskGroup(of: (UUID, String)?.self) { group in
            for id in ids {
                group.addTask {
                    guard let row = try? await ProfileRepository.shared.fetchProfile(userID: id),
                          let name = row["full_name"] as? String,
                          !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    else { return nil }
                    return (id, name)
                }
            }
            for await result in group {
                if let (id, name) = result {
                    authorNames[id] = name
                }
            }
        }

        // Also always put current user's name (profile is always available locally)
        if let me = UserDataModel.shared.getCurrentUser(),
           !me.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authorNames[me.id] = me.fullName
        }

        tableView.reloadData()
    }

    // MARK: - Send comment

    @IBAction private func sendTapped() {
        submitComment()
    }

    private func submitComment() {
        let text = (commentTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        commentTextField.text = ""
        sendButton.isHidden = true
        spinner.startAnimating()

        Task { @MainActor in
            defer {
                self.spinner.stopAnimating()
                self.sendButton.isHidden = false
            }
            do {
                let newCount = try await CommunityRepository.shared.insertComment(postID: post.id, text: text)

                // NOTIFY GLOBALLY: So feed can update its local count immediately
                NotificationCenter.default.post(
                    name: .CommunityCommentDidUpdate,
                    object: nil,
                    userInfo: ["postID": post.id, "newCount": newCount]
                )

                self.comments = try await CommunityRepository.shared.fetchComments(postID: post.id)
                await self.fetchRealAuthorNames()
                let lastRow = IndexPath(row: self.comments.count - 1, section: 1)
                if !self.comments.isEmpty {
                    self.tableView.scrollToRow(at: lastRow, at: .bottom, animated: true)
                }
            } catch {
                self.commentTextField.text = text  // restore on failure
                let alert = UIAlertController(title: "Couldn't post comment",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension PostDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : comments.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 && !comments.isEmpty ? "Comments" : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return buildPostHeaderCell()
        }
        return buildCommentCell(at: indexPath.row)
    }

    // Post header cell
    private func buildPostHeaderCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostHeaderCell")!
        cell.selectionStyle = .none

        var config = UIListContentConfiguration.subtitleCell()

        // Author — prefer real Supabase name, fall back to local cache
        let name: String
        if let realName = authorNames[post.authorUserID], !realName.isEmpty {
            name = realName
        } else {
            let author = UserDataModel.shared.getUser(by: post.authorUserID)
            name = author?.fullName.isEmpty == false ? author!.fullName : "UniRide User"
        }
        let isVerified = UserDataModel.shared.getUser(by: post.authorUserID)?.isEmailVerified == true

        config.text          = name
        config.textProperties.font = .systemFont(ofSize: 13, weight: .semibold)
        config.textProperties.color = .secondaryLabel

        // Timestamp
        let df = RelativeDateTimeFormatter()
        df.unitsStyle = .short
        config.secondaryText = df.localizedString(for: post.createdAt, relativeTo: Date())
        config.secondaryTextProperties.color = .tertiaryLabel

        // Avatar — dedicated view for reliability
        if cell.contentView.viewWithTag(101) == nil {
            let iv = UIImageView()
            iv.tag = 101
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 18
            iv.backgroundColor = .systemGray6
            iv.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                iv.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                iv.widthAnchor.constraint(equalToConstant: 36),
                iv.heightAnchor.constraint(equalToConstant: 36)
            ])
        }

        let avatar = cell.contentView.viewWithTag(101) as? UIImageView
        avatar?.loadAndFallback(from: post.authorProfile?.photoURL, name: name)

        config.image = nil // Disable standard image
        config.imageToTextPadding = 52 // Room for avatar

        cell.contentConfiguration = config

        // Verified badge
        if isVerified {
            let badge = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            badge.tintColor = AppDesign.Color.primary
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.widthAnchor.constraint(equalToConstant: 14).isActive = true
            badge.heightAnchor.constraint(equalToConstant: 14).isActive = true
            cell.accessoryView = badge
        } else {
            cell.accessoryView = nil
        }

        // Post body below header — add as a text view if not already present
        if cell.viewWithTag(88) == nil {
            let body = UILabel()
            body.tag = 88
            body.numberOfLines = 0
            body.font = .systemFont(ofSize: 16)
            body.textColor = .label
            body.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(body)
            NSLayoutConstraint.activate([
                body.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 56),
                body.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                body.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                body.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16),
            ])
        }
        (cell.viewWithTag(88) as? UILabel)?.text = post.text
        return cell
    }

    // Comment cell
    private func buildCommentCell(at row: Int) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        let comment = comments[row]
        cell.configure(with: comment)
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension PostDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitComment()
        return false
    }
}
