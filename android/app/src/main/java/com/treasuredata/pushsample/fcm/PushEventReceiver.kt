package com.treasuredata.pushsample.fcm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.BuildConfig
import com.treasuredata.pushsample.utils.TimeUtils

// REQUIRED: BroadcastReceiver for notification dismiss events
// This receiver tracks when users dismiss (swipe away) push notifications
class PushEventReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PushEventReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PushAction.ACTION_NOTIFICATION_DISMISSED -> {
                val campaignId = intent.getStringExtra("campaign_id") ?: ""
                val messageId = intent.getStringExtra("message_id") ?: ""

                logDebug(TAG, "Notification dismissed - campaign: $campaignId, message: $messageId")

                trackDismissEvent(context, campaignId, messageId)
            }
            // CUSTOMIZE: Add more action handlers here if needed
            // Example: Custom notification actions (buttons in notifications)
        }
    }

    private fun trackDismissEvent(context: Context, campaignId: String, messageId: String) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val event = mutableMapOf<String, Any>(
                    "type" to "dismiss",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to task.result,
                    "time" to TimeUtils.getCurrentTimestamp()
                    // CUSTOMIZE: Add custom event properties here
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, "Dismiss event added to Treasure Data SDK")
            }
        }
    }

    // MARK: - Logging Helpers

    private fun logDebug(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(tag, message)
        }
    }
}
