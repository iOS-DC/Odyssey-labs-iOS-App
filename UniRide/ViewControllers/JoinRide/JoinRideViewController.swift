import UIKit
import MapKit

class JoinRideViewController: UIViewController,
                              UITextFieldDelegate,
                              UITableViewDelegate,
                              UITableViewDataSource,
                              MKLocalSearchCompleterDelegate {

    // MARK: - Storyboard Outlets (kept so IB connections don't crash)
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var findRideButton: UIButton!
    @IBOutlet weak var suggestionsTable: UITableView!

    // MARK: - Autocomplete
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var searchRequestID: Int = 0
    private var activeTextField: UITextField?

    private var fromCoordinate: CLLocationCoordinate2D?
    private var toCoordinate: CLLocationCoordinate2D?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find a Ride"
        view.backgroundColor = AppDesign.Color.groupedBackground

        // Hide the storyboard card — we build our own layout
        contentView?.isHidden = true

        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self
        searchCompleter.region = MapKitManager.indiaRegion

        suggestionsTable.translatesAutoresizingMaskIntoConstraints = true
        suggestionsTable.isHidden = true
        suggestionsTable.delegate = self
        suggestionsTable.dataSource = self

        fromTextField.delegate = self
        toTextField.delegate = self
        fromTextField.addTarget(self, action: #selector(routeFieldChanged(_:)), for: .editingChanged)
        toTextField.addTarget(self, action: #selector(routeFieldChanged(_:)), for: .editingChanged)

        setDefaultDateAndTime()
        setupPickers()
        buildLayout()
        prefillLocationsIfPossible()
        updateFindButtonState()
    }

    // MARK: - Build Layout (matches Offer Ride Step 1)
    private func buildLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppDesign.Spacing.lg
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.md * 2)
        ])

        // Header subtitle
        let header = UILabel()
        header.text = "Where are you going, and when?"
        header.applyTextStyle(AppDesign.Typography.subheadline, color: .secondaryLabel, lines: 0)
        stack.addArrangedSubview(header)

        // From / To unified route card
        fromTextField.borderStyle = .none
        fromTextField.backgroundColor = .clear
        fromTextField.addLeftIcon("circle.fill", tint: AppDesign.Color.success)
        fromTextField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        toTextField.borderStyle = .none
        toTextField.backgroundColor = .clear
        toTextField.addLeftIcon("mappin.circle.fill", tint: AppDesign.Color.destructive)
        toTextField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        stack.addArrangedSubview(makeRouteCard())

        // Date + Time pickers side by side (no "When" label — just a card)
        let dateView = makeLabeledPicker(picker: datePicker, icon: "calendar")
        let timeView = makeLabeledPicker(picker: timePicker, icon: "clock")
        let pickerRow = UIStackView(arrangedSubviews: [dateView, timeView])
        pickerRow.axis = .horizontal
        pickerRow.spacing = 10
        pickerRow.distribution = .fillEqually
        stack.addArrangedSubview(makeCard(title: "When", content: pickerRow))

        // Find Ride button
        let findTitle = findRideButton.currentTitle ?? "Find Available Rides"
        findRideButton.applyProminentPrimaryCTA(title: findTitle, corner: AppDesign.Radius.md)
        stack.addArrangedSubview(findRideButton)

        // Keep suggestions table on top
        view.bringSubviewToFront(suggestionsTable)
        view.bringSubviewToFront(findRideButton)
    }

    // MARK: - Card helpers

    private func makeRouteCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.applyCardStyle(corner: AppDesign.Radius.md,
                            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                            shadowRadius: AppDesign.Shadow.smallCardRadius)

        let titleLbl = UILabel()
        titleLbl.text = "Route"
        titleLbl.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)

        let hairline = UIView()
        hairline.backgroundColor = AppDesign.Color.divider
        hairline.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let innerStack = UIStackView(arrangedSubviews: [titleLbl, fromTextField, hairline, toTextField])
        innerStack.axis = .vertical
        innerStack.spacing = 4
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeCard(title: String, content: UIView) -> UIView {
        let card = UIView()
        card.applyCardStyle(corner: AppDesign.Radius.md,
                            shadowOpacity: AppDesign.Shadow.smallCardOpacity,
                            shadowRadius: AppDesign.Shadow.smallCardRadius)

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)

        let inner = UIStackView(arrangedSubviews: [titleLbl, content])
        inner.axis = .vertical
        inner.spacing = 8
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeLabeledPicker(picker: UIDatePicker, icon: String) -> UIView {
        let container = UIView()
        container.backgroundColor = AppDesign.Color.fieldBackground
        container.layer.cornerRadius = 16
        container.clipsToBounds = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.transform = .identity
        container.addSubview(iconView)
        container.addSubview(picker)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 54),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            picker.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            picker.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    // MARK: - Date / Time
    private func setDefaultDateAndTime() {
        datePicker.date = Date()
        timePicker.date = Date()
    }

    private func setupPickers() {
        datePicker.minimumDate = Date()
        timePicker.transform = CGAffineTransform(translationX: -20, y: 0)
    }

    private func prefillLocationsIfPossible() {
        guard let prefill = UserDataModel.shared.suggestedCommutePrefill() else { return }
        fromTextField.text = prefill.from.address ?? "Chitkara University"
        toTextField.text   = prefill.to.address   ?? "Home"
        fromCoordinate = CLLocationCoordinate2D(latitude: prefill.from.lat, longitude: prefill.from.lon)
        toCoordinate   = CLLocationCoordinate2D(latitude: prefill.to.lat,   longitude: prefill.to.lon)
        updateFindButtonState()
    }

    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) { refreshTimeConstraintIfNeeded() }
    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) { refreshTimeConstraintIfNeeded() }

    private func refreshTimeConstraintIfNeeded() {
        let min = Date().addingTimeInterval(10 * 60)
        if Calendar.current.isDateInToday(datePicker.date) {
            timePicker.minimumDate = min
            if timePicker.date < min { timePicker.date = min }
        } else {
            timePicker.minimumDate = nil
        }
    }

    @objc private func routeFieldChanged(_ sender: UITextField) {
        if sender == fromTextField { fromCoordinate = nil }
        if sender == toTextField { toCoordinate = nil }
        updateFindButtonState()
    }

    private func updateFindButtonState() {
        let hasFrom = !(fromTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTo = !(toTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        findRideButton.setPrimaryCTAEnabled(hasFrom && hasTo && fromCoordinate != nil && toCoordinate != nil)
    }

    // MARK: - Autocomplete typing
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField == fromTextField || textField == toTextField else { return true }
        let updated = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if textField == fromTextField { fromCoordinate = nil }
        if textField == toTextField { toCoordinate = nil }
        searchRequestID += 1
        searchCompleter.queryFragment = updated
        activeTextField = textField
        updateSuggestionTablePosition()
        DispatchQueue.main.async { [weak self] in self?.updateFindButtonState() }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let requestID = searchRequestID
        MapKitManager.shared.filterCompletionsToIndia(completer.results) { [weak self] filtered in
            guard let self, self.searchRequestID == requestID else { return }
            self.searchResults = filtered
            self.suggestionsTable.reloadData()
            let hasResults = !filtered.isEmpty
            self.suggestionsTable.isHidden = !hasResults
            self.suggestionsTable.isUserInteractionEnabled = hasResults
        }
    }

    // MARK: - Suggestions table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { searchResults.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinSuggestCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "JoinSuggestCell")
        let result = searchResults[indexPath.row]
        cell.textLabel?.text         = result.title
        cell.textLabel?.font         = AppDesign.Typography.subheadline
        cell.detailTextLabel?.text   = result.subtitle
        cell.detailTextLabel?.font   = AppDesign.Typography.caption
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image        = UIImage(systemName: "mappin")
        cell.imageView?.tintColor    = AppDesign.Color.primary
        cell.backgroundColor = .clear
        cell.selectionStyle  = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let request = MKLocalSearch.Request(completion: result)
        request.region = MapKitManager.indiaRegion
        request.resultTypes = .address
        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let self, let item = response?.mapItems.first(where: MapKitManager.isInIndia) else { return }
            DispatchQueue.main.async {
                if self.activeTextField == self.fromTextField {
                    self.fromTextField.text = item.name
                    self.fromCoordinate = item.placemark.coordinate
                } else {
                    self.toTextField.text = item.name
                    self.toCoordinate = item.placemark.coordinate
                }
                self.suggestionsTable.isHidden = true
                self.activeTextField?.resignFirstResponder()
                self.activeTextField = nil
                self.updateFindButtonState()
            }
        }
    }

    private func updateSuggestionTablePosition() {
        guard let tf = activeTextField else { return }
        let frame = tf.convert(tf.bounds, to: view)
        suggestionsTable.frame = CGRect(
            x: frame.minX, y: frame.maxY + AppDesign.Spacing.xxs,
            width: frame.width, height: 220
        )
        suggestionsTable.isHidden = false
        view.insertSubview(suggestionsTable, aboveSubview: tf)
        view.bringSubviewToFront(findRideButton)
    }

    // MARK: - Find Ride
    @IBAction func didTapFindRide(_ sender: Any) {
        ensureNonGuest { [weak self] in
            guard let self = self else { return }
            let fromText = self.fromTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let toText   = self.toTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !fromText.isEmpty, !toText.isEmpty else {
                self.showAlert("Route Incomplete", message: "Add both a pickup and drop-off to search for rides.")
                return
            }
            guard let fromCoord = self.fromCoordinate else {
                self.showAlert("Select a Location", message: "Tap a suggestion to confirm your pickup.")
                return
            }
            guard let toCoord = self.toCoordinate else {
                self.showAlert("Select a Location", message: "Tap a suggestion to confirm your drop-off.")
                return
            }
            guard fromText.lowercased() != toText.lowercased() else {
                self.showAlert("Same Location", message: "Your pickup and drop-off are the same place. Update one to continue.")
                return
            }

            self.view.endEditing(true)

            guard let vc = self.storyboard?.instantiateViewController(identifier: "AvailableRideViewController")
                    as? AvailableRideViewController else { return }
            vc.fromCoordinate = fromCoord
            vc.toCoordinate   = toCoord
            vc.fromAddress = fromText
            vc.toAddress = toText
            vc.date = self.datePicker.date
            vc.time = self.timePicker.date
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
