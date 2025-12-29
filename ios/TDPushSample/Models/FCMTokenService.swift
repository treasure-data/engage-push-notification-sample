import Foundation
import FirebaseMessaging
import TreasureData_iOS_SDK

class FCMTokenService {

    static let shared = FCMTokenService()

    private init() {}

    // MARK: - Token Registration

    func registerToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                LogHelper.error("Error fetching FCM token", error: error)
                return
            }

            if let token = token {
                self.registerToken(token: token)
            }
        }
    }

    func registerToken(token: String) {
        LogHelper.debug("Registering FCM token with Treasure Data: \(token)")

        guard let table = Bundle.main.object(forInfoDictionaryKey: "TDTable") as? String else {
            LogHelper.error("TDTable not configured")
            return
        }

        var event: [String: Any] = [
            "type": "token_register",
            "fcm_token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "os_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model,
            "time": TimeUtils.shared.getCurrentTimestamp()
        ]

        // Add user_id if available (example: from UserDefaults or authentication system)
        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            event["user_id"] = userId
        }

        TreasureData.sharedInstance().addEvent(event, table: table)
        LogHelper.debug("Token registration event added to Treasure Data SDK")
    }

    // MARK: - User Association

    func associateUser(userId: String) {
        UserDefaults.standard.set(userId, forKey: "user_id")
        UserDefaults.standard.synchronize()

        // Re-register token with user_id
        registerToken()
    }

    func dissociateUser() {
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.synchronize()
    }
}
