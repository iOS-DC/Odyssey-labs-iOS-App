import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var sementedControl: UISegmentedControl!
    @IBOutlet weak var NewPostContainerView: UIView!
    @IBOutlet weak var NewPostTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newPostBottomConstraint: NSLayoutConstraint!
    
    
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
        print("didTapAddPost triggered successfully")
        
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
                  !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print(" No text entered")
                return
            }

            print("Posting: \(typedText)")

           
            let newPost = Post(message: typedText, timestamp: "Just now")

          
            feedPosts.insert(newPost, at: 0)

           
            if sementedControl.selectedSegmentIndex == 0 {
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            } else {
                let alert = UIAlertController(title: "Posted!", message: "Your post has been added to Feed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
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
            (cell.viewWithTag(2) as? UILabel)?.text = "Rehan Khan"
            (cell.viewWithTag(4) as? UILabel)?.text = post.timestamp
            (cell.viewWithTag(5) as? UILabel)?.text = post.message
            return cell
        } else {
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
