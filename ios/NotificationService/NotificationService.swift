import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Download and attach image if present
        if let imageUrlString = request.content.userInfo["image"] as? String,
           let imageUrl = URL(string: imageUrlString) {

            print("🖼️ Downloading notification image: \(imageUrlString)")

            downloadImage(from: imageUrl) { attachment in
                if let attachment = attachment {
                    bestAttemptContent.attachments = [attachment]
                    print("✅ Image attached to notification")
                } else {
                    print("❌ Failed to download/attach image")
                }

                contentHandler(bestAttemptContent)
            }
        } else {
            // No image to download
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Image Download

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location, error == nil else {
                print("❌ Image download error: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }

            // Get file extension
            let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let fileName = "\(UUID().uuidString).\(fileExtension)"
            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            let fileUrl = tempDirectory.appendingPathComponent(fileName)

            do {
                // Move downloaded file to temp directory
                try FileManager.default.moveItem(at: location, to: fileUrl)

                // Create attachment
                let attachment = try UNNotificationAttachment(identifier: fileName, url: fileUrl, options: nil)
                completion(attachment)
            } catch {
                print("❌ Error creating attachment: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }
}
