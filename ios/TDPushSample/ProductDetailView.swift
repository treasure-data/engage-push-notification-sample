import UIKit

class ProductDetailViewController: UIViewController {

    private let productId: String
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
        label.text = "Product Details"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "cube.box.fill")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let productIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let productNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let productDescriptionLabel: UILabel = {
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

    init(productId: String, campaignId: String = "", messageId: String = "") {
        self.productId = productId
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

        LogHelper.debug("ProductDetailViewController loaded with productId: \(productId)")

        setupUI()
        updateProductInfo()
        setupActions()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(productImageView)
        contentView.addSubview(productIdLabel)
        contentView.addSubview(productNameLabel)
        contentView.addSubview(productDescriptionLabel)
        contentView.addSubview(campaignInfoTitleLabel)
        contentView.addSubview(campaignInfoLabel)
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

            // Product Image
            productImageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            productImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 200),
            productImageView.heightAnchor.constraint(equalToConstant: 200),

            // Product ID
            productIdLabel.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: 24),
            productIdLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productIdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Product Name
            productNameLabel.topAnchor.constraint(equalTo: productIdLabel.bottomAnchor, constant: 16),
            productNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Product Description
            productDescriptionLabel.topAnchor.constraint(equalTo: productNameLabel.bottomAnchor, constant: 8),
            productDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Campaign Info Title
            campaignInfoTitleLabel.topAnchor.constraint(equalTo: productDescriptionLabel.bottomAnchor, constant: 24),
            campaignInfoTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            campaignInfoTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Campaign Info
            campaignInfoLabel.topAnchor.constraint(equalTo: campaignInfoTitleLabel.bottomAnchor, constant: 4),
            campaignInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            campaignInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Share Button
            shareButton.topAnchor.constraint(equalTo: campaignInfoLabel.bottomAnchor, constant: 24),
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

    private func setupActions() {
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    private func updateProductInfo() {
        productIdLabel.text = "Product ID: \(productId)"
        productNameLabel.text = "Product \(productId)"
        productDescriptionLabel.text = "This is a sample product with ID: \(productId). Deep link navigation successful!"

        if !campaignId.isEmpty {
            campaignInfoLabel.text = "Campaign: \(campaignId), Message: \(messageId)"
        } else {
            campaignInfoLabel.text = "Opened directly (not from push notification)"
        }

        LogHelper.debug("Product details loaded - ID: \(productId), Campaign: \(campaignId), Message: \(messageId)")
    }

    // MARK: - Actions

    @objc private func shareButtonTapped() {
        guard let deepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            return
        }

        let shareText = "Check out this product: \(deepLinkScheme)://product/\(productId)"
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
            LogHelper.debug("ProductDetailViewController dismissed")
        }
    }
}
