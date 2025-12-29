import UIKit
import FirebaseMessaging

class ViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Treasure Data\nPush Sample"
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tokenLabel: UILabel = {
        let label = UILabel()
        label.text = "FCM Token: Loading..."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to receive notifications"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let eventCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Queued Events: 0"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Refresh Token", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload Events Now", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupViews()
        updateTokenLabel()
        updateEventCount()

        refreshButton.addTarget(self, action: #selector(refreshToken), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadEvents), for: .touchUpInside)

        // Update event count periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateEventCount()
        }
    }

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(tokenLabel)
        view.addSubview(statusLabel)
        view.addSubview(eventCountLabel)
        view.addSubview(refreshButton)
        view.addSubview(uploadButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tokenLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tokenLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tokenLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            eventCountLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            eventCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            refreshButton.topAnchor.constraint(equalTo: eventCountLabel.bottomAnchor, constant: 30),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            uploadButton.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 20),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func updateTokenLabel() {
        if let token = Messaging.messaging().fcmToken {
            let shortToken = String(token.prefix(20)) + "..."
            tokenLabel.text = "FCM Token: \(shortToken)"
        } else {
            tokenLabel.text = "FCM Token: Not available"
        }
    }

    private func updateEventCount() {
        let count = EventQueue.shared.count()
        eventCountLabel.text = "Queued Events: \(count)"
    }

    @objc private func refreshToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error)")
                self.statusLabel.text = "Error fetching token"
                return
            }

            if let token = token {
                print("🔑 FCM token: \(token)")
                FCMTokenService.shared.registerToken(token: token)
                self.updateTokenLabel()
                self.statusLabel.text = "Token refreshed successfully"
            }
        }
    }

    @objc private func uploadEvents() {
        statusLabel.text = "Uploading events..."
        PushEventUploader.shared.uploadEvents { success in
            DispatchQueue.main.async {
                if success {
                    self.statusLabel.text = "Events uploaded successfully"
                } else {
                    self.statusLabel.text = "Upload failed - check logs"
                }
            }
        }
    }
}
