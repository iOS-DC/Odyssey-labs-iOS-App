import UIKit
import MapKit

class JoinRideViewController: UIViewController,
                              UITextFieldDelegate,
                              UITableViewDelegate,
                              UITableViewDataSource,
                              MKLocalSearchCompleterDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var findRideButton: UIButton!
    @IBOutlet weak var suggestionsTable: UITableView!
    
    // MARK: - Helpers
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var activeTextField: UITextField?

    private var fromCoordinate: CLLocationCoordinate2D?
    private var toCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find Ride"

        // Autocomplete table will be manually positioned
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = true
        suggestionsTable.isHidden = true

        fromTextField.delegate = self
        toTextField.delegate = self

        suggestionsTable.delegate = self
        suggestionsTable.dataSource = self

        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self

        setDefaultDateAndTime()
        setupPickers()
        prefillLocationsIfPossible()

        contentView.applyCardStyle(corner: AppDesign.Radius.lg)
        fromTextField.applyRoundedField()
        fromTextField.addLeftIcon("mappin")
        toTextField.applyRoundedField()
        toTextField.addLeftIcon("mappin")
        suggestionsTable.applySmallCard()
        let findTitle = findRideButton.currentTitle ?? "Find Ride"
        findRideButton.applyProminentPrimaryCTA(title: findTitle, corner: AppDesign.Radius.md)
        view.bringSubviewToFront(findRideButton)
    }

    // MARK: - Date / Time Pickers (inline, compact — same as Offer Ride)
    private func setDefaultDateAndTime() {
        datePicker.date = Date()
        timePicker.date = Date()
    }

    private func setupPickers() {
        datePicker.minimumDate = Date()
    }

    private func prefillLocationsIfPossible() {
        guard let prefill = UserDataModel.shared.suggestedCommutePrefill() else { return }
        fromTextField.text = prefill.from.address ?? "Chitkara University"
        toTextField.text = prefill.to.address ?? "Home"
        fromCoordinate = CLLocationCoordinate2D(latitude: prefill.from.lat, longitude: prefill.from.lon)
        toCoordinate = CLLocationCoordinate2D(latitude: prefill.to.lat, longitude: prefill.to.lon)
    }

    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        // Enforce time minimum when today is selected
        refreshTimeConstraintIfNeeded()
    }

    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) {
        refreshTimeConstraintIfNeeded()
    }

    private func refreshTimeConstraintIfNeeded() {
        let minTime = Date().addingTimeInterval(10 * 60)
        if Calendar.current.isDateInToday(datePicker.date) {
            timePicker.minimumDate = minTime
            if timePicker.date < minTime {
                timePicker.date = minTime
            }
        } else {
            timePicker.minimumDate = nil
        }
    }

    // MARK: - Autocomplete typing
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        guard textField == fromTextField || textField == toTextField else {
            return true
        }

        let updated = ((textField.text ?? "") as NSString)
            .replacingCharacters(in: range, with: string)

        searchCompleter.queryFragment = updated
        activeTextField = textField
        updateSuggestionTablePosition()
        return true
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTable.reloadData()

        let hasResults = !searchResults.isEmpty
        suggestionsTable.isHidden = !hasResults
        suggestionsTable.isUserInteractionEnabled = hasResults
    }

    // MARK: - Suggestions table
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinSuggestCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "JoinSuggestCell")
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.textLabel?.font = AppDesign.Typography.subheadline
        cell.detailTextLabel?.text = result.subtitle
        cell.detailTextLabel?.font = AppDesign.Typography.caption
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(systemName: "mappin")
        cell.imageView?.tintColor = AppDesign.Color.primary
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let request = MKLocalSearch.Request(completion: result)

        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let self, let item = response?.mapItems.first else { return }
            DispatchQueue.main.async {
                if self.activeTextField == self.fromTextField {
                    self.fromTextField.text = item.name
                    self.fromCoordinate = item.placemark.coordinate
                } else if self.activeTextField == self.toTextField {
                    self.toTextField.text = item.name
                    self.toCoordinate = item.placemark.coordinate
                }
                self.suggestionsTable.isHidden = true
                self.activeTextField?.resignFirstResponder()
                self.activeTextField = nil
            }
        }
    }

    private func updateSuggestionTablePosition() {
        guard let tf = activeTextField else { return }

        let frameInView = tf.convert(tf.bounds, to: self.view)

        suggestionsTable.frame = CGRect(
            x: frameInView.minX,
            y: frameInView.maxY + AppDesign.Spacing.xxs,
            width: frameInView.width,
            height: 220
        )

        suggestionsTable.isHidden = false
        view.insertSubview(suggestionsTable, aboveSubview: tf)
        view.bringSubviewToFront(findRideButton)
    }

    // MARK: - Find Ride button
    @IBAction func didTapFindRide(_ sender: Any) {
        let fromText = fromTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let toText   = toTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !fromText.isEmpty, !toText.isEmpty else {
            showValidationAlert("Missing Location", message: "Please select both a pickup and a drop-off location from the suggestions.")
            return
        }
        guard let fromCoord = fromCoordinate else {
            showValidationAlert("Select from suggestions", message: "Please pick your pickup location from the autocomplete list so we can find nearby rides.")
            return
        }
        guard let toCoord = toCoordinate else {
            showValidationAlert("Select from suggestions", message: "Please pick your drop-off location from the autocomplete list so we can find nearby rides.")
            return
        }
        guard fromText.lowercased() != toText.lowercased() else {
            showValidationAlert("Same Location", message: "Your pickup and drop-off locations can't be the same. Please choose different locations.")
            return
        }

        view.endEditing(true)

        guard let vc = storyboard?.instantiateViewController(
            identifier: "AvailableRideViewController"
        ) as? AvailableRideViewController else { return }

        vc.fromCoordinate = fromCoord
        vc.toCoordinate   = toCoord
        vc.date = datePicker.date
        vc.time = timePicker.date

        navigationController?.pushViewController(vc, animated: true)
    }

    private func showValidationAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
