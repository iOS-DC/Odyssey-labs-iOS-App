//
//  EditHomeLocationViewController.swift
//  UniRide
//

import UIKit
import MapKit

final class EditHomeLocationViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UIGestureRecognizerDelegate {

    // MARK: - IBOutlets (wired in EditHomeLocation.storyboard)
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var contentStack: UIStackView!
    @IBOutlet private var searchContainer: UIView!
    @IBOutlet private var searchTextField: UITextField!
    @IBOutlet private var mapPreviewContainer: UIView!
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var summaryCard: UIView!
    @IBOutlet private var summaryTitleLabel: UILabel!
    @IBOutlet private var summaryAddressLabel: UILabel!
    @IBOutlet private var saveButton: UIButton!

    // MARK: - Dynamic overlay (floating, added at runtime)
    private let suggestionsTableView = UITableView()

    // MARK: - State
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var searchRequestID: Int = 0

    private var selectedLocation: LocationPoint?

    private let defaultRegion = MapKitManager.indiaRegion

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupScrollView()
        setupSearchUI()
        setupMapUI()
        setupSummaryUI()
        setupSuggestionsTableView()

        // Load existing
        if let home = UserDataModel.shared.preferredHomeLocation() {
            selectedLocation = home
        }

        setupSearch()
        updateUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Edit Home Location"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = AppDesign.Spacing.lg
    }

    private func setupSearchUI() {
        searchTextField.placeholder = "Enter college / city / sector"
        searchTextField.applyRoundedField()
        searchTextField.addLeftIcon("magnifyingglass")
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.autocorrectionType = .no

        let currentLocationButton = UIButton(type: .system)
        currentLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        currentLocationButton.tintColor = AppDesign.Color.primary
        currentLocationButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        currentLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        searchTextField.rightView = currentLocationButton
        searchTextField.rightViewMode = .always
    }

    private func setupMapUI() {
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isUserInteractionEnabled = false
        mapPreviewContainer.applyCardStyle(corner: AppDesign.Radius.md)
        mapPreviewContainer.clipsToBounds = true
    }

    private func setupSummaryUI() {
        summaryCard.applyCardStyle()
        summaryTitleLabel.text = "Selected Location"
        summaryTitleLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)
        summaryAddressLabel.text = "No location selected"
        summaryAddressLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        summaryAddressLabel.numberOfLines = 0
        saveButton.setTitle("Save Location", for: .normal)
        saveButton.applyPrimaryButton()
    }

    private func setupSuggestionsTableView() {
        // Floating autocomplete overlay — dynamic runtime subview
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.allowsSelection = true
        suggestionsTableView.isHidden = true
        suggestionsTableView.applySmallCard()
        suggestionsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        suggestionsTableView.layer.zPosition = 999
        suggestionsTableView.tableFooterView = UIView()

        view.addSubview(suggestionsTableView)
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: AppDesign.Spacing.xs),
            suggestionsTableView.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 240)
        ])
    }

    // MARK: - MapKit & Search
    private func setupSearch() {
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.delegate = self
        searchCompleter.region = defaultRegion
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        let query = textField.text ?? ""
        searchRequestID += 1
        selectedLocation = nil
        saveButton.setPrimaryCTAEnabled(false)

        if query.isEmpty {
            searchResults = []
            suggestionsTableView.reloadData()
            suggestionsTableView.isHidden = true
            return
        }
        view.bringSubviewToFront(suggestionsTableView)
        searchCompleter.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let query = (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            suggestionsTableView.reloadData()
            suggestionsTableView.isHidden = true
            return
        }

        let rawResults = completer.results
        let filtered = rawResults.filter { result in
            let haystack = "\(result.title) \(result.subtitle)".lowercased()
            return haystack.contains("india") || haystack.contains("punjab") || haystack.contains("rajpura") || haystack.contains("chandigarh") || haystack.contains("chitkara") || haystack.contains(query.lowercased())
        }

        searchResults = (filtered.isEmpty ? Array(rawResults.prefix(8)) : Array(filtered.prefix(8)))
        suggestionsTableView.reloadData()
        suggestionsTableView.isHidden = searchResults.isEmpty
        view.bringSubviewToFront(suggestionsTableView)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let request = MKLocalSearch.Request(completion: result)
        request.region = defaultRegion
        request.resultTypes = [.address, .pointOfInterest]

        searchTextField.text = result.title
        suggestionsTableView.isHidden = true
        view.endEditing(true)

        saveButton.setPrimaryCTAEnabled(false) // disable until geocoded

        MKLocalSearch(request: request).start { [weak self] response, error in
            guard let self = self, let item = response?.mapItems.first(where: MapKitManager.isInIndia) else {
                self?.saveButton.setPrimaryCTAEnabled(true)
                return
            }

            DispatchQueue.main.async {
                let name = item.name ?? result.title
                self.selectedLocation = LocationPoint(
                    lat: item.placemark.coordinate.latitude,
                    lon: item.placemark.coordinate.longitude,
                    address: name
                )
                self.updateUI()
            }
        }
    }

    // MARK: - Current Location
    @objc private func useCurrentLocationTapped() {
        guard let location = LocationService.shared.lastLocation else {
            LocationService.shared.requestWhenInUse()
            LocationService.shared.startLiveUpdates()

            let alert = UIAlertController(title: "Fetching Location", message: "Please allow access and try again in a moment.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self, let place = placemarks?.first else { return }
            let name = [place.name, place.locality, place.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")

            DispatchQueue.main.async {
                self.searchTextField.text = name
                self.selectedLocation = LocationPoint(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    address: name
                )
                self.suggestionsTableView.isHidden = true
                self.view.endEditing(true)
                self.updateUI()
            }
        }
    }

    // MARK: - UI Updates
    private func updateUI() {
        if let loc = selectedLocation {
            let address = (loc.address ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            summaryAddressLabel.text = address.isEmpty ? "Unknown" : address
            saveButton.setPrimaryCTAEnabled(true)

            let coordinate = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.lon)

            mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Home"
            mapView.addAnnotation(annotation)

            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            mapView.setRegion(region, animated: true)

        } else {
            summaryAddressLabel.text = "Please search for a location"
            saveButton.setPrimaryCTAEnabled(false)
        }
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        suggestionsTableView.isHidden = true
    }

    @IBAction private func saveTapped() {
        guard let loc = selectedLocation else { return }

        saveButton.setPrimaryCTAEnabled(false)
        saveButton.setTitle("Saving...", for: .normal)

        Task {
            guard let user = UserDataModel.shared.getCurrentUser() else { return }
            do {
                try await ProfileRepository.shared.upsertHomeLocation(userID: user.id, location: loc, isPrimary: true)
                UserDataModel.shared.setHomeLocations([loc])

                await MainActor.run {
                    AppHaptics.success()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    print("[EditHome] Failed to push to backend:", error)
                    self.saveButton.setPrimaryCTAEnabled(true)
                    self.saveButton.setTitle("Save Location", for: .normal)

                    let alert = UIAlertController(title: "Save Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var currentView: UIView? = touch.view
        while let view = currentView {
            if view === suggestionsTableView {
                return false
            }
            currentView = view.superview
        }
        return true
    }
}
