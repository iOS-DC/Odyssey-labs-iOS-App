import UIKit

final class TripBookingViewController: UIViewController {

    private let trip: Trip
    private var travelerCount = 1
    private var discountAmount = 0
    private let couponCode = "SAVE500"
    private let discountValue = 500

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let tripCard = UIView()
    private let tripThumb = UIImageView()
    private let tripTitleLabel = UILabel()
    private let tripLocationLabel = UILabel()
    private let tripDateLabel = UILabel()

    private let countLabel = UILabel()
    private let pricePerPersonLabel = UILabel()
    private let subtotalLabel = UILabel()

    private let couponField = UITextField()
    private let couponHintLabel = UILabel()
    private let applyButton = UIButton(type: .system)

    private let breakdownSubtotalLabel = UILabel()
    private let breakdownDiscountLabel = UILabel()
    private let breakdownTotalLabel = UILabel()

    private let continueButton = UIButton(type: .system)

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Booking"
        view.backgroundColor = AppDesign.Color.groupedBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        build()
        updatePrices()
    }

    // MARK: - Price updates

    private func updatePrices() {
        let subtotal = trip.price * travelerCount
        let total = subtotal - discountAmount
        let personText = travelerCount == 1 ? "1 person" : "\(travelerCount) people"

        countLabel.text = "\(travelerCount)"
        pricePerPersonLabel.text = trip.priceFormatted
        subtotalLabel.text = formatPrice(subtotal)
        breakdownSubtotalLabel.text = formatPrice(subtotal)

        if discountAmount > 0 {
            breakdownDiscountLabel.isHidden = false
            breakdownDiscountLabel.text = "-₹\(discountAmount)"
        } else {
            breakdownDiscountLabel.isHidden = true
        }

        let totalAttr = NSAttributedString(
            string: formatPrice(total),
            attributes: [
                .foregroundColor: AppDesign.Color.primary,
                .font: UIFont.systemFont(ofSize: 18, weight: .bold)
            ]
        )
        breakdownTotalLabel.attributedText = totalAttr

        // Find the subtotal row's value label and update it
        _ = personText
    }

    private func formatPrice(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let f = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "₹\(f)"
    }

    // MARK: - Actions

    @objc private func decreaseTapped() {
        guard travelerCount > 1 else { return }
        travelerCount -= 1
        updatePrices()
    }

    @objc private func increaseTapped() {
        guard travelerCount < trip.spotsLeft else { return }
        travelerCount += 1
        updatePrices()
    }

    @objc private func applyTapped() {
        let entered = couponField.text?.trimmingCharacters(in: .whitespaces).uppercased() ?? ""
        if entered == couponCode {
            discountAmount = discountValue
            applyButton.configuration?.title = "Applied ✓"
            applyButton.configuration?.baseBackgroundColor = .systemGreen
            applyButton.isEnabled = false
            couponField.isEnabled = false
        } else {
            couponHintLabel.text = "Invalid code. Try: \(couponCode)"
            couponHintLabel.textColor = .systemRed
        }
        updatePrices()
    }

    @objc private func continueTapped() {
        let alert = UIAlertController(
            title: "Booking Confirmed!",
            message: "Your spot for \(trip.title) is reserved. You'll receive a confirmation shortly.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Build UI

    private func build() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -100),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        contentStack.addArrangedSubview(buildTripCard())
        contentStack.addArrangedSubview(buildTravelersCard())
        contentStack.addArrangedSubview(buildCouponCard())
        contentStack.addArrangedSubview(buildPriceBreakdownCard())

        // Sticky continue button
        let bottomBar = UIView()
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        var continueCfg = UIButton.Configuration.filled()
        continueCfg.title = "Continue"
        continueCfg.baseForegroundColor = .white
        continueCfg.baseBackgroundColor = AppDesign.Color.primary
        continueCfg.cornerStyle = .capsule
        continueCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.systemFont(ofSize: 17, weight: .semibold); return a
        }
        continueButton.configuration = continueCfg
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        bottomBar.addSubview(continueButton)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 90),

            continueButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            continueButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: AppDesign.Size.buttonHeight),
        ])
    }

    private func buildTripCard() -> UIView {
        let card = makeCard()
        tripThumb.loadImage(from: trip.imageName)
        tripThumb.contentMode = .scaleAspectFill
        tripThumb.clipsToBounds = true
        tripThumb.layer.cornerRadius = AppDesign.Radius.sm
        tripThumb.backgroundColor = .systemGray5
        tripThumb.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(tripThumb)

        tripTitleLabel.text = trip.title
        tripTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        tripTitleLabel.textColor = .label

        tripLocationLabel.text = trip.location
        tripLocationLabel.font = UIFont.systemFont(ofSize: 14)
        tripLocationLabel.textColor = .secondaryLabel

        tripDateLabel.text = trip.dateRange
        tripDateLabel.font = UIFont.systemFont(ofSize: 14)
        tripDateLabel.textColor = .secondaryLabel

        let labelStack = UIStackView(arrangedSubviews: [tripTitleLabel, tripLocationLabel, tripDateLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(labelStack)

        NSLayoutConstraint.activate([
            tripThumb.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            tripThumb.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            tripThumb.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16),
            tripThumb.widthAnchor.constraint(equalToConstant: 72),
            tripThumb.heightAnchor.constraint(equalToConstant: 72),

            labelStack.centerYAnchor.constraint(equalTo: tripThumb.centerYAnchor),
            labelStack.leadingAnchor.constraint(equalTo: tripThumb.trailingAnchor, constant: 12),
            labelStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            labelStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func buildTravelersCard() -> UIView {
        let card = makeCard()
        let heading = makeHeading("Number of People")
        card.addSubview(heading)

        // Traveler row
        let travelerRowLabel = UILabel()
        travelerRowLabel.text = "Travelers"
        travelerRowLabel.font = UIFont.systemFont(ofSize: 15)
        travelerRowLabel.textColor = .secondaryLabel

        let minusButton = UIButton(type: .system)
        minusButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusButton.tintColor = UIColor.systemGray3
        minusButton.addTarget(self, action: #selector(decreaseTapped), for: .touchUpInside)
        minusButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        minusButton.heightAnchor.constraint(equalToConstant: 36).isActive = true

        countLabel.text = "1"
        countLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        countLabel.textAlignment = .center
        countLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true

        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusButton.tintColor = AppDesign.Color.primary
        plusButton.addTarget(self, action: #selector(increaseTapped), for: .touchUpInside)
        plusButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let stepperStack = UIStackView(arrangedSubviews: [minusButton, countLabel, plusButton])
        stepperStack.axis = .horizontal
        stepperStack.spacing = 8
        stepperStack.alignment = .center

        let travelerRow = UIStackView(arrangedSubviews: [travelerRowLabel, UIView(), stepperStack])
        travelerRow.axis = .horizontal
        travelerRow.alignment = .center
        travelerRow.translatesAutoresizingMaskIntoConstraints = false

        let divider = makeDivider()

        let priceRow = makePriceRow(label: "Price per person", valueLabel: pricePerPersonLabel)
        let subtotalRow = makePriceRow(label: "Subtotal", valueLabel: subtotalLabel)
        subtotalLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)

        let stack = UIStackView(arrangedSubviews: [heading, travelerRow, divider, priceRow, subtotalRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func buildCouponCard() -> UIView {
        let card = makeCard()
        let heading = makeHeading("Have a Coupon?")

        couponField.placeholder = "Enter code"
        couponField.borderStyle = .none
        couponField.font = UIFont.systemFont(ofSize: 15)
        couponField.autocapitalizationType = .allCharacters
        couponField.leftView = UIImageView(image: UIImage(systemName: "tag"))
        couponField.leftView?.tintColor = .secondaryLabel
        couponField.leftViewMode = .always
        couponField.backgroundColor = UIColor.systemGray6
        couponField.layer.cornerRadius = AppDesign.Radius.sm
        couponField.heightAnchor.constraint(equalToConstant: 46).isActive = true

        if let leftView = couponField.leftView {
            leftView.frame = CGRect(x: 0, y: 0, width: 36, height: 20)
        }

        var applyCfg = UIButton.Configuration.filled()
        applyCfg.title = "Apply"
        applyCfg.baseForegroundColor = .white
        applyCfg.baseBackgroundColor = AppDesign.Color.primary
        applyCfg.cornerStyle = .medium
        applyCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        applyButton.configuration = applyCfg
        applyButton.widthAnchor.constraint(equalToConstant: 86).isActive = true
        applyButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)

        let fieldRow = UIStackView(arrangedSubviews: [couponField, applyButton])
        fieldRow.axis = .horizontal
        fieldRow.spacing = 8
        fieldRow.alignment = .fill

        couponHintLabel.text = "Try code: \(couponCode)"
        couponHintLabel.font = UIFont.systemFont(ofSize: 13)
        couponHintLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [heading, fieldRow, couponHintLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func buildPriceBreakdownCard() -> UIView {
        let card = makeCard()
        let heading = makeHeading("Price Breakdown")

        let subtotalRowLabel = UILabel()
        subtotalRowLabel.text = "Subtotal"
        subtotalRowLabel.font = UIFont.systemFont(ofSize: 15)
        subtotalRowLabel.textColor = .secondaryLabel

        breakdownSubtotalLabel.font = UIFont.systemFont(ofSize: 15)
        breakdownSubtotalLabel.textColor = .label
        breakdownSubtotalLabel.textAlignment = .right

        let subtotalRow = UIStackView(arrangedSubviews: [subtotalRowLabel, UIView(), breakdownSubtotalLabel])
        subtotalRow.axis = .horizontal
        subtotalRow.alignment = .center

        let discountRowLabel = UILabel()
        discountRowLabel.text = "Discount"
        discountRowLabel.font = UIFont.systemFont(ofSize: 15)
        discountRowLabel.textColor = .secondaryLabel

        breakdownDiscountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        breakdownDiscountLabel.textColor = .systemGreen
        breakdownDiscountLabel.textAlignment = .right
        breakdownDiscountLabel.isHidden = true

        let discountRow = UIStackView(arrangedSubviews: [discountRowLabel, UIView(), breakdownDiscountLabel])
        discountRow.axis = .horizontal
        discountRow.alignment = .center

        let divider = makeDivider()

        let totalRowLabel = UILabel()
        totalRowLabel.text = "Total Amount"
        totalRowLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        totalRowLabel.textColor = .label

        breakdownTotalLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        breakdownTotalLabel.textColor = AppDesign.Color.primary
        breakdownTotalLabel.textAlignment = .right

        let totalRow = UIStackView(arrangedSubviews: [totalRowLabel, UIView(), breakdownTotalLabel])
        totalRow.axis = .horizontal
        totalRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [heading, subtotalRow, discountRow, divider, totalRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = AppDesign.Radius.lg
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = AppDesign.Shadow.smallCardOpacity
        v.layer.shadowOffset = AppDesign.Shadow.smallCardOffset
        v.layer.shadowRadius = AppDesign.Shadow.smallCardRadius
        return v
    }

    private func makeHeading(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        l.textColor = .label
        return l
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func makePriceRow(label: String, valueLabel: UILabel) -> UIView {
        let l = UILabel()
        l.text = label
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel

        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [l, UIView(), valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }
}
