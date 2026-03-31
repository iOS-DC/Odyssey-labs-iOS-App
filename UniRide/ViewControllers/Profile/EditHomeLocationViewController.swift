//
//  EditHomeLocationViewController.swift
//  UniRide
//

import UIKit
import MapKit

final class EditHomeLocationViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UIGestureRecognizerDelegate {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let searchContainer = UIView()
    private let searchTextField = UITextField()
    private let currentLocationButton = UIButton(type: .system)
    
    private let mapPreviewContainer = UIView()
    private let mapView = MKMapView()
    
    private let summaryCard = UIView()
    private let summaryTitleLabel = UILabel()
    private let summaryAddressLabel = UILabel()
    
    private let saveButton = UIButton(type: .system)
    
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
        buildLayout()
        
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

    // MARK: - Layout & UI
    private func setupNavigationBar() {
        title = "Edit Home Location"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = AppDesign.Spacing.lg
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppDesign.Spacing.md),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppDesign.Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppDesign.Spacing.md),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppDesign.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -AppDesign.Spacing.md * 2)
        ])
        
        // 1. Search Bar
        buildSearchUI()
        contentStack.addArrangedSubview(searchContainer)
        
        // 2. Map Preview
        buildMapUI()
        contentStack.addArrangedSubview(mapPreviewContainer)
        
        // 3. Summary Card
        buildSummaryUI()
        contentStack.addArrangedSubview(summaryCard)
        
        // 4. Spacer & Save Button
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(spacer)
        
        saveButton.setTitle("Save Location", for: .normal)
        saveButton.applyPrimaryButton()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(saveButton)
        
        // 5. Autocomplete Table (Floating)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.allowsSelection = true
        suggestionsTableView.isHidden = true
        suggestionsTableView.applySmallCard()
        suggestionsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        view.addSubview(suggestionsTableView)
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: AppDesign.Spacing.xs),
            suggestionsTableView.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    private func buildSearchUI() {
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        
        searchTextField.placeholder = "Enter college / city / sector"
        searchTextField.applyRoundedField()
        searchTextField.addLeftIcon("magnifyingglass")
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.autocorrectionType = .no
        
        currentLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        currentLocationButton.tintColor = AppDesign.Color.primary
        currentLocationButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        currentLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        searchTextField.rightView = currentLocationButton
        searchTextField.rightViewMode = .always
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchTextField)
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor)
        ])
    }
    
    private func buildMapUI() {
        mapPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        mapPreviewContainer.heightAnchor.constraint(equalToConstant: 160).isActive = true
        mapPreviewContainer.applyCardStyle(corner: AppDesign.Radius.md)
        mapPreviewContainer.clipsToBounds = true
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isUserInteractionEnabled = false
        
        mapPreviewContainer.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mapPreviewContainer.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapPreviewContainer.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapPreviewContainer.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapPreviewContainer.bottomAnchor)
        ])
    }
    
    private func buildSummaryUI() {
        summaryCard.applyCardStyle()
        
        summaryTitleLabel.text = "Selected Location"
        summaryTitleLabel.applyTextStyle(AppDesign.Typography.captionStrong, color: .secondaryLabel)
        
        summaryAddressLabel.text = "No location selected"
        summaryAddressLabel.applyTextStyle(AppDesign.Typography.bodyStrong)
        summaryAddressLabel.numberOfLines = 0
        
        let icon = UIImageView(image: UIImage(systemName: "house.circle.fill"))
        icon.tintColor = AppDesign.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        let textStack = UIStackView(arrangedSubviews: [summaryTitleLabel, summaryAddressLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let row = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis = .horizontal
        row.spacing = AppDesign.Spacing.sm
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        
        summaryCard.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: AppDesign.Spacing.md),
            row.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: AppDesign.Spacing.md),
            row.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -AppDesign.Spacing.md),
            row.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -AppDesign.Spacing.md)
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
        if query.isEmpty {
            searchResults = []
            suggestionsTableView.reloadData()
            suggestionsTableView.isHidden = true
            return
        }
        searchCompleter.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let requestID = searchRequestID
        MapKitManager.shared.filterCompletionsToIndia(completer.results) { [weak self] filtered in
            guard let self, self.searchRequestID == requestID else { return }
            self.searchResults = filtered
            self.suggestionsTableView.reloadData()
            self.suggestionsTableView.isHidden = filtered.isEmpty
        }
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
            
            // Map handling
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
    
    @objc private func saveTapped() {
        guard let loc = selectedLocation else { return }
        
        saveButton.setPrimaryCTAEnabled(false)
        saveButton.setTitle("Saving...", for: .normal)
        
        Task {
            guard let user = UserDataModel.shared.getCurrentUser() else { return }
            do {
                // 1. Push to Supabase synchronously
                try await ProfileRepository.shared.upsertHomeLocation(userID: user.id, location: loc, isPrimary: true)
                
                // 2. Save locally
                UserDataModel.shared.setHomeLocations([loc])
                
                // 3. Return to profile
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
