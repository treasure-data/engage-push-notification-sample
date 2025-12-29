import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // Load allowlist from Info.plist
    private lazy var allowedDeepLinkHosts: Set<String> = {
        guard let hosts = Bundle.main.object(forInfoDictionaryKey: "TDAllowedDeepLinkHosts") as? [String] else {
            LogHelper.error("TDAllowedDeepLinkHosts not configured in Info.plist")
            return []
        }
        return Set(hosts)
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()

        // Handle deep link from notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeepLink(_:)), name: NSNotification.Name("OpenDeepLink"), object: nil)

        // Handle deep link if app was opened via URL (direct deep link, no campaign data)
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(url: urlContext.url, deepLink: urlContext.url.absoluteString, campaignId: "", messageId: "")
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        // Direct deep link (no campaign data available)
        handleDeepLink(url: url, deepLink: url.absoluteString, campaignId: "", messageId: "")
    }

    @objc private func handleDeepLink(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? URL else { return }

        let deepLink = userInfo["deepLink"] as? String ?? url.absoluteString
        let campaignId = userInfo["campaign_id"] as? String ?? ""
        let messageId = userInfo["message_id"] as? String ?? ""

        handleDeepLink(url: url, deepLink: deepLink, campaignId: campaignId, messageId: messageId)
    }

    private func handleDeepLink(url: URL, deepLink: String, campaignId: String, messageId: String) {
        LogHelper.debug("🔗 Deep link opened: \(url)")

        // Get configured deep link scheme from Info.plist
        guard let deepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "invalid_link")
            return
        }

        // Validate scheme
        guard url.scheme == deepLinkScheme else {
            LogHelper.warning("⚠️ Invalid deep link scheme: \(url.scheme ?? "nil"), expected: \(deepLinkScheme)")
            TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "invalid_link")
            return
        }

        // Validate deep link host against allowlist
        guard let host = url.host, allowedDeepLinkHosts.contains(host) else {
            LogHelper.warning("⚠️ Unknown or invalid deep link host: \(url.host ?? "nil")")
            TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "unknown_path")
            return
        }

        // Get the root view controller
        guard let rootViewController = window?.rootViewController else {
            LogHelper.error("Root view controller not found")
            return
        }

        // Log deep link details as JSON
        do {
            let deepLinkInfo: [String: Any] = [
                "url": url.absoluteString,
                "scheme": url.scheme ?? NSNull(),
                "host": url.host ?? NSNull(),
                "path": url.path,
                "pathComponents": url.pathComponents
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: deepLinkInfo, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                LogHelper.debug("Deep Link Info (JSON):\n\(jsonString)")
            }
        } catch {
            LogHelper.error("Error formatting deep link as JSON", error: error)
        }

        // Routing based on host and path
        switch url.host {
        case "product":
            // Navigate to product detail
            if let productId = url.pathComponents.last, productId != "/", !productId.isEmpty {
                LogHelper.debug("📦 Navigating to product: \(productId)")

                let productDetailVC = ProductDetailViewController(productId: productId)
                productDetailVC.modalPresentationStyle = .fullScreen
                rootViewController.present(productDetailVC, animated: true) {
                    LogHelper.debug("ProductDetailViewController presented")
                    // Track successful arrival
                    TrackingService.shared.trackLinkArriveEvent(link: deepLink, campaignId: campaignId, messageId: messageId)
                }
            } else {
                LogHelper.warning("Product ID not found in URL: \(url)")
                TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "invalid_link")
            }

        case "category":
            // Navigate to category
            if let categoryId = url.pathComponents.last, categoryId != "/", !categoryId.isEmpty {
                LogHelper.debug("🏷️ Navigating to category: \(categoryId)")

                let categoryVC = CategoryViewController(categoryId: categoryId)
                categoryVC.modalPresentationStyle = .fullScreen
                rootViewController.present(categoryVC, animated: true) {
                    LogHelper.debug("CategoryViewController presented")
                    // Track successful arrival
                    TrackingService.shared.trackLinkArriveEvent(link: deepLink, campaignId: campaignId, messageId: messageId)
                }
            } else {
                LogHelper.warning("Category ID not found in URL: \(url)")
                TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "invalid_link")
            }

        case "home":
            // Navigate to home (dismiss any presented view controllers)
            LogHelper.debug("🏠 Navigating to home")
            rootViewController.dismiss(animated: true) {
                LogHelper.debug("Dismissed to home")
                // Track successful arrival
                TrackingService.shared.trackLinkArriveEvent(link: deepLink, campaignId: campaignId, messageId: messageId)
            }

        default:
            LogHelper.warning("⚠️ Unknown deep link host: \(url.host ?? "nil")")
            TrackingService.shared.trackLinkFailEvent(link: deepLink, campaignId: campaignId, messageId: messageId, reason: "unknown_path")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Clear badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
