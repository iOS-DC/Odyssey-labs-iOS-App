import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets
    @IBOutlet weak var sementedControl: UISegmentedControl!
    @IBOutlet weak var NewPostContainerView: UIView!
    @IBOutlet weak var NewPostTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newPostBottomConstraint: NSLayoutConstraint!  // Bottom constraint for bottom sheet
    
    // MARK: - Variables
    var eventPosts: [Post] = [
        Post(message: "Rangrez 2025", timestamp: "Nov 6, 2025 at 14:00")
    ]
    
    var feedPosts: [Post] = [
        Post(message: "Planning a weekend trip to Kasauli!", timestamp: "2 hours ago")
    ]
    
    struct Post {
        let message: String
        let timestamp: String
    }
    
    // MARK: - View Lifecycle
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
        
        // Ensure bottom sheet is hidden initially
        newPostBottomConstraint.constant = 250
    }
    
    // MARK: - Show Bottom Sheet
    @objc func didTapAddPost() {
        NewPostContainerView.isHidden = false
        print("🟢 didTapAddPost triggered successfully")
        
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 90
        
        UIView.animate(withDuration: 0.3) {
            self.newPostBottomConstraint.constant = -tabBarHeight  // Slide above tab bar
            self.view.layoutIfNeeded()
        }
        
        NewPostTextField.becomeFirstResponder()
    }
    
    // MARK: - Close Bottom Sheet (Fixed)
    @IBAction func closeNewPostView(_ sender: UIButton) {
        print("❌ Close button tapped")
        
        UIView.animate(withDuration: 0.3, animations: {
            self.newPostBottomConstraint.constant = 250  // Same as initial
            self.view.layoutIfNeeded()
        }) { _ in
            self.NewPostContainerView.isHidden = true
        }
        
        NewPostTextField.resignFirstResponder()
    }
    
    // MARK: - Post Button Action
    @IBAction func postButtonTapped(_ sender: UIButton) {
        guard let text = NewPostTextField.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newPost = Post(message: text, timestamp: "Just now")
        eventPosts.insert(newPost, at: 0)
        tableView.reloadData()
        
        NewPostTextField.text = ""
        sementedControl.selectedSegmentIndex = 1  // Switch to event tab
        closeNewPostView(sender)
    }
    
    // MARK: - Segment Action
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    // MARK: - TableView Logic
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sementedControl.selectedSegmentIndex == 0 ? feedPosts.count : eventPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sementedControl.selectedSegmentIndex == 0 {  // Feed tab
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
            let post = feedPosts[indexPath.row]
            (cell.viewWithTag(2) as? UILabel)?.text = "Rehan Khan"
            (cell.viewWithTag(4) as? UILabel)?.text = post.timestamp
            (cell.viewWithTag(5) as? UILabel)?.text = post.message
            return cell
        } else {  // Events tab
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
            let post = eventPosts[indexPath.row]
            (cell.viewWithTag(2) as? UILabel)?.text = post.message
            (cell.viewWithTag(3) as? UILabel)?.text = post.timestamp
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sementedControl.selectedSegmentIndex == 0 ? 160 : 150
    }
}
