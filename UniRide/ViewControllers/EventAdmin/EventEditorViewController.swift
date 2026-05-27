import UIKit
import PhotosUI

final class EventEditorViewController: UIViewController {
    var onSave: (() -> Void)?

    private let event: EventItem?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let titleField = UITextField()
    private let locationField = UITextField()
    private let imageNameField = UITextField()
    private let detailsView = UITextView()
    private let startsPicker = UIDatePicker()
    private let endsPicker = UIDatePicker()
    private let saveButton = UIButton(type: .system)

    // Image
    private let photoPreview = UIImageView()
    private let photoPicker = UIButton(type: .system)
    private let uploadSpinner = UIActivityIndicatorView(style: .medium)
    private var uploadedImageURL: String?

    init(event: EventItem? = nil) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event == nil ? "Create Event" : "Edit Event"
        view.backgroundColor = AppDesign.Color.groupedBackground
        buildLayout()
        fillExistingValues()
        updateSaveState()
    }

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

        configureField(titleField, placeholder: "Event title")
        configureField(locationField, placeholder: "Location")
        configureField(imageNameField, placeholder: "Image asset name (leave blank if photo uploaded)")

        detailsView.font = AppDesign.Typography.body
        detailsView.backgroundColor = AppDesign.Color.fieldBackground
        detailsView.layer.cornerRadius = AppDesign.Radius.md
        detailsView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        detailsView.heightAnchor.constraint(equalToConstant: 160).isActive = true

        startsPicker.datePickerMode = .dateAndTime
        startsPicker.preferredDatePickerStyle = .compact
        endsPicker.datePickerMode = .dateAndTime
        endsPicker.preferredDatePickerStyle = .compact

        stack.addArrangedSubview(makeCard(title: "Basics", views: [titleField, locationField, imageNameField]))
        stack.addArrangedSubview(makeCard(title: "Description", views: [detailsView]))
        stack.addArrangedSubview(makeCard(title: "Schedule", views: [makePickerRow(title: "Starts", picker: startsPicker), makePickerRow(title: "Ends", picker: endsPicker)]))

        saveButton.applyProminentPrimaryCTA(title: event == nil ? "Post Event" : "Save Changes", corner: AppDesign.Radius.md)
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

    private func configureField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.applyRoundedField()
        field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
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

    private func makePickerRow(title: String, picker: UIDatePicker) -> UIView {
        let label = UILabel()
        label.text = title
        label.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel)

        let row = UIStackView(arrangedSubviews: [label, picker])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        return row
    }

    private func fillExistingValues() {
        startsPicker.minimumDate = Date().addingTimeInterval(-60 * 60 * 24)
        endsPicker.minimumDate = Date()
        startsPicker.date = Date().addingTimeInterval(60 * 60 * 24)
        endsPicker.date = startsPicker.date.addingTimeInterval(2 * 60 * 60)

        guard let event else { return }
        if let name = event.imageName { photoPreview.loadImage(from: name) }
        titleField.text = event.title
        locationField.text = event.location?.name
        imageNameField.text = event.imageName
        detailsView.text = event.details
        startsPicker.date = event.startsAt
        endsPicker.date = event.endsAt ?? event.startsAt.addingTimeInterval(2 * 60 * 60)
    }

    @objc private func fieldChanged() {
        updateSaveState()
    }

    private func updateSaveState() {
        let hasTitle = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = !(locationField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        saveButton.setPrimaryCTAEnabled(hasTitle && hasLocation)
    }

    @objc private func saveTapped() {
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let location = (locationField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !location.isEmpty else { return }

        let updated = EventItem(
            id: event?.id ?? UUID(),
            createdByUserID: event?.createdByUserID ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: title,
            details: detailsView.text.trimmingCharacters(in: .whitespacesAndNewlines),
            location: EventLocation(name: location),
            startsAt: startsPicker.date,
            endsAt: endsPicker.date,
            attendeeCount: event?.attendeeCount ?? 0,
            dayScholarCount: event?.dayScholarCount ?? 0,
            imageName: uploadedImageURL
                ?? imageNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
                ?? event?.imageName,
            shareCount: event?.shareCount ?? 0
        )

        if event == nil {
            EventDataModel.shared.addEvent(updated)
        } else {
            EventDataModel.shared.updateEvent(updated)
        }

        Task { [isNew = event == nil] in
            if isNew {
                try? await EventsAPI.shared.createEvent(updated)
            } else {
                try? await EventsAPI.shared.updateEvent(updated)
            }
        }

        AppHaptics.success()
        onSave?()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension EventEditorViewController: PHPickerViewControllerDelegate {
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
                let filename = "events/\(UUID().uuidString).jpg"
                if let url = try? await StorageService.shared.upload(bucket: "community-images", path: filename, imageData: data) {
                    self.uploadedImageURL = url
                }
                self.uploadSpinner.stopAnimating()
                self.updateSaveState()
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
