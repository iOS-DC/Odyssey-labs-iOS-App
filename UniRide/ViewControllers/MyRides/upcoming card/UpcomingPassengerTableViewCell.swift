import UIKit

class UpcomingPassengerTableViewCell: UITableViewCell {
    
   
//    outlets forms upcomming passenger table view cell xib file
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    
    @IBOutlet weak var rideStatusLabel: UILabel!
    
    @IBOutlet weak var hostNameLabel: UILabel!
    
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var requestStatusLabel: UILabel!
    
    @IBOutlet weak var hostImageView: UIImageView!
    
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!
    
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        // Card styling – same as hosting cell
        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowColor = UIColor.black.cgColor
        
        hostImageView.layer.cornerRadius = hostImageView.bounds.height / 2
        hostImageView.clipsToBounds = true
    }
    
 
    
    func configure(with trip: RideDataModel.MyTrip) {
        let ride = trip.ride
        
        // date
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        dateLabel.text = df.string(from: ride.departureTime)
        
        // times
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)
        let endDate = ride.departureTime.addingTimeInterval(2 * 3600)
        endTimeLabel.text = tf.string(from: endDate)
        durationLabel.text = "2h"
        
        // route
        fromLabel.text = ride.source.address ?? "From"
        toLabel.text = ride.destination.address ?? "To"
        
        // seats
        let booked = ride.seatsTotal - ride.seatsAvailable
        seatsLabel.text = "\(booked)/\(ride.seatsTotal) seats"
        
        // ride lifecycle
        rideStatusLabel.text = ride.status.rawValue.capitalized
        
        // role label
        roleLabel.text = trip.role == .passenger ? "Passenger" : "Hosting"
        
        // request / booking status: prefer requestStatus if present, otherwise show Confirmed for bookings
        if let status = trip.requestStatus {
            requestStatusLabel.text = status == .pending ? "Pending" : status.rawValue.capitalized
        } else {
            requestStatusLabel.text = "Confirmed"
        }
        
        // host info
        hostNameLabel.text = "Host Name"
        hostImageView.image = UIImage(systemName: "person.circle")
    }
}
