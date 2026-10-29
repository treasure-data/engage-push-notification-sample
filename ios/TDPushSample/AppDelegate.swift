import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import TreasureData_iOS_SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private weak var notificationScene: SceneDelegate?
    private var pendingNotificationTaps: [[AnyHashable: Any]] = []
    private var handledNotificationResponses: Set<String> = []

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

            // Append device, app, locale, and record metadata to every event.
            TreasureData.sharedInstance().enableAutoAppendUniqId()
            TreasureData.sharedInstance().enableAutoAppendModelInformation()
            TreasureData.sharedInstance().enableAutoAppendAppInformation()
            TreasureData.sharedInstance().enableAutoAppendLocaleInformation()
            TreasureData.sharedInstance().enableAutoAppendRecordUUID()

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
        // Engage Studio sets aps.category to default; dismiss callbacks require this option.
        let defaultCategory = UNNotificationCategory(
            identifier: "default",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([defaultCategory])
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
        // Firebase method swizzling is disabled, so pass the APNs token to Messaging explicitly.
        Messaging.messaging().apnsToken = deviceToken
        LogHelper.debug("APNs token registered")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LogHelper.error("Failed to register for remote notifications", error: error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Foreground delivery is tracked in willPresent; background execution is best-effort.
        if application.applicationState != .active {
            trackDeliveryEvent(userInfo: userInfo)
        }
        completionHandler(.newData)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Upload any pending events when app enters background
        TreasureData.sharedInstance().uploadEvents(callback: {
            LogHelper.debug("Background upload completed successfully")
        }, onError: { (code, message) in
            LogHelper.error("Background upload failed - Code: \(code), Message: \(message)")
        })
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

        // Log notification content and metadata for debugging.
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

            // Stringify userInfo values for diagnostic logging.
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
                        "type": attachment.type
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

    // Handle notification taps and dismissals.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        // UIKit navigation and response deduplication share the main queue with Scene callbacks.
        DispatchQueue.main.async {
            self.handleNotificationResponse(response)
            completionHandler()
        }
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let responseKey = response.notification.request.identifier + ":" + response.actionIdentifier
        guard handledNotificationResponses.insert(responseKey).inserted else { return }

        let userInfo = response.notification.request.content.userInfo
        let content = response.notification.request.content

        // Log the notification content and the user's action for debugging.
        LogHelper.debug("========== Notification Payload (Response - JSON) ==========")
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

            // Stringify userInfo values for diagnostic logging.
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
            // A cold-start response can arrive before the Scene is ready to present a screen.
            if notificationScene?.window?.windowScene?.activationState == .foregroundActive {
                handleNotificationTap(userInfo: userInfo)
            } else {
                pendingNotificationTaps.append(userInfo)
            }

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            trackDismissEvent(userInfo: userInfo)

        default:
            break
        }
    }

    func notificationSceneDidBecomeActive(_ scene: SceneDelegate) {
        notificationScene = scene
        let pendingTaps = pendingNotificationTaps
        pendingNotificationTaps.removeAll()
        for userInfo in pendingTaps {
            handleNotificationTap(userInfo: userInfo)
        }
    }

    // MARK: - Event Tracking

    private func trackDeliveryEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let (campaignId, messageId) = extractCampaignAndMessageIDs(from: userInfo)

        let event: [String: Any] = [
            "type": "delivery",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Delivery event added to Treasure Data SDK")

        // addEvent queues locally; request an upload during the notification callback.
        TreasureData.sharedInstance().uploadEvents()
    }

    private func trackOpenEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let (campaignId, messageId) = extractCampaignAndMessageIDs(from: userInfo)

        let event: [String: Any] = [
            "type": "open",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Open event added to Treasure Data SDK")

        // addEvent queues locally; request an upload during the notification callback.
        TreasureData.sharedInstance().uploadEvents()
    }

    private func trackDismissEvent(userInfo: [AnyHashable: Any]) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let (campaignId, messageId) = extractCampaignAndMessageIDs(from: userInfo)

        let event: [String: Any] = [
            "type": "dismiss",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Dismiss event added to Treasure Data SDK")

        // addEvent queues locally; request an upload during the notification callback.
        TreasureData.sharedInstance().uploadEvents()
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

        guard let configuredDeepLinkScheme = Bundle.main.object(forInfoDictionaryKey: "TDDeepLinkScheme") as? String else {
            LogHelper.error("TDDeepLinkScheme not configured in Info.plist")
            return
        }

        let deepLinkScheme = configuredDeepLinkScheme.lowercased()
        let (campaignId, messageId) = extractCampaignAndMessageIDs(from: userInfo)

        // Engage Studio uses link for both web URLs and deep links; Open app omits it.
        guard let link = userInfo["link"] as? String else {
            LogHelper.debug("No link field found in userInfo")
            return
        }

        guard let url = URL(string: link), let scheme = url.scheme?.lowercased() else {
            LogHelper.error("Failed to parse link field URL: \(link)")
            return
        }

        LogHelper.debug("Processing link field (scheme: \(scheme))")

        switch scheme {
        case deepLinkScheme:
            guard let host = url.host, allowedDeepLinkHosts.contains(host) else {
                LogHelper.warning("Invalid deep link host: \(url.host ?? "nil")")
                return
            }

            TrackingService.shared.trackDeepLinkOpenEvent(deepLink: link, campaignId: campaignId, messageId: messageId)
            // Pass attribution to the Scene for destination events.
            notificationScene?.handleDeepLink(
                url: url, deepLink: link, campaignId: campaignId, messageId: messageId
            )

        case "http", "https":
            guard let host = url.host, allowedDomains.contains(host) else {
                LogHelper.warning("Domain not in allowlist: \(url.host ?? "nil") (allowed: \(allowedDomains.joined(separator: ", ")))")
                TrackingService.shared.trackLinkFailEvent(link: link, campaignId: campaignId, messageId: messageId, reason: "domain_not_allowed")
                return
            }

            TrackingService.shared.trackWebLinkOpenEvent(webLink: link, campaignId: campaignId, messageId: messageId)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        LogHelper.debug("Successfully opened URL in Safari")
                        // Records a successful URL handoff; page loading is outside this callback.
                        TrackingService.shared.trackLinkArriveEvent(link: link, campaignId: campaignId, messageId: messageId)
                    } else {
                        LogHelper.error("Failed to open URL in Safari")
                        TrackingService.shared.trackLinkFailEvent(link: link, campaignId: campaignId, messageId: messageId, reason: "browser_open_failed")
                    }
                }
            } else {
                LogHelper.error("Cannot open URL (canOpenURL returned false): \(url)")
                TrackingService.shared.trackLinkFailEvent(link: link, campaignId: campaignId, messageId: messageId, reason: "browser_open_failed")
            }

        default:
            LogHelper.warning("Unknown URI scheme in link field: \(scheme)")
        }

        LogHelper.debug("===========================================")
    }

    // MARK: - Helper Functions

    // Engage Studio supplies tdCampaignId; FCM adds gcm.message_id at the userInfo root.
    // simctl push does not add an FCM message ID.
    private func extractCampaignAndMessageIDs(from userInfo: [AnyHashable: Any]) -> (String, String) {
        let campaignId = userInfo["tdCampaignId"] as? String ?? ""
        let messageId = userInfo["gcm.message_id"] as? String ?? ""

        return (campaignId, messageId)
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
