//
//  ProfileStep3ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 19/11/25.
//

import UIKit
import MapKit

final class ProfileStep3ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate {

    @IBOutlet weak var containerCard: UIView!
    @IBOutlet weak var homeAddressTextField: UITextField!
    @IBOutlet weak var verificationCard: UIView!
    @IBOutlet weak var completeSetupButton: UIButton!

    private let locationsSummaryLabel = UILabel()
    private var homeLocation: LocationPoint?
    var isEditingMode: Bool = false
    
    private let suggestionsTable = UITableView()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    
    private let indiaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.9734, longitude: 78.6569),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isEditingMode ? "Edit Home Location" : "Set Home Location"
        applyOnboardingChrome(step: 7, total: 7)
        if isEditingMode {
            navigationItem.rightBarButtonItem = nil
        }
        
        let existingHome = RegistrationBuilder.shared.homeLocation ?? UserDataModel.shared.getHomeLocations().first
        if let stored = existingHome {
            homeLocation = stored
        }
        applyStyles()
        setupLocationSummary()
        refreshSummary()
        configureAccessibility()
        
        setupAutocomplete()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, verificationCard, completeSetupButton])
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        suggestionsTable.isHidden = true
    }

    private func applyStyles() {
        containerCard.applyCardStyle()
        verificationCard.applySmallCard()
        homeAddressTextField.applyRoundedField()

        // Using standard text field visually, but maybe light outline depending on current app style.
        
        completeSetupButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(completeSetupButton)
        completeSetupButton.setTitle(isEditingMode ? "Save Location" : "Complete Setup", for: .normal)
    }

    private func setupLocationSummary() {
        locationsSummaryLabel.font = AppDesign.Typography.subheadline
        locationsSummaryLabel.textColor = .secondaryLabel
        locationsSummaryLabel.numberOfLines = 0
        locationsSummaryLabel.translatesAutoresizingMaskIntoConstraints = false

        verificationCard.addSubview(locationsSummaryLabel)
        NSLayoutConstraint.activate([
            locationsSummaryLabel.topAnchor.constraint(equalTo: verificationCard.topAnchor, constant: AppDesign.Spacing.sm),
            locationsSummaryLabel.leadingAnchor.constraint(equalTo: verificationCard.leadingAnchor, constant: AppDesign.Spacing.sm),
            locationsSummaryLabel.trailingAnchor.constraint(equalTo: verificationCard.trailingAnchor, constant: -AppDesign.Spacing.sm),
            locationsSummaryLabel.bottomAnchor.constraint(equalTo: verificationCard.bottomAnchor, constant: -AppDesign.Spacing.sm)
        ])
    }

    private func refreshSummary() {
        if let home = homeLocation {
            let text = (home.address ?? "Location").trimmingCharacters(in: .whitespacesAndNewlines)
            locationsSummaryLabel.text = "Home:\n\(text)"
            homeAddressTextField.text = text
            completeSetupButton.setPrimaryCTAEnabled(true)
        } else {
            locationsSummaryLabel.text = "No home location set.\nPlease search and select your primary route from the suggestions above."
            completeSetupButton.setPrimaryCTAEnabled(false)
        }
    }
    
    // MARK: - Autocomplete Setup
    private func setupAutocomplete() {
        homeAddressTextField.delegate = self
        homeAddressTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Add Current Location Button
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = AppDesign.Color.primary
        locationButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        locationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        homeAddressTextField.rightView = locationButton
        homeAddressTextField.rightViewMode = .always
        
        // Format table view
        suggestionsTable.delegate = self
        suggestionsTable.dataSource = self
        suggestionsTable.isHidden = true
        suggestionsTable.applySmallCard()
        suggestionsTable.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.delegate = self
        searchCompleter.region = indiaRegion
    }
    
    @objc private func useCurrentLocationTapped() {
        guard let location = LocationService.shared.lastLocation else {
            LocationService.shared.requestWhenInUse()
            LocationService.shared.startLiveUpdates()
            showAlert("Fetching Location", "Please allow access and try again in a moment.")
            return
        }
        
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let place = placemarks?.first else { return }
            let name = [place.name, place.locality, place.administrativeArea].compactMap { $0 }.joined(separator: ", ")
            
            DispatchQueue.main.async {
                self.homeAddressTextField.text = name
                self.homeLocation = LocationPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude, address: name)
                self.refreshSummary()
                self.suggestionsTable.isHidden = true
                self.view.endEditing(true)
            }
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        homeLocation = nil
        completeSetupButton.setPrimaryCTAEnabled(false)
        
        let query = textField.text ?? ""
        if query.isEmpty {
            suggestionsTable.isHidden = true
            return
        }
        searchCompleter.queryFragment = query
        updateSuggestionTablePosition()
    }

    private func updateSuggestionTablePosition() {
        let frameInView = homeAddressTextField.convert(homeAddressTextField.bounds, to: self.view)
        suggestionsTable.frame = CGRect(
            x: frameInView.minX,
            y: frameInView.maxY + AppDesign.Spacing.xxs,
            width: frameInView.width,
            height: 220
        )
        suggestionsTable.isHidden = false
        view.insertSubview(suggestionsTable, aboveSubview: containerCard)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTable.reloadData()
        
        let hasResults = !searchResults.isEmpty
        suggestionsTable.isHidden = !hasResults
        suggestionsTable.isUserInteractionEnabled = hasResults
    }

    // MARK: - Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HomeSuggestCell")
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let request = MKLocalSearch.Request(completion: result)
        
        homeAddressTextField.text = result.title
        suggestionsTable.isHidden = true
        view.endEditing(true)
        
        MKLocalSearch(request: request).start { [weak self] response, error in
            guard let self = self, let item = response?.mapItems.first else { return }
            DispatchQueue.main.async {
                let name = item.name ?? result.title
                self.homeLocation = LocationPoint(lat: item.placemark.coordinate.latitude, lon: item.placemark.coordinate.longitude, address: name)
                self.refreshSummary()
            }
        }
    }

    // MARK: - Actions
    @IBAction func completeSetupTapped(_ sender: UIButton) {
        if isEditingMode {
            if let home = homeLocation {
                UserDataModel.shared.setHomeLocations([home])
            }
            navigationController?.popViewController(animated: true)
        } else {
            // End of Onboarding: build user and register
            if let home = homeLocation {
                RegistrationBuilder.shared.homeLocation = home
            }
            commitRegistrationAndFinish()
        }
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        if isEditingMode {
            navigationController?.popViewController(animated: true)
        } else {
            commitRegistrationAndFinish()
        }
    }
    
    private func commitRegistrationAndFinish() {
        do {
            let finalUser = try RegistrationBuilder.shared.buildUser()
            UserDataModel.shared.registerNewUser(profile: finalUser)
            RegistrationBuilder.shared.reset()
            AppHaptics.success()
            goToTabBar()
        } catch {
            showAlert("Missing Information", error.localizedDescription)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func goToTabBar() {
        let tabBar = storyboard?.instantiateViewController(identifier: "MainTabBarController") as! UITabBarController
        navigationController?.setViewControllers([tabBar], animated: true)
    }

    private func configureAccessibility() {
        homeAddressTextField.accessibilityLabel = "Home address"
        homeAddressTextField.accessibilityHint = "Search and select your home location"
        completeSetupButton.accessibilityLabel = isEditingMode ? "Save location" : "Complete setup"
        completeSetupButton.accessibilityHint = isEditingMode ? "Save your updated home location" : "Finish account setup and go to home"
    }
}
