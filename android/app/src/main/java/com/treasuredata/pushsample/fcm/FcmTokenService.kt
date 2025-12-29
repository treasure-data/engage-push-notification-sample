package com.treasuredata.pushsample.fcm

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.BuildConfig
import com.treasuredata.pushsample.utils.TimeUtils

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

        val event = mutableMapOf<String, Any>(
            "type" to "token_register",
            "fcm_token" to token,
            "platform" to "android",
            "app_version" to getAppVersion(context),
            "os_version" to Build.VERSION.RELEASE,
            "device_model" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "time" to TimeUtils.getCurrentTimestamp()
        )

        // Add user_id if available
        getUserId(context)?.let { event["user_id"] = it }

        TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
        logDebug(TAG, "Token registration event added to Treasure Data SDK")
    }

    fun associateUser(context: Context, userId: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_USER_ID, userId).apply()

        // Re-register token with user_id
        registerToken(context)
    }

    fun dissociateUser(context: Context) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_USER_ID).apply()
    }

    private fun getUserId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_USER_ID, null)
    }

    private fun getAppVersion(context: Context): String {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(context.packageName, 0)
            }
            packageInfo.versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
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
