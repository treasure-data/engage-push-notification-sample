import Foundation
import FirebaseMessaging
import TreasureData_iOS_SDK

class TrackingService {

    static let shared = TrackingService()

    private init() {}

    // MARK: - Event Tracking Methods

    func trackLinkArriveEvent(link: String, campaignId: String, messageId: String) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "link_arrive",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "value": link,
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Link arrive event added to Treasure Data SDK")
    }

    func trackLinkFailEvent(link: String, campaignId: String, messageId: String, reason: String) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "link_fail",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "value": link,
            "reason": reason,
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Link fail event added to Treasure Data SDK - reason: \(reason)")
    }

    func trackDeepLinkOpenEvent(deepLink: String, campaignId: String, messageId: String) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "deeplink_open",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "value": deepLink,
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("DeepLink open event added to Treasure Data SDK")
    }

    func trackWebLinkOpenEvent(webLink: String, campaignId: String, messageId: String) {
        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        let event: [String: Any] = [
            "type": "link_open",
            "campaign_id": campaignId,
            "message_id": messageId,
            "platform": "ios",
            "fcm_token": Messaging.messaging().fcmToken ?? "",
            "value": webLink,
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Link open event added to Treasure Data SDK")
    }
}
