//
//  UpcomingTableViewCell.swift
//  UniRide
//
//  Created by Jagpreet Singh on 23/11/25.
//  (Complete cell with map, requests area, configure + reuse-safe handling)
//

import UIKit
import MapKit

protocol UpcomingTableViewCellDelegate: AnyObject {
    /// Called when user toggles the requests area (so the table can animate height change)
    func upcomingCellRequestsToggled(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapMessage(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCall(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapCancelRide(_ cell: UpcomingTableViewCell)
    func upcomingCellDidTapViewRequests(_ cell: UpcomingTableViewCell)
}

final class UpcomingTableViewCell: UITableViewCell {
    static let reuseIdentifier = "UpcomingRideCell" // set this as the XIB cell identifier too

    // MARK: - IBOutlets (connect these in the cell XIB)
    @IBOutlet weak var cardView: UIView!

    // Top row
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!

    // Route / times / seats
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var seatsLabel: UILabel!
    @IBOutlet weak var passengersLabel: UILabel! // small hint label "Passengers >"

    // Map
    @IBOutlet weak var mapView: MKMapView! // connect in XIB

    // Requests area
    @IBOutlet weak var requestContainerView: UIView!      // container above map or below map depending on layout
    @IBOutlet weak var viewRequestButton: UIButton!       // "view req" button
    @IBOutlet weak var requestsScrollView: UIScrollView!  // scroll view that contains horizontal stack
    @IBOutlet weak var requestsScrollStack: UIStackView!  // horizontal stack inside scroll view

    // Approved chips
    @IBOutlet weak var approvedStackView: UIStackView!

    // Action buttons
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cancelRideButton: UIButton!
    
    @IBOutlet weak var mapHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var requestsContainerHeightConstraint: NSLayoutConstraint!


    // MARK: - State
    private var rideForCell: Ride?
    private var isRequestsExpanded = false

    weak var delegate: UpcomingTableViewCellDelegate?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        setupVisuals()

        // initial requests UI folded
        requestContainerView.isHidden = true
        isRequestsExpanded = false

        // Button wiring
        viewRequestButton.addTarget(self, action: #selector(viewRequestsTapped(_:)), for: .touchUpInside)
        messageButton.addTarget(self, action: #selector(messageTapped(_:)), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(callTapped(_:)), for: .touchUpInside)
        cancelRideButton.addTarget(self, action: #selector(cancelTapped(_:)), for: .touchUpInside)

        // Keep map from stealing taps (unless you want map gestures)
        mapView.isUserInteractionEnabled = false
        
        mapHeightConstraint?.constant = 140
        requestsContainerHeightConstraint?.constant = 0
        requestContainerView.isHidden = true

    }

    private func setupVisuals() {
        // Card
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.backgroundColor = .systemBackground

        // Status pill
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Buttons style
        [messageButton, callButton, cancelRideButton, viewRequestButton].forEach {
            $0?.layer.cornerRadius = 8
            $0?.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        }

        // Stack view settings (chip stack)
        approvedStackView.axis = .horizontal
        approvedStackView.spacing = 8
        approvedStackView.alignment = .center
        approvedStackView.distribution = .fillProportionally

        // Requests scroll stack
        requestsScrollStack.axis = .horizontal
        requestsScrollStack.alignment = .center
        requestsScrollStack.spacing = 12
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // reset map
        if let map = mapView {
            map.removeAnnotations(map.annotations)
            map.delegate = nil
        }

        // clear labels
        statusLabel.text = nil
        dateLabel.text = nil
        roleLabel.text = nil
        fromLabel.text = nil
        toLabel.text = nil
        startTimeLabel.text = nil
        endTimeLabel.text = nil
        durationLabel.text = nil
        seatsLabel.text = nil
        passengersLabel.text = nil

        // clear dynamic stacks
        approvedStackView.arrangedSubviews.forEach {
            approvedStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        requestsScrollStack.arrangedSubviews.forEach {
            requestsScrollStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        requestContainerView.isHidden = true
        isRequestsExpanded = false

        rideForCell = nil
    }

    // MARK: - Configure
    func configure(with trip: RideDataModel.MyTrip) {
        self.rideForCell = trip.ride

        // Role text
        switch trip.role {
        case .hosting: roleLabel.text = "Hosting"
        case .passenger: roleLabel.text = "Passenger"
        }

        // status
        let ride = trip.ride
        switch ride.status {
        case .draft:
            statusLabel.text = "Draft"
            statusLabel.textColor = .systemOrange
            statusLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        case .published:
            statusLabel.text = "Published"
            statusLabel.textColor = .systemGreen
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        case .ongoing:
            statusLabel.text = "Ongoing"
            statusLabel.textColor = .systemBlue
            statusLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        case .completed:
            statusLabel.text = "Completed"
            statusLabel.textColor = .secondaryLabel
            statusLabel.backgroundColor = UIColor.systemGray5
        case .cancelled:
            statusLabel.text = "Cancelled"
            statusLabel.textColor = .systemRed
            statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        }

        let tf = DateFormatter(); tf.dateFormat = "HH:mm"
        startTimeLabel.text = tf.string(from: ride.departureTime)

        // Use selectedRoute.expectedTravelTime if present (seconds), else fallback to 2 hour
        let travelSeconds = ride.selectedRoute?.expectedTravelTime ?? (2 * 3600)
        let endDate = ride.departureTime.addingTimeInterval(travelSeconds)
        endTimeLabel.text = tf.string(from: endDate)

        // Nicely formatted duration (e.g. "2h 15m" or "45m")
        durationLabel.text = formatDuration(travelSeconds)
        fromLabel.text = ride.source.address ?? "Source"
        toLabel.text = ride.destination.address ?? "Destination"
        seatsLabel.text = "\(ride.seatsTotal - ride.seatsAvailable)/\(ride.seatsTotal) seats"
        passengersLabel.text = "Passengers >"

        // Requests area state
        let allReqs = RideDataModel.shared.listRequests(for: ride.id)
        let pendingCount = allReqs.filter { $0.status == .pending }.count

        // Update request button title & visibility
        if pendingCount > 0 {
            viewRequestButton.isHidden = false
            viewRequestButton.setTitle("Requests (\(pendingCount))", for: .normal)
            // Optionally highlight the button for attention
            viewRequestButton.layer.borderWidth = 0.5
            viewRequestButton.layer.borderColor = UIColor.systemGray4.cgColor
        } else {
            viewRequestButton.isHidden = true
            viewRequestButton.setTitle("Requests", for: .normal)
            viewRequestButton.layer.borderWidth = 0
        }

        // Keep expand/collapse behavior as before (host taps to view)
        requestContainerView.isHidden = !isRequestsExpanded
        requestsContainerHeightConstraint?.constant = isRequestsExpanded ? 140 : 0
        if isRequestsExpanded {
            populateRequests(for: ride)
        }

        


        // Fill approved chips
        populateApprovedPassengers(ride)

        // Configure map with source coordinate (if available)
        if let coord = coordinate(for: ride.source) {
            mapView.removeAnnotations(mapView.annotations)
            let a = MKPointAnnotation(); a.coordinate = coord
            a.title = ride.source.address ?? "Pickup"
            mapView.addAnnotation(a)
            let region = MKCoordinateRegion(center: coord,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
            mapView.setRegion(region, animated: false)
        }
    }

    // MARK: - Helpers
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(round(seconds / 60.0))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        else if h > 0 { return "\(h)h" }
        else { return "\(m)m" }
    }

    private func coordinate(for point: LocationPoint) -> CLLocationCoordinate2D? {
        guard !(point.lat == 0 && point.lon == 0) else { return nil }
        return CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
    }

    private func populateApprovedPassengers(_ ride: Ride) {
        approvedStackView.arrangedSubviews.forEach {
            approvedStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let bookings = RideDataModel.shared.listBookings(for: ride.id).filter { $0.status == .confirmed }
        let names: [String] = bookings.compactMap {
            UserDataModel.shared.getUser(by: $0.passengerUserID)?.fullName
        }

        if names.isEmpty {
            let chip = makeChip(text: "No approved passengers")
            approvedStackView.addArrangedSubview(chip)
            return
        }

        for name in names {
            let chip = makeChip(text: name)
            approvedStackView.addArrangedSubview(chip)
        }
    }

    private func makeChip(text: String) -> UILabel {
        let chip = PaddingLabel()
        chip.text = text
        chip.font = .systemFont(ofSize: 13, weight: .medium)
        chip.backgroundColor = UIColor.systemGray6
        chip.textColor = .label
        chip.layer.cornerRadius = 12
        chip.clipsToBounds = true
        chip.textAlignment = .center
        chip.padding = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        chip.translatesAutoresizingMaskIntoConstraints = false
        return chip
    }

    // MARK: - Requests population
    private func populateRequests(for ride: Ride) {
        // clear
        requestsScrollStack.arrangedSubviews.forEach {
            requestsScrollStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let reqs = RideDataModel.shared.listRequests(for: ride.id).sorted { $0.createdAt < $1.createdAt }
        for req in reqs {
            let card = makeRequestCard(request: req, ride: ride)
            // fixed width for horizontal cards
            card.widthAnchor.constraint(equalToConstant: 260).isActive = true
            requestsScrollStack.addArrangedSubview(card)
        }
    }

    private func makeRequestCard(request: RideRequest, ride: Ride) -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 12
        card.backgroundColor = .systemBackground
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.systemGray4.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        // Name
        let name = UserDataModel.shared.getUser(by: request.passengerUserID)?.fullName ?? "Passenger"
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        // status
        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 13)
        switch request.status {
        case .pending:
            statusLabel.text = "Pending"
            statusLabel.textColor = .systemOrange
        case .approved:
            statusLabel.text = "Approved"
            statusLabel.textColor = .systemGreen
        case .denied:
            statusLabel.text = "Denied"
            statusLabel.textColor = .systemRed
        case .cancelled:
            statusLabel.text = "Cancelled"
            statusLabel.textColor = .secondaryLabel
        }

        let seatsLbl = UILabel()
        seatsLbl.font = .systemFont(ofSize: 13)
        seatsLbl.textColor = .secondaryLabel
        seatsLbl.text = request.seats > 1 ? "\(request.seats) seats" : "1 seat"

        let routeLbl = UILabel()
        routeLbl.font = .systemFont(ofSize: 13)
        routeLbl.textColor = .secondaryLabel
        routeLbl.text = "\(ride.source.address ?? "From") → \(ride.destination.address ?? "To")"
        routeLbl.numberOfLines = 1

        // Approve / Deny buttons for host (we tag by UUID hash)
        let approveBtn = UIButton(type: .system)
        approveBtn.setTitle("Approve", for: .normal)
        approveBtn.setTitleColor(.white, for: .normal)
        approveBtn.backgroundColor = .systemGreen
        approveBtn.layer.cornerRadius = 6
        approveBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        approveBtn.translatesAutoresizingMaskIntoConstraints = false
        approveBtn.tag = request.id.hashValue
        approveBtn.addTarget(self, action: #selector(requestApproveTapped(_:)), for: .touchUpInside)

        let denyBtn = UIButton(type: .system)
        denyBtn.setTitle("Deny", for: .normal)
        denyBtn.setTitleColor(.white, for: .normal)
        denyBtn.backgroundColor = .systemRed
        denyBtn.layer.cornerRadius = 6
        denyBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        denyBtn.translatesAutoresizingMaskIntoConstraints = false
        denyBtn.tag = request.id.hashValue
        denyBtn.addTarget(self, action: #selector(requestDenyTapped(_:)), for: .touchUpInside)

        approveBtn.isHidden = request.status != .pending
        denyBtn.isHidden = request.status != .pending

        // Layout
        let topRow = UIStackView(arrangedSubviews: [nameLabel, seatsLbl])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center

        let vstack = UIStackView(arrangedSubviews: [topRow, routeLbl, statusLabel])
        vstack.axis = .vertical
        vstack.spacing = 8
        vstack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(vstack)
        card.addSubview(approveBtn)
        card.addSubview(denyBtn)

        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            vstack.trailingAnchor.constraint(lessThanOrEqualTo: approveBtn.leadingAnchor, constant: -8),

            approveBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            approveBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            approveBtn.widthAnchor.constraint(equalToConstant: 88),
            approveBtn.heightAnchor.constraint(equalToConstant: 34),

            denyBtn.topAnchor.constraint(equalTo: approveBtn.bottomAnchor, constant: 8),
            denyBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            denyBtn.widthAnchor.constraint(equalToConstant: 72),
            denyBtn.heightAnchor.constraint(equalToConstant: 32),

            denyBtn.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    // MARK: - Request actions
    @objc private func requestApproveTapped(_ sender: UIButton) {
        guard let ride = rideForCell else { return }
        let reqs = RideDataModel.shared.listRequests(for: ride.id)
        guard let req = reqs.first(where: { $0.id.hashValue == sender.tag }) else { return }

        if ride.seatsAvailable < req.seats {
            // insufficient seats; in production show an alert via delegate
            return
        }
        RideDataModel.shared.approveRequest(requestID: req.id, hostUserID: ride.driverUserID)
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
    }

    @objc private func requestDenyTapped(_ sender: UIButton) {
        guard let ride = rideForCell else { return }
        let reqs = RideDataModel.shared.listRequests(for: ride.id)
        guard let req = reqs.first(where: { $0.id.hashValue == sender.tag }) else { return }
        RideDataModel.shared.denyRequest(requestID: req.id, hostUserID: ride.driverUserID)
        NotificationCenter.default.post(name: .rideRequestsUpdated, object: nil)
    }

    // MARK: - Button handlers (cell-level)
    @objc private func viewRequestsTapped(_ sender: UIButton) {
        isRequestsExpanded.toggle()

        // animate height change
        requestsContainerHeightConstraint?.constant = isRequestsExpanded ? 140 : 0
        requestContainerView.isHidden = false // keep visible while animating

        UIView.animate(withDuration: 0.25, animations: {
            self.contentView.layoutIfNeeded()
        }, completion: { _ in
            self.requestContainerView.isHidden = !self.isRequestsExpanded
            self.delegate?.upcomingCellRequestsToggled(self)
            if self.isRequestsExpanded, let ride = self.rideForCell {
                self.populateRequests(for: ride)
            }
        })
    }


    @objc private func messageTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapMessage(self)
    }

    @objc private func callTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapCall(self)
    }

    @objc private func cancelTapped(_ sender: UIButton) {
        delegate?.upcomingCellDidTapCancelRide(self)
    }
}

// MARK: - PaddingLabel helper
final class PaddingLabel: UILabel {
    var padding: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
