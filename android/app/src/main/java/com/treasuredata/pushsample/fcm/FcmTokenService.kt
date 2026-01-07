package com.treasuredata.pushsample.fcm

import android.content.Context
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.BuildConfig
import com.treasuredata.pushsample.utils.TimeUtils

// REQUIRED: FCM Token Management Service
// This object handles registration and association of FCM tokens with Treasure Data
object FcmTokenService {

    private const val TAG = "FcmTokenService"
    private const val PREF_NAME = "td_push_prefs"
    private const val KEY_USER_ID = "user_id"

    fun registerToken(context: Context) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val token = task.result
                registerToken(context, token)
            } else {
                logError(TAG, "Error fetching FCM token", task.exception)
            }
        }
    }

    fun registerToken(context: Context, token: String) {
        logDebug(TAG, "Registering FCM token with Treasure Data: $token")

        // REQUIRED: Device metadata is automatically added by TD SDK via:
        // - enableAutoAppendModelInformation() -> td_device, td_model, td_os_ver, td_os_type
        // - enableAutoAppendAppInformation() -> td_app_ver, td_app_ver_num
        // - enableAutoAppendLocaleInformation() -> td_locale_country, td_locale_lang
        // - enableAutoAppendUniqId() -> td_uuid
        // - enableAutoAppendRecordUUID() -> record_uuid (per-event unique ID)
        val event = mutableMapOf<String, Any>(
            "type" to "token_register",
            "fcm_token" to token,
            "platform" to "android",
            "time" to TimeUtils.getCurrentTimestamp()
        )

        // Add user_id if available
        getUserId(context)?.let { event["user_id"] = it }

        TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
        logDebug(TAG, "Token registration event added to Treasure Data SDK")
    }

    // CUSTOMIZE: Associate a user ID with the FCM token
    // Call this method after user login to link push notifications to a specific user
    fun associateUser(context: Context, userId: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_USER_ID, userId).apply()

        // Re-register token with user_id
        registerToken(context)
    }

    // CUSTOMIZE: Dissociate user ID from FCM token
    // Call this method after user logout
    fun dissociateUser(context: Context) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_USER_ID).apply()
    }

    private fun getUserId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_USER_ID, null)
    }

    // MARK: - Logging Helpers

    private fun logDebug(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(tag, message)
        }
    }

    private fun logError(tag: String, message: String, throwable: Throwable? = null) {
        if (BuildConfig.ENABLE_LOGGING) {
            if (throwable != null) {
                Log.e(tag, message, throwable)
            } else {
                Log.e(tag, message)
            }
        }
    }
}
