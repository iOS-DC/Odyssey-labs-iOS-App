//
//  OnboardingViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 10/11/25.
//

import UIKit

struct OnboardingSlide {
    let imageName: String
    let title: String
    let subtitle: String
}

class OnboardingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nextButton: UIButton!

    private let slides: [OnboardingSlide] = [
        .init(imageName: "onboard_1",
              title: "Find rides with your college community",
              subtitle: "Connect with fellow students for safe, affordable rides"),
        .init(imageName: "onboard_2",
              title: "Save money & help the planet",
              subtitle: "Split costs and reduce carbon footprint together"),
        .init(imageName: "onboard_3",
              title: "Stay safe with verified profiles",
              subtitle: "All members verified through college email")
    ]

    private var index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applySlide(animated: false)
    }

    private func setupUI() {
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        nextButton.layer.cornerRadius = 12
        nextButton.clipsToBounds = true
    }

    private func applySlide(animated: Bool) {
        let slide = slides[index]
        pageControl.currentPage = index
        nextButton.setTitle(index == slides.count - 1 ? "Get Started" : "Next", for: .normal)

        let update = {
            self.imageView.image = UIImage(named: slide.imageName)
            self.titleLabel.text = slide.title
            self.subtitleLabel.text = slide.subtitle
        }

        if animated {
            UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve, animations: update, completion: nil)
        } else {
            update()
        }
    }

    @IBAction func nextTapped(_ sender: UIButton) {
        if index < slides.count - 1 {
            index += 1
            applySlide(animated: true)
        } else {
            finishOnboarding()
        }
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        finishOnboarding()
    }

    @IBAction func pageChanged(_ sender: UIPageControl) {
        index = sender.currentPage
        applySlide(animated: true)
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let email = sb.instantiateViewController(withIdentifier: "EmailViewController")
        let nav = UINavigationController(rootViewController: email)

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }


}
