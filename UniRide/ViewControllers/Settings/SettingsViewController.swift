// SettingsViewController.swift
// UniRide
// App settings: notifications, appearance, data, account, and about.

import UIKit
import SafariServices

final class SettingsViewController: UIViewController {

    // MARK: - Data

    private struct SettingItem {
        let icon: String
        let title: String
        let subtitle: String?
        let tintColor: UIColor
        var toggle: Bool?
        let action: (() -> Void)?
    }

    private struct SettingSection {
        let header: String
        var items: [SettingItem]
    }

    private var sections: [SettingSection] = []

    // MARK: - UI

    @IBOutlet private var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = AppDesign.Color.groupedBackground
        navigationItem.largeTitleDisplayMode = .never
        buildSections()
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.backgroundColor = AppDesign.Color.groupedBackground
    }

    // MARK: - Build Sections

    private func buildSections() {
        let me = UserDataModel.shared.getCurrentUser()

        // ACCOUNT
        sections = [
            SettingSection(header: "Account", items: [
                SettingItem(icon: "person.crop.circle.fill",
                            title: me?.fullName.isEmpty == false ? me!.fullName : "Your Profile",
                            subtitle: me?.email,
                            tintColor: AppDesign.Color.primary,
                            action: { [weak self] in self?.openEditProfile() }),

                SettingItem(icon: "checkmark.seal.fill",
                            title: "Email Verified",
                            subtitle: me?.isEmailVerified == true ? "Your account is verified" : "Not verified",
                            tintColor: me?.isEmailVerified == true ? AppDesign.Color.success : AppDesign.Color.warning,
                            action: nil)
            ]),

            // NOTIFICATIONS
            SettingSection(header: "Notifications", items: [
                SettingItem(icon: "bell.badge.fill",
                            title: "Push Notifications",
                            subtitle: "Get notified about ride requests, approvals, and messages",
                            tintColor: AppDesign.Color.primary,
                            toggle: true,
                            action: nil),

                SettingItem(icon: "bell.slash.fill",
                            title: "Manage in Settings",
                            subtitle: "Open iOS notification settings",
                            tintColor: .secondaryLabel,
                            action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            })
            ]),

            // PRIVACY & DATA
            SettingSection(header: "Privacy & Data", items: [
                SettingItem(icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            subtitle: nil,
                            tintColor: AppDesign.Color.primary,
                            action: { [weak self] in
                                self?.openURL("https://krishbahukhandi.github.io/UniRide_Website/index.html#privacy")
                            }),

                SettingItem(icon: "doc.text.fill",
                            title: "Terms of Service",
                            subtitle: nil,
                            tintColor: AppDesign.Color.primary,
                            action: { [weak self] in
                                self?.openURL("https://krishbahukhandi.github.io/UniRide_Website/terms.html")
                            }),

                SettingItem(icon: "questionmark.circle.fill",
                            title: "Support",
                            subtitle: "Help center and contact information",
                            tintColor: AppDesign.Color.primary,
                            action: { [weak self] in
                                self?.openURL("https://krishbahukhandi.github.io/UniRide_Website/support.html")
                            })
            ]),

            // ABOUT
            SettingSection(header: "About", items: [
                SettingItem(icon: "info.circle.fill",
                            title: "Version",
                            subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
                            tintColor: .secondaryLabel,
                            action: nil),

                SettingItem(icon: "star.fill",
                            title: "Rate UniRide",
                            subtitle: "If you're enjoying the app",
                            tintColor: .systemYellow,
                            action: { [weak self] in
                                self?.openURL("https://apps.apple.com/us/app/uniride/id6760745418")
                            })
            ]),

            // DANGER ZONE
            SettingSection(header: "Danger Zone", items: [
                SettingItem(icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            subtitle: nil,
                            tintColor: AppDesign.Color.destructive,
                            action: { [weak self] in self?.signOut() }),

                SettingItem(icon: "person.crop.circle.badge.xmark",
                            title: "Delete Account",
                            subtitle: "Permanently remove your account and data",
                            tintColor: AppDesign.Color.destructive,
                            action: { [weak self] in self?.deleteAccount() })
            ])
        ]
    }

    // MARK: - Actions

    private func openEditProfile() {
        let sb = UIStoryboard(name: "EditProfile", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func clearCache() {
        let alert = UIAlertController(
            title: "Clear Cache?",
            message: "This removes locally saved rides and messages. Your account won't be affected.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let files = (try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)) ?? []
            files.filter { $0.pathExtension == "json" }.forEach { try? FileManager.default.removeItem(at: $0) }
            AppHaptics.impact(.medium)
        })
        present(alert, animated: true)
    }

    private func exportData() {
        guard let me = UserDataModel.shared.getCurrentUser() else { return }
        var dict: [String: Any] = [
            "id":        me.id.uuidString,
            "email":     me.email,
            "full_name": me.fullName,
            "role":      me.role?.rawValue ?? "",
            "course":    me.courseName ?? "",
            "exported_at": ISO8601DateFormatter().string(from: Date())
        ]
        if let phone = me.phone { dict["phone"] = phone }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else { return }

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("uniride_data_export.json")
        try? json.write(to: tmp, atomically: true, encoding: .utf8)

        let sheet = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
        presentPopoverCentered(sheet)
    }

    private func deleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account?",
            message: "This removes your account, rides, and all data permanently. This can't be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete My Account", style: .destructive) { [weak self] _ in
            guard let self else { return }
            
            // Show simple loading alert
            let loading = UIAlertController(title: "Deleting Account…", message: "Please wait…", preferredStyle: .alert)
            self.present(loading, animated: true)
            
            Task { @MainActor in
                do {
                    // 1. Try server-side account deletion via RPC
                    try await AuthService.shared.deleteAccount()
                    
                    // 2. Perform local logout cleanup
                    UserDataModel.shared.logout()
                    AppHaptics.impact(.heavy)
                    
                    // Dismiss loading and exit
                    loading.dismiss(animated: true) {
                        self.navigateToLogin()
                    }
                } catch {
                    // Fallback: If server deletion fails, alert the user but don't just log out
                    loading.dismiss(animated: true) {
                        let errorAlert = UIAlertController(
                            title: "Deletion Failed",
                            message: "We couldn't delete your account. Try again or contact support.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func navigateToLogin() {
        let sb      = UIStoryboard(name: "Main", bundle: nil)
        let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
        let nav     = UINavigationController(rootViewController: emailVC)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = AppDesign.Color.primary
        present(safariVC, animated: true)
    }

    private func signOut() {
        let alert = UIAlertController(title: "Sign Out?", message: "You'll need to sign in again to access your rides.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            Task { @MainActor in
                try? await AuthService.shared.signOut()
                UserDataModel.shared.logout()
                let sb      = UIStoryboard(name: "Main", bundle: nil)
                let emailVC = sb.instantiateViewController(withIdentifier: "EmailViewController")
                let nav     = UINavigationController(rootViewController: emailVC)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController = nav
                    window.makeKeyAndVisible()
                }
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header.isEmpty ? nil : sections[section].header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)

        var config = UIListContentConfiguration.valueCell()
        config.text = item.title
        config.secondaryText = item.subtitle
        config.image = UIImage(systemName: item.icon)
        config.imageProperties.tintColor = item.tintColor
        cell.contentConfiguration = config
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default

        if item.toggle != nil {
            let sw = UISwitch()
            sw.isOn = item.toggle == true
            sw.onTintColor = AppDesign.Color.primary
            cell.accessoryView = sw
            cell.selectionStyle = .none
        } else if item.action != nil {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].items[indexPath.row].action?()
    }
}
