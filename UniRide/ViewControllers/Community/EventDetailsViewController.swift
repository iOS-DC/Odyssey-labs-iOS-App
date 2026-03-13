import UIKit

class EventDetailsViewController: UIViewController {

    // Keep outlets to prevent Storyboard crashes (setValue:forUndefinedKey:)
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var event: EventItem?

    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    private let heroImageView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let eventDateLabel = UILabel()
    private let eventLocationLabel = UILabel()
    
    private let actionButtonsStack = UIStackView()
    private let offerRideButton = UIButton(type: .system)
    private let joinRideButton = UIButton(type: .system)
    
    private let aboutHeaderLabel = UILabel()
    private let detailsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgrammaticUI()
        populateData()
    }

    private func setupProgrammaticUI() {
        view.backgroundColor = .systemBackground
        
        // Remove storyboard subviews to start fresh
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // ScrollView Setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Main Stack View
        stackView.axis = .vertical
        stackView.spacing = AppDesign.Spacing.lg
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDesign.Spacing.md),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDesign.Spacing.md),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppDesign.Spacing.xl - AppDesign.Spacing.md)
        ])
        
        // 1. Hero Image
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = AppDesign.Radius.md
        heroImageView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        stackView.addArrangedSubview(heroImageView)
        
        // 2. Header Info
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = AppDesign.Spacing.xs
        
        headerTitleLabel.applyTextStyle(AppDesign.Typography.h2, lines: 0)
        infoStack.addArrangedSubview(headerTitleLabel)
        
        eventDateLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        infoStack.addArrangedSubview(eventDateLabel)
        
        eventLocationLabel.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        infoStack.addArrangedSubview(eventLocationLabel)
        
        stackView.addArrangedSubview(infoStack)
        
        // 3. Action Buttons
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = AppDesign.Spacing.md
        actionButtonsStack.distribution = .fillEqually
        actionButtonsStack.heightAnchor.constraint(equalToConstant: AppDesign.Size.buttonHeight).isActive = true
        
        offerRideButton.applyProminentPrimaryCTA(title: "Offer Ride", corner: AppDesign.Radius.md)
        joinRideButton.applyProminentPrimaryCTA(title: "Join Ride", corner: AppDesign.Radius.md)
        
        offerRideButton.addTarget(self, action: #selector(offerRideTapped), for: .touchUpInside)
        joinRideButton.addTarget(self, action: #selector(joinRide), for: .touchUpInside)
        
        actionButtonsStack.addArrangedSubview(offerRideButton)
        actionButtonsStack.addArrangedSubview(joinRideButton)
        stackView.addArrangedSubview(actionButtonsStack)
        
        // 4. About Section
        aboutHeaderLabel.text = "About Event"
        aboutHeaderLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        stackView.addArrangedSubview(aboutHeaderLabel)
        
        detailsLabel.applyTextStyle(AppDesign.Typography.body, lines: 0)
        stackView.addArrangedSubview(detailsLabel)
    }
    
    private func populateData() {
        guard let event = event else { return }
        
        // Image
        if let name = event.imageName, let img = UIImage(named: name) {
            heroImageView.image = img
        } else {
            heroImageView.image = UIImage(named: "default_event")
        }
        
        // Title
        headerTitleLabel.text = event.title
        
        // Date with Icon
        let dateAtt = NSMutableAttributedString(attachment: NSTextAttachment(image: UIImage(systemName: "calendar")!))
        dateAtt.append(NSAttributedString(string: "  " + formatDate(event.startsAt)))
        eventDateLabel.attributedText = dateAtt
        
        // Location with Icon
        let locAtt = NSMutableAttributedString(attachment: NSTextAttachment(image: UIImage(systemName: "mappin.and.ellipse")!))
        locAtt.append(NSAttributedString(string: "  " + (event.location?.name ?? "Unknown")))
        eventLocationLabel.attributedText = locAtt
        
        // Description
        detailsLabel.text = event.details
        detailsLabel.setLineHeight(lineHeight: 1.4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df.string(from: date)
    }

    @objc @IBAction func offerRideTapped(_ sender: Any) {
        // BUG FIX: Record attendance in Supabase event_attendance table
        if let eventID = event?.id {
            Task { try? await CommunityRepository.shared.recordEventAttendance(eventID: eventID) }
        }
        let storyboard = UIStoryboard(name: "OfferRide", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "OfferRideViewController") as? OfferRideViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc @IBAction func joinRide(_ sender: Any) {
        // BUG FIX: Record attendance in Supabase event_attendance table
        if let eventID = event?.id {
            Task { try? await CommunityRepository.shared.recordEventAttendance(eventID: eventID) }
        }
        // Navigate directly to AvailableRideViewController with this event
        let storyboard = UIStoryboard(name: "JoinRide", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AvailableRideViewController") as? AvailableRideViewController {
            vc.event = self.event
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}




extension UILabel {
    func setLineHeight(lineHeight: CGFloat) {
        guard let text = self.text else { return }
        let attributeString = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineHeight
        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, attributeString.length))
        self.attributedText = attributeString
    }
}
