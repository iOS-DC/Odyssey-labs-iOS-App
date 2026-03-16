import UIKit

final class ProfilePhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI Elements
    private let containerCard = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let selectButton = UIButton()
    private let continueButton = UIButton()
    private let skipButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyOnboardingChrome(step: 5, total: 7)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateOnboardingEntrance([containerCard, titleLabel, subtitleLabel, continueButton, skipButton])
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Profile Photo"
        
        // Container
        containerCard.applyCardStyle()
        containerCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerCard)
        
        // Title
        titleLabel.text = "Add a profile photo"
        titleLabel.font = AppDesign.Typography.h2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerCard.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Show your community who you are. This helps build trust for ride sharing."
        subtitleLabel.font = AppDesign.Typography.subheadline
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerCard.addSubview(subtitleLabel)
        
        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.backgroundColor = AppDesign.Color.fieldBackground
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = AppDesign.Color.border
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.isUserInteractionEnabled = true
        containerCard.addSubview(avatarImageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectPhotoTapped))
        avatarImageView.addGestureRecognizer(tap)
        
        // Select Button
        selectButton.setTitle("Select Photo", for: .normal)
        selectButton.setTitleColor(AppDesign.Color.primary, for: .normal)
        selectButton.titleLabel?.font = AppDesign.Typography.bodyStrong
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
        containerCard.addSubview(selectButton)
        
        // Continue Button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.applyPrimaryButton(color: AppDesign.Color.primary)
        applyPrimaryOnboardingCTAStyle(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        view.addSubview(continueButton)
        
        // Skip Button
        skipButton.setTitle("Maybe Later", for: .normal)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.titleLabel?.font = AppDesign.Typography.subheadline
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            containerCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            containerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.md),
            containerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.md),
            
            titleLabel.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: AppDesign.Spacing.lg),
            titleLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: AppDesign.Spacing.md),
            titleLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -AppDesign.Spacing.md),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppDesign.Spacing.xs),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: AppDesign.Spacing.lg),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -AppDesign.Spacing.lg),
            
            avatarImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: AppDesign.Spacing.xl),
            avatarImageView.centerXAnchor.constraint(equalTo: containerCard.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),
            
            selectButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: AppDesign.Spacing.md),
            selectButton.centerXAnchor.constraint(equalTo: containerCard.centerXAnchor),
            selectButton.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -AppDesign.Spacing.xl),
            
            continueButton.topAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: AppDesign.Spacing.xl),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDesign.Spacing.md),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDesign.Spacing.md),
            
            skipButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: AppDesign.Spacing.md),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func selectPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        let alert = UIAlertController(title: "Choose Profile Photo", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true)
            })
        }
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func continueTapped() {
        RegistrationBuilder.shared.profileImage = avatarImageView.image != UIImage(systemName: "person.circle.fill") ? avatarImageView.image : nil
        navigateToStep6()
    }
    
    @objc private func skipTapped() {
        RegistrationBuilder.shared.profileImage = nil
        navigateToStep6()
    }
    
    private func navigateToStep6() {
        let main = UIStoryboard(name: "Main", bundle: nil)
        if let vc = main.instantiateViewController(withIdentifier: "ProfileStep2ViewController") as? ProfileStep2ViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let edited = info[.editedImage] as? UIImage {
            avatarImageView.image = edited
        } else if let original = info[.originalImage] as? UIImage {
            avatarImageView.image = original
        }
        picker.dismiss(animated: true)
    }
}
