import UIKit

class CategoryViewController: UIViewController {

    private let categoryId: String
    private let campaignId: String
    private let messageId: String

    // UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let categoryIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let categoryDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let campaignInfoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Campaign Info:"
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let campaignInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let productsLabel: UILabel = {
        let label = UILabel()
        label.text = "Products in this category"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let productStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back to Home", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initialization

    init(categoryId: String, campaignId: String = "", messageId: String = "") {
        self.categoryId = categoryId
        self.campaignId = campaignId
        self.messageId = messageId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        LogHelper.debug("CategoryViewController loaded with categoryId: \(categoryId)")

        setupUI()
        updateCategoryInfo()
        setupProductItems()
        setupActions()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(categoryIdLabel)
        contentView.addSubview(categoryNameLabel)
        contentView.addSubview(categoryDescriptionLabel)
        contentView.addSubview(campaignInfoTitleLabel)
        contentView.addSubview(campaignInfoLabel)
        contentView.addSubview(productsLabel)
        contentView.addSubview(productStackView)
        contentView.addSubview(shareButton)
        contentView.addSubview(backButton)

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Category ID
            categoryIdLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            categoryIdLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryIdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Category Name
            categoryNameLabel.topAnchor.constraint(equalTo: categoryIdLabel.bottomAnchor, constant: 16),
            categoryNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Category Description
            categoryDescriptionLabel.topAnchor.constraint(equalTo: categoryNameLabel.bottomAnchor, constant: 8),
            categoryDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Campaign Info Title
            campaignInfoTitleLabel.topAnchor.constraint(equalTo: categoryDescriptionLabel.bottomAnchor, constant: 24),
            campaignInfoTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            campaignInfoTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Campaign Info
            campaignInfoLabel.topAnchor.constraint(equalTo: campaignInfoTitleLabel.bottomAnchor, constant: 4),
            campaignInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            campaignInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Products Label
            productsLabel.topAnchor.constraint(equalTo: campaignInfoLabel.bottomAnchor, constant: 24),
            productsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Product Stack
            productStackView.topAnchor.constraint(equalTo: productsLabel.bottomAnchor, constant: 16),
            productStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Share Button
            shareButton.topAnchor.constraint(equalTo: productStackView.bottomAnchor, constant: 24),
            shareButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shareButton.heightAnchor.constraint(equalToConstant: 50),

            // Back Button
            backButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            backButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    private func setupProductItems() {
        let products = [
            ("PROD001", "📱 Sample Product 001 - Click to view details"),
            ("PROD002", "💻 Sample Product 002 - Click to view details"),
            ("PROD003", "⌚ Sample Product 003 - Click to view details")
        ]

        for (productId, title) in products {
            let card = createProductCard(productId: productId, title: title)
            productStackView.addArrangedSubview(card)
        }
    }

    private func createProductCard(productId: String, title: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(productCardTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = Int(productId.replacingOccurrences(of: "PROD", with: "")) ?? 0

        return containerView
    }

    private func setupActions() {
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    private func updateCategoryInfo() {
        categoryIdLabel.text = "Category ID: \(categoryId)"
        categoryNameLabel.text = "Category: \(categoryId)"
        categoryDescriptionLabel.text = "Browse products in the \(categoryId) category"

        if !campaignId.isEmpty {
            campaignInfoLabel.text = "Campaign: \(campaignId), Message: \(messageId)"
        } else {
            campaignInfoLabel.text = "Opened directly (not from push notification)"
        }

        LogHelper.debug("Category details loaded - ID: \(categoryId), Campaign: \(campaignId), Message: \(messageId)")
    }

    // MARK: - Actions

    @objc private func productCardTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        let productId = String(format: "PROD%03d", tag)

        LogHelper.debug("Product card tapped: \(productId)")

        guard let deepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            return
        }

        // Navigate to product detail
        if let url = URL(string: "\(deepLinkScheme)://product/\(productId)") {
            NotificationCenter.default.post(name: NSNotification.Name("OpenDeepLink"), object: nil, userInfo: ["url": url])
        }
    }

    @objc private func shareButtonTapped() {
        guard let deepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            return
        }

        let shareText = "Check out this category: \(deepLinkScheme)://category/\(categoryId)"
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        // For iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.sourceRect = shareButton.bounds
        }

        present(activityViewController, animated: true)
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true) {
            LogHelper.debug("CategoryViewController dismissed")
        }
    }
}
