import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import TreasureData_iOS_SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Load allowlists from Info.plist
    private lazy var allowedDeepLinkHosts: Set<String> = {
        guard let hosts = Bundle.main.object(forInfoDictionaryKey: "TDAllowedDeepLinkHosts") as? [String] else {
            LogHelper.error("TDAllowedDeepLinkHosts not configured in Info.plist")
            return []
        }
        return Set(hosts)
    }()

    private lazy var allowedDomains: Set<String> = {
        guard let domains = Bundle.main.object(forInfoDictionaryKey: "TDAllowedDomains") as? [String] else {
            LogHelper.error("TDAllowedDomains not configured in Info.plist")
            return []
        }
        return Set(domains)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase initialization
        FirebaseApp.configure()
        LogHelper.debug("Firebase initialized")

        // Initialize Treasure Data SDK
        // Read API key and endpoint from Info.plist
        if let tdWriteKey = Bundle.main.object(forInfoDictionaryKey: "TDWriteKey") as? String,
           let tdEndpoint = Bundle.main.object(forInfoDictionaryKey: "TDEndpoint") as? String,
           let tdDatabase = Bundle.main.object(forInfoDictionaryKey: "TDDatabase") as? String {
            TreasureData.initialize(withApiKey: tdWriteKey, apiEndpoint: tdEndpoint)
            TreasureData.sharedInstance().defaultDatabase = tdDatabase

            // Enable automatic data collection
            // These methods automatically append useful information to all events
            TreasureData.sharedInstance().enableAutoAppendUniqId()
            TreasureData.sharedInstance().enableAutoAppendModelInformation()
            TreasureData.sharedInstance().enableAutoAppendAppInformation()
            TreasureData.sharedInstance().enableAutoAppendLocaleInformation()

            LogHelper.debug("Treasure Data SDK initialized")
            LogHelper.debug("Database: \(tdDatabase)")
            LogHelper.debug("Endpoint: \(tdEndpoint)")
        } else {
            LogHelper.error("Treasure Data configuration missing in Info.plist")
        }

        // Set up FCM delegate
        Messaging.messaging().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                LogHelper.error("Notification permission error", error: error)
                return
            }
            LogHelper.debug("Notification permission granted: \(granted)")
        }

        application.registerForRemoteNotifications()

        // Register FCM token on app launch
        FCMTokenService.shared.registerToken()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        LogHelper.debug("APNs token registered")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LogHelper.error("Failed to register for remote notifications", error: error)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo
        let content = notification.request.content

        // Log complete notification payload as JSON
        LogHelper.debug("========== Notification Payload (Foreground - JSON) ==========")
        do {
            var payload: [String: Any] = [
                "requestIdentifier": notification.request.identifier,
                "threadIdentifier": content.threadIdentifier,
                "categoryIdentifier": content.categoryIdentifier,
                "title": content.title,
                "subtitle": content.subtitle,
                "body": content.body,
                "badge": content.badge?.stringValue ?? NSNull(),
                "sound": content.sound?.description ?? NSNull(),
                "launchImageName": content.launchImageName
            ]

            // Add userInfo
            if !userInfo.isEmpty {
                var userInfoDict: [String: Any] = [:]
                for (key, value) in userInfo {
                    userInfoDict["\(key)"] = "\(value)"
                }
                payload["userInfo"] = userInfoDict
            } else {
                payload["userInfo"] = NSNull()
            }

            // Add attachments
            if !content.attachments.isEmpty {
                var attachmentsArray: [[String: Any]] = []
                for attachment in content.attachments {
                    attachmentsArray.append([
                        "identifier": attachment.identifier,
                        "url": attachment.url.absoluteString,
                        "type": attachment.type.identifier
                    ])
                }
                payload["attachments"] = attachmentsArray
            } else {
                payload["attachments"] = []
            }

            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                LogHelper.debug(jsonString)
            }
        } catch {
            LogHelper.error("Error formatting notification payload as JSON", error: error)
        }
        LogHelper.debug("==============================================================")

        // Track delivery event
        trackDeliveryEvent(userInfo: userInfo)

        // Show notification even when app is in foreground
        completionHandler([[.banner, .sound, .badge]])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        let content = response.notification.request.content

        // Log complete notification payload as JSON
        LogHelper.debug("========== Notification Payload (Tapped - JSON) ==========")
        do {
            var payload: [String: Any] = [
                "actionIdentifier": response.actionIdentifier,
                "requestIdentifier": response.notification.request.identifier,
                "threadIdentifier": content.threadIdentifier,
                "categoryIdentifier": content.categoryIdentifier,
                "title": content.title,
                "subtitle": content.subtitle,
                "body": content.body
            ]

            // Add userInfo
            if !userInfo.isEmpty {
                var userInfoDict: [String: Any] = [:]
                for (key, value) in userInfo {
                    userInfoDict["\(key)"] = "\(value)"
                }
                payload["userInfo"] = userInfoDict
            } else {
                payload["userInfo"] = NSNull()
            }

            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                LogHelper.debug(jsonString)
            }
        } catch {
            LogHelper.error("Error formatting notification payload as JSON", error: error)
        }
        LogHelper.debug("==========================================================")

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            trackOpenEvent(userInfo: userInfo)
            handleNotificationTap(userInfo: userInfo)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            trackDismissEvent(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Event Tracking

    private func trackDeliveryEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "delivery",
            "campaign_id": userInfo["campaign_id"] as? String ?? "",
            "message_id": userInfo["message_id"] as? String ?? "",
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Delivery event added to Treasure Data SDK")
    }

    private func trackOpenEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "open",
            "campaign_id": userInfo["campaign_id"] as? String ?? "",
            "message_id": userInfo["message_id"] as? String ?? "",
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Open event added to Treasure Data SDK")
    }

    private func trackDismissEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "dismiss",
            "campaign_id": userInfo["campaign_id"] as? String ?? "",
            "message_id": userInfo["message_id"] as? String ?? "",
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Dismiss event added to Treasure Data SDK")
    }

    // MARK: - Deep Link Handling

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        LogHelper.debug("========== handleNotificationTap (JSON) ==========")
        do {
            var userInfoDict: [String: Any] = [:]
            for (key, value) in userInfo {
                userInfoDict["\(key)"] = "\(value)"
            }
            let jsonData = try JSONSerialization.data(withJSONObject: userInfoDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                LogHelper.debug("User Info:\n\(jsonString)")
            }
        } catch {
            LogHelper.error("Error formatting userInfo as JSON", error: error)
        }

        // Get configured deep link scheme from Info.plist
        guard let deepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            return
        }

        // Process deeplink field (backward compatibility)
        if let deepLinkField = userInfo["deeplink"] as? String, let url = URL(string: deepLinkField) {
            LogHelper.debug("Processing deeplink field: \(deepLinkField)")
            if url.scheme == deepLinkScheme {
                // Validate deep link host against whitelist
                guard let host = url.host, allowedDeepLinkHosts.contains(host) else {
                    LogHelper.warning("Invalid deep link host: \(url.host ?? "nil")")
                    return
                }

                let campaignId = userInfo["campaign_id"] as? String ?? ""
                let messageId = userInfo["message_id"] as? String ?? ""

                // Track deep link open event
                TrackingService.shared.trackDeepLinkOpenEvent(deepLink: deepLinkField, campaignId: campaignId, messageId: messageId)

                // Navigate to deep link (handled in SceneDelegate) - pass campaign data for tracking
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenDeepLink"),
                    object: nil,
                    userInfo: [
                        "url": url,
                        "deepLink": deepLinkField,
                        "campaign_id": campaignId,
                        "message_id": messageId
                    ]
                )
            } else {
                LogHelper.warning("Invalid deep link scheme in deeplink field: \(url.scheme ?? "nil")")
            }
        }

        // Process link field - detect if it's a deep link or web link by URI scheme
        if let linkField = userInfo["link"] as? String {
            LogHelper.debug("Found link field: \(linkField)")

            guard let url = URL(string: linkField) else {
                LogHelper.error("Failed to parse link field URL: \(linkField)")
                return
            }

            let scheme = url.scheme?.lowercased()

            // Log URL details as JSON
            do {
                let urlInfo: [String: Any] = [
                    "url": url.absoluteString,
                    "scheme": url.scheme ?? NSNull(),
                    "host": url.host ?? NSNull(),
                    "path": url.path
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: urlInfo, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    LogHelper.debug("Parsed link field URL (JSON):\n\(jsonString)")
                }
            } catch {
                LogHelper.error("Error formatting URL as JSON", error: error)
            }

            LogHelper.debug("Processing link field (scheme: \(scheme ?? "nil"))")

            switch scheme {
            case deepLinkScheme:
                // Deep link
                LogHelper.debug("Link field contains deep link")

                // Validate deep link host against whitelist
                guard let host = url.host, allowedDeepLinkHosts.contains(host) else {
                    LogHelper.warning("Invalid deep link host: \(url.host ?? "nil")")
                    return
                }

                let campaignId = userInfo["campaign_id"] as? String ?? ""
                let messageId = userInfo["message_id"] as? String ?? ""

                // Track deep link open event
                TrackingService.shared.trackDeepLinkOpenEvent(deepLink: linkField, campaignId: campaignId, messageId: messageId)

                // Navigate to deep link (handled in SceneDelegate) - pass campaign data for tracking
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenDeepLink"),
                    object: nil,
                    userInfo: [
                        "url": url,
                        "deepLink": linkField,
                        "campaign_id": campaignId,
                        "message_id": messageId
                    ]
                )

            case "http", "https":
                // Web link
                LogHelper.debug("Link field contains web link")

                let campaignId = userInfo["campaign_id"] as? String ?? ""
                let messageId = userInfo["message_id"] as? String ?? ""

                // Validate domain against allowlist
                guard let host = url.host, allowedDomains.contains(host) else {
                    LogHelper.warning("Domain not in allowlist: \(url.host ?? "nil") (allowed: \(allowedDomains.joined(separator: ", ")))")
                    TrackingService.shared.trackLinkFailEvent(link: linkField, campaignId: campaignId, messageId: messageId, reason: "domain_not_allowed")
                    fallbackToHome()
                    return
                }

                // Track link open event
                TrackingService.shared.trackWebLinkOpenEvent(webLink: linkField, campaignId: campaignId, messageId: messageId)

                // Open in Safari
                if UIApplication.shared.canOpenURL(url) {
                    LogHelper.debug("Opening URL in Safari: \(url)")
                    UIApplication.shared.open(url, options: [:]) { success in
                        if success {
                            LogHelper.debug("Successfully opened URL in Safari")
                            // Track successful arrival
                            TrackingService.shared.trackLinkArriveEvent(link: linkField, campaignId: campaignId, messageId: messageId)
                        } else {
                            LogHelper.error("Failed to open URL in Safari")
                            TrackingService.shared.trackLinkFailEvent(link: linkField, campaignId: campaignId, messageId: messageId, reason: "browser_open_failed")
                            self.fallbackToHome()
                        }
                    }
                } else {
                    LogHelper.error("Cannot open URL (canOpenURL returned false): \(url)")
                    TrackingService.shared.trackLinkFailEvent(link: linkField, campaignId: campaignId, messageId: messageId, reason: "browser_open_failed")
                    fallbackToHome()
                }

            default:
                LogHelper.warning("Unknown URI scheme in link field: \(scheme ?? "nil")")
            }
        }

        // Log if no links were found
        if userInfo["deeplink"] == nil && userInfo["link"] == nil {
            LogHelper.debug("No deeplink or link field found in userInfo")
        }

        LogHelper.debug("===========================================")
    }

    // MARK: - Fallback Strategy

    private func fallbackToHome() {
        LogHelper.debug("Fallback: Invalid link - staying at home screen")
        // App stays on home screen, no navigation occurs
        // The user sees the app in its default state
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        LogHelper.debug("FCM token: \(token)")

        // Register token with Treasure Data
        FCMTokenService.shared.registerToken(token: token)
    }
}
