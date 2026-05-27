import UIKit
import PhotosUI

final class TripEditorViewController: UIViewController {
    var onSave: (() -> Void)?

    private let trip: Trip?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    // Image
    private let photoPicker = UIButton(type: .system)
    private let photoPreview = UIImageView()
    private var uploadedImageURL: String?
    private let uploadSpinner = UIActivityIndicatorView(style: .medium)

    // Basics
    private let titleField = UITextField()
    private let locationField = UITextField()
    private let organizerField = UITextField()
    private let imageNameField = UITextField()
    private let dateRangeField = UITextField()

    // Dates
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()

    // Numbers
    private let priceField = UITextField()
    private let spotsField = UITextField()

    // Long text
    private let aboutView = UITextView()
    private let inclusionsView = UITextView()
    private let exclusionsView = UITextView()
    private let itineraryView = UITextView()

    private let saveButton = UIButton(type: .system)

    init(trip: Trip? = nil) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = trip == nil ? "Add Trip" : "Edit Trip"
        view.backgroundColor = AppDesign.Color.groupedBackground
        buildLayout()
        fillExistingValues()
        updateSaveState()
    }

    // MARK: - Layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        stack.axis = .vertical
        stack.spacing = AppDesign.Spacing.lg
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.md * 2)
        ])

        stack.addArrangedSubview(makePhotoCard())

        configureField(titleField, placeholder: "Trip title", keyboard: .default)
        configureField(locationField, placeholder: "Location (e.g. Manali, Himachal)")
        configureField(organizerField, placeholder: "Organizer name")
        configureField(imageNameField, placeholder: "Image asset name (leave blank if photo uploaded)")
        configureField(dateRangeField, placeholder: "Date range text (e.g. 12–15 June)")
        configureField(priceField, placeholder: "Price in ₹ (e.g. 5999)", keyboard: .numberPad)
        configureField(spotsField, placeholder: "Spots available (e.g. 10)", keyboard: .numberPad)

        startPicker.datePickerMode = .date
        startPicker.preferredDatePickerStyle = .compact
        endPicker.datePickerMode = .date
        endPicker.preferredDatePickerStyle = .compact

        configureTextView(aboutView, placeholder: "About the trip…", height: 120)
        configureTextView(inclusionsView, placeholder: "What's included — one item per line\ne.g.\n3 nights accommodation\nDaily breakfast & dinner", height: 100)
        configureTextView(exclusionsView, placeholder: "What's excluded — one item per line\ne.g.\nLunch\nPersonal expenses", height: 100)
        configureTextView(itineraryView, placeholder: "Itinerary — separate days with a blank line\ne.g.\nDay 1: Arrival\n- Check-in to hotel\n- Evening walk\n\nDay 2: Adventure\n- Paragliding\n- Zorbing", height: 200)

        stack.addArrangedSubview(makeCard(title: "Basics", views: [titleField, locationField, organizerField, imageNameField]))
        stack.addArrangedSubview(makeCard(title: "Schedule", views: [
            dateRangeField,
            makePickerRow("Start date", picker: startPicker),
            makePickerRow("End date", picker: endPicker)
        ]))
        stack.addArrangedSubview(makeCard(title: "Pricing & Availability", views: [priceField, spotsField]))
        stack.addArrangedSubview(makeCard(title: "About", views: [aboutView]))
        stack.addArrangedSubview(makeCard(title: "Inclusions", views: [inclusionsView]))
        stack.addArrangedSubview(makeCard(title: "Exclusions", views: [exclusionsView]))
        stack.addArrangedSubview(makeCard(title: "Itinerary", views: [itineraryView]))

        saveButton.applyProminentPrimaryCTA(title: trip == nil ? "Post Trip" : "Save Changes", corner: AppDesign.Radius.md)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
    }

    private func makePhotoCard() -> UIView {
        let card = UIView()
        card.applyCardStyle(corner: AppDesign.Radius.md,
                            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                            shadowRadius: AppDesign.Shadow.smallCardRadius)

        photoPreview.contentMode = .scaleAspectFill
        photoPreview.clipsToBounds = true
        photoPreview.layer.cornerRadius = AppDesign.Radius.sm
        photoPreview.backgroundColor = AppDesign.Color.fieldBackground
        photoPreview.image = UIImage(systemName: "photo.on.rectangle.angled")
        photoPreview.tintColor = .tertiaryLabel
        photoPreview.translatesAutoresizingMaskIntoConstraints = false

        uploadSpinner.hidesWhenStopped = true
        uploadSpinner.translatesAutoresizingMaskIntoConstraints = false

        var cfg = UIButton.Configuration.tinted()
        cfg.title = "Choose Photo"
        cfg.image = UIImage(systemName: "photo.badge.plus")
        cfg.imagePadding = 6
        cfg.cornerStyle = .medium
        photoPicker.configuration = cfg
        photoPicker.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
        photoPicker.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Cover Photo"
        titleLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLabel)
        card.addSubview(photoPreview)
        card.addSubview(uploadSpinner)
        card.addSubview(photoPicker)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: AppDesign.Spacing.md),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),

            photoPreview.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppDesign.Spacing.sm),
            photoPreview.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),
            photoPreview.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.md),
            photoPreview.heightAnchor.constraint(equalToConstant: 160),

            uploadSpinner.centerXAnchor.constraint(equalTo: photoPreview.centerXAnchor),
            uploadSpinner.centerYAnchor.constraint(equalTo: photoPreview.centerYAnchor),

            photoPicker.topAnchor.constraint(equalTo: photoPreview.bottomAnchor, constant: AppDesign.Spacing.sm),
            photoPicker.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            photoPicker.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.md),
        ])
        return card
    }

    @objc private func choosePhotoTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func configureField(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType = .default) {
        field.placeholder = placeholder
        field.applyRoundedField()
        field.keyboardType = keyboard
        field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
    }

    private func configureTextView(_ tv: UITextView, placeholder: String, height: CGFloat) {
        tv.font = AppDesign.Typography.body
        tv.backgroundColor = AppDesign.Color.fieldBackground
        tv.layer.cornerRadius = AppDesign.Radius.md
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        tv.heightAnchor.constraint(equalToConstant: height).isActive = true
        tv.text = placeholder
        tv.textColor = .placeholderText
        tv.delegate = self
    }

    private func makeCard(title: String, views: [UIView]) -> UIView {
        let card = UIView()
        card.applyCardStyle(corner: AppDesign.Radius.md,
                            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                            shadowRadius: AppDesign.Shadow.smallCardRadius)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)

        let inner = UIStackView(arrangedSubviews: [titleLabel] + views)
        inner.axis = .vertical
        inner.spacing = AppDesign.Spacing.sm
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: AppDesign.Spacing.md),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppDesign.Spacing.md),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppDesign.Spacing.md),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppDesign.Spacing.md)
        ])
        return card
    }

    private func makePickerRow(_ label: String, picker: UIDatePicker) -> UIView {
        let lbl = UILabel()
        lbl.text = label
        lbl.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)
        let row = UIStackView(arrangedSubviews: [lbl, picker])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        return row
    }

    // MARK: - Pre-fill

    private func fillExistingValues() {
        startPicker.minimumDate = nil
        startPicker.date = Date().addingTimeInterval(60 * 60 * 24 * 7)
        endPicker.date = startPicker.date.addingTimeInterval(60 * 60 * 24 * 3)

        guard let trip else { return }
        photoPreview.loadImage(from: trip.imageName)
        titleField.text = trip.title
        locationField.text = trip.location
        organizerField.text = trip.organizer
        imageNameField.text = trip.imageName
        dateRangeField.text = trip.dateRange
        priceField.text = "\(trip.price)"
        spotsField.text = "\(trip.spotsLeft)"
        startPicker.date = trip.startDate
        setTextViewContent(aboutView, text: trip.about)
        setTextViewContent(inclusionsView, text: trip.inclusions.joined(separator: "\n"))
        setTextViewContent(exclusionsView, text: trip.exclusions.joined(separator: "\n"))
        setTextViewContent(itineraryView, text: formatItinerary(trip.itinerary))
    }

    private func setTextViewContent(_ tv: UITextView, text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        tv.text = text
        tv.textColor = .label
    }

    // MARK: - Validation

    @objc private func fieldChanged() { updateSaveState() }

    private func updateSaveState() {
        let hasTitle = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = !(locationField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasOrganizer = !(organizerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        saveButton.setPrimaryCTAEnabled(hasTitle && hasLocation && hasOrganizer)
    }

    // MARK: - Save

    @objc private func saveTapped() {
        let titleText = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let locationText = (locationField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let organizerText = (organizerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleText.isEmpty, !locationText.isEmpty, !organizerText.isEmpty else { return }

        let priceValue = Int(priceField.text ?? "") ?? 0
        let spotsValue = Int(spotsField.text ?? "") ?? 10
        let aboutText = textViewValue(aboutView)
        let inclusionsText = textViewValue(inclusionsView)
        let exclusionsText = textViewValue(exclusionsView)
        let itineraryText = textViewValue(itineraryView)

        let resolvedImage = uploadedImageURL
            ?? imageNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            ?? trip?.imageName
            ?? "eventImage"

        let updated = Trip(
            id: trip?.id ?? UUID(),
            title: titleText,
            location: locationText,
            dateRange: (dateRangeField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "\(formatDate(startPicker.date))",
            startDate: startPicker.date,
            price: priceValue,
            spotsLeft: spotsValue,
            organizer: organizerText,
            imageName: resolvedImage,
            about: aboutText,
            itinerary: parseItinerary(itineraryText),
            inclusions: parseLines(inclusionsText),
            exclusions: parseLines(exclusionsText),
            isPast: startPicker.date < Date()
        )

        if trip == nil {
            TripDataModel.shared.addTrip(updated)
        } else {
            TripDataModel.shared.updateTrip(updated)
        }

        Task { [isNew = trip == nil] in
            if isNew {
                try? await TripsAPI.shared.createTrip(updated)
            } else {
                try? await TripsAPI.shared.updateTrip(updated)
            }
        }

        AppHaptics.success()
        onSave?()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helpers

    private func textViewValue(_ tv: UITextView) -> String {
        tv.textColor == .placeholderText ? "" : (tv.text ?? "")
    }

    private func parseLines(_ text: String) -> [String] {
        text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func parseItinerary(_ text: String) -> [ItineraryDay] {
        guard !text.isEmpty else { return [] }
        return text
            .components(separatedBy: "\n\n")
            .compactMap { block -> ItineraryDay? in
                let lines = block.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                guard let first = lines.first else { return nil }
                let activities = lines.dropFirst().map {
                    $0.trimmingCharacters(in: .whitespaces)
                      .replacingOccurrences(of: "^[-•] ?", with: "", options: .regularExpression)
                }
                return ItineraryDay(title: first, activities: activities)
            }
    }

    private func formatItinerary(_ days: [ItineraryDay]) -> String {
        days.map { day in
            ([day.title] + day.activities.map { "- \($0)" }).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension TripEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.photoPreview.image = image
                self.uploadSpinner.startAnimating()
                self.saveButton.isEnabled = false
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    self.uploadSpinner.stopAnimating()
                    return
                }
                let filename = "trips/\(UUID().uuidString).jpg"
                if let url = try? await StorageService.shared.upload(bucket: "community-images", path: filename, imageData: data) {
                    self.uploadedImageURL = url
                }
                self.uploadSpinner.stopAnimating()
                self.updateSaveState()
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension TripEditorViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.textColor = .placeholderText
            // restore placeholder
            switch textView {
            case aboutView:       textView.text = "About the trip…"
            case inclusionsView:  textView.text = "What's included — one item per line\ne.g.\n3 nights accommodation\nDaily breakfast & dinner"
            case exclusionsView:  textView.text = "What's excluded — one item per line\ne.g.\nLunch\nPersonal expenses"
            case itineraryView:   textView.text = "Itinerary — separate days with a blank line\ne.g.\nDay 1: Arrival\n- Check-in to hotel\n- Evening walk\n\nDay 2: Adventure\n- Paragliding\n- Zorbing"
            default: break
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
