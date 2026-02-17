import UIKit

class EventDetailsViewController: UIViewController {

   
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var event: EventItem?   // ADD THIS HERE

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let event = event else { return }

        // Title
        titleLabel.text = event.title

        // Description
        descriptionLabel.text = event.details ?? "No description available"

        // Location
        locationLabel.text = event.location?.name ?? "Unknown Location"

        // Format Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: event.startsAt)

        // Image
        if let name = event.imageName,
           let img = UIImage(named: name) {
            imageView.image = img
        } else {
            imageView.image = UIImage(named: "default_event")
        }
    }

    @IBAction func offerRideTapped(_ sender: Any) {
        print("offer ride tapped")
    }
    
    @IBAction func joinRide(_ sender: Any) {
        print("join ride tapped")
    }
}


