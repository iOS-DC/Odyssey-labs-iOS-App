import UIKit
import MapKit

class JoinRideViewController: UIViewController,
                              UITextFieldDelegate,
                              UITableViewDelegate,
                              UITableViewDataSource,
                              MKLocalSearchCompleterDelegate {
    
    // MARK: - Outlets (connect these in storyboard)
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var findRideButton: UIButton!
    @IBOutlet weak var suggestionsTable: UITableView!   // small table used for autocomplete
    
    // MARK: - Helpers
    private let datePicker = UIDatePicker()
    private let timePicker = UIDatePicker()
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
        dateTextField.delegate = self
        timeTextField.delegate = self

        suggestionsTable.delegate = self
        suggestionsTable.dataSource = self

        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self

        setupDatePicker()
        setupTimePicker()

        findRideButton.layer.cornerRadius = 22
        
        view.bringSubviewToFront(findRideButton)
          
          print("🔷 Button frame at runtime:", findRideButton.frame)
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        print("👆 touchesEnded at:", point)

        if findRideButton.frame.contains(point) {
            print("👉 Touch was inside Find Ride button frame")
        }
    }

    // MARK: - Date picker
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()

        dateTextField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneSelectingDate)
        )
        toolbar.items = [done]
        dateTextField.inputAccessoryView = toolbar
    }

    @objc private func doneSelectingDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: datePicker.date)
        dateTextField.resignFirstResponder()
    }

    // MARK: - Time picker
    private func setupTimePicker() {
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels

        timeTextField.inputView = timePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneSelectingTime)
        )
        toolbar.items = [done]
        timeTextField.inputAccessoryView = toolbar
    }

    @objc private func doneSelectingTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        timeTextField.text = formatter.string(from: timePicker.date)
        timeTextField.resignFirstResponder()
    }

    // MARK: - Autocomplete typing
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        // Only run autocomplete on from/to, not date/time
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

        // 👉 Put table just above the text field,
        //    but NOT above the whole view / button
        view.insertSubview(suggestionsTable, aboveSubview: tf)

        // 👉 Make sure button stays on top
        view.bringSubviewToFront(findRideButton)
    }
        // MARK: - Find Ride button
        @IBAction func didTapFindRide(_ sender: Any) {
            print("🎉 didTapFindRide fired")

                    guard
                        let fromCoord = fromCoordinate,
                        let toCoord = toCoordinate,
                        let fromText = fromTextField.text, !fromText.isEmpty,
                        let toText = toTextField.text, !toText.isEmpty
                    else {
                        print("❌ Please choose From & To from suggestions")
                        return
                    }

                    guard let vc = storyboard?.instantiateViewController(
                        identifier: "AvailableRideViewController"
                    ) as? AvailableRideViewController else {
                        print("❌ Could not cast to AvailableRideViewController")
                        return
                    }

                    vc.fromCoordinate = fromCoord
                    vc.toCoordinate = toCoord
                    vc.date = datePicker.date
                    vc.time = timePicker.date

                    guard let nav = navigationController else {
                        print("❌ navigationController is nil")
                        return
                    }

                    nav.pushViewController(vc, animated: true)
                }
            }
