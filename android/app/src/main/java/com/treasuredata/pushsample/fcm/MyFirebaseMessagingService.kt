package com.treasuredata.pushsample.fcm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.BuildConfig
import com.treasuredata.pushsample.MainActivity
import com.treasuredata.pushsample.R
import com.treasuredata.pushsample.utils.TimeUtils
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FCMService"
        private const val CHANNEL_ID = "td_push_notifications"
        private const val IMAGE_DOWNLOAD_TIMEOUT_MS = 10000
        private const val IMAGE_CONNECT_TIMEOUT_MS = 5000
    }

    // REQUIRED: Handle incoming FCM messages
    // This method is called when a push notification is received
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        logDebug(TAG, getString(R.string.log_fcm_message_received, message.from ?: "unknown"))

        // Log complete FCM message payload as JSON
        logDebug(TAG, "========== FCM Message Payload (JSON) ==========")
        try {
            val payloadJson = JSONObject().apply {
                put("messageId", message.messageId)
                put("messageType", message.messageType)
                put("from", message.from)
                put("to", message.to)
                put("sentTime", message.sentTime)
                put("ttl", message.ttl)

                // Notification payload
                message.notification?.let { notification ->
                    put("notification", JSONObject().apply {
                        put("title", notification.title)
                        put("body", notification.body)
                        put("icon", notification.icon)
                        put("imageUrl", notification.imageUrl?.toString())
                        put("sound", notification.sound)
                        put("tag", notification.tag)
                        put("clickAction", notification.clickAction)
                        put("channelId", notification.channelId)
                    })
                } ?: put("notification", JSONObject.NULL)

                // Data payload
                put("data", JSONObject().apply {
                    message.data.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
            logDebug(TAG, payloadJson.toString(2)) // Indent with 2 spaces
        } catch (e: Exception) {
            logError(TAG, "Error formatting FCM message as JSON", e)
        }
        logDebug(TAG, "===============================================")

        // Extract campaign and FCM message IDs for event tracking
        val campaignId = message.data["tdCampaignId"].orEmpty()
        val messageId = message.messageId.orEmpty()

        // Engage Studio sends Android notifications as data-only FCM messages.
        val title = message.data["title"] ?: getString(R.string.notification_default_title)
        val body = message.data["message"].orEmpty()
        val imageUrl = message.data["image"]

        val (deepLink, webLink) = parseLinkField(message.data["link"])

        logDebug(TAG, getString(R.string.log_campaign_id, campaignId))
        logDebug(TAG, getString(R.string.log_message_id, messageId))
        logDebug(TAG, getString(R.string.log_title, title))
        logDebug(TAG, getString(R.string.log_body, body))

        // Track delivery event
        trackDeliveryEvent(campaignId, messageId)

        // Show notification
        showNotification(title, body, imageUrl, campaignId, messageId, deepLink, webLink)
    }

    // REQUIRED: Handle FCM token refresh
    // This is called when Firebase generates a new token (e.g., after app reinstall)
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        logDebug(TAG, getString(R.string.log_new_fcm_token, token))

        // Register token with Treasure Data
        FcmTokenService.registerToken(this, token)
    }

    private fun showNotification(
        title: String,
        body: String,
        imageUrl: String?,
        campaignId: String,
        messageId: String,
        deepLink: String?,
        webLink: String?
    ) {
        createNotificationChannel()

        // Download image if present
        val bitmap = imageUrl?.let { downloadImage(it) }

        // Create intent for notification tap
        val intent = Intent(this, MainActivity::class.java).apply {
            action = PushAction.ACTION_NOTIFICATION_OPENED
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("campaign_id", campaignId)
            putExtra("message_id", messageId)
            putExtra("deeplink", deepLink)
            putExtra("link", webLink)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            pendingIntentFlags
        )

        // Create delete intent for dismiss tracking
        val deleteIntent = Intent(this, PushEventReceiver::class.java).apply {
            action = PushAction.ACTION_NOTIFICATION_DISMISSED
            putExtra("campaign_id", campaignId)
            putExtra("message_id", messageId)
        }

        val deletePendingIntent = PendingIntent.getBroadcast(
            this,
            System.currentTimeMillis().toInt(),
            deleteIntent,
            pendingIntentFlags
        )

        // CUSTOMIZE: Build notification with your app's style
        // Modify notification appearance, sound, vibration, etc.
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification) // Change to your app's icon
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setDeleteIntent(deletePendingIntent)

        // Add image if downloaded
        if (bitmap != null) {
            notificationBuilder.setLargeIcon(bitmap)
            notificationBuilder.setStyle(
                NotificationCompat.BigPictureStyle()
                    .bigPicture(bitmap)
                    .bigLargeIcon(null as android.graphics.Bitmap?)
            )
            logDebug(TAG, getString(R.string.log_image_attached))
        }

        // Show notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())

        logDebug(TAG, getString(R.string.log_notification_displayed, notificationId))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = getString(R.string.notification_channel_description)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Download image from URL with timeout and proper resource management
     * @param imageUrl URL of the image to download
     * @return Bitmap if successful, null otherwise
     */
    private fun downloadImage(imageUrl: String): Bitmap? {
        return try {
            logDebug(TAG, getString(R.string.log_downloading_image, imageUrl))
            val url = URL(imageUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.apply {
                doInput = true
                connectTimeout = IMAGE_CONNECT_TIMEOUT_MS
                readTimeout = IMAGE_DOWNLOAD_TIMEOUT_MS
            }
            connection.connect()

            // Use 'use' to ensure InputStream is closed
            connection.inputStream.use { input ->
                BitmapFactory.decodeStream(input)
            }
        } catch (e: Exception) {
            logError(TAG, getString(R.string.log_error_downloading_image), e)
            null
        }
    }

    private fun trackDeliveryEvent(campaignId: String, messageId: String) {
        com.google.firebase.messaging.FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val event = mutableMapOf<String, Any>(
                    "type" to "delivery",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to task.result,
                    "time" to TimeUtils.getCurrentTimestamp()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "Delivery"))
            }
        }
    }

    /**
     * Parse link field and determine if it's a deeplink or web link
     * @param linkField The link value from FCM payload
     * @return Pair of (deepLink, webLink) - one will be non-null, the other null
     */
    private fun parseLinkField(linkField: String?): Pair<String?, String?> {
        if (linkField.isNullOrBlank()) {
            return Pair(null, null)
        }

        return when {
            // Check if it's a web link (http or https)
            linkField.startsWith("http://", ignoreCase = true) ||
            linkField.startsWith("https://", ignoreCase = true) -> {
                Pair(null, linkField)
            }
            // Check if it's a deeplink (custom scheme)
            linkField.contains("://") -> {
                Pair(linkField, null)
            }
            // Default: treat as deeplink if no scheme detected
            else -> {
                Pair(linkField, null)
            }
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
