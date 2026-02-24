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

        contentView.applyCardStyle(corner: 24)
        findRideButton.layer.cornerRadius = 22
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
        let cell = UITableViewCell(style: .subtitle,
                                   reuseIdentifier: "JoinSuggestCell")
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let request = MKLocalSearch.Request(completion: result)

        MKLocalSearch(request: request).start { response, error in
            guard let item = response?.mapItems.first else { return }

            DispatchQueue.main.async {
                if self.activeTextField == self.fromTextField {
                    self.fromTextField.text = item.name
                    self.fromCoordinate = item.placemark.coordinate
                } else if self.activeTextField == self.toTextField {
                    self.toTextField.text = item.name
                    self.toCoordinate = item.placemark.coordinate
                }
                self.suggestionsTable.isHidden = true
            }
        }
    }

    private func updateSuggestionTablePosition() {
        guard let tf = activeTextField else { return }

        let frameInView = tf.convert(tf.bounds, to: self.view)

        suggestionsTable.frame = CGRect(
            x: frameInView.minX,
            y: frameInView.maxY + 4,
            width: frameInView.width,
            height: 220
        )

        suggestionsTable.isHidden = false
        view.insertSubview(suggestionsTable, aboveSubview: tf)
        view.bringSubviewToFront(findRideButton)
    }

    // MARK: - Find Ride button
    @IBAction func didTapFindRide(_ sender: Any) {
        guard
            let fromCoord = fromCoordinate,
            let toCoord = toCoordinate,
            let fromText = fromTextField.text, !fromText.isEmpty,
            let toText = toTextField.text, !toText.isEmpty
        else {
            print("Please choose From & To from suggestions")
            return
        }

        guard let vc = storyboard?.instantiateViewController(
            identifier: "AvailableRideViewController"
        ) as? AvailableRideViewController else {
            print("Could not cast to AvailableRideViewController")
            return
        }

        vc.fromCoordinate = fromCoord
        vc.toCoordinate = toCoord
        vc.date = datePicker.date
        vc.time = timePicker.date

        guard let nav = navigationController else {
            print("navigationController is nil")
            return
        }

        nav.pushViewController(vc, animated: true)
    }
}
