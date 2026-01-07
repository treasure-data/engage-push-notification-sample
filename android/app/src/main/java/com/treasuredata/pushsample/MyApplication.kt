package com.treasuredata.pushsample

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.fcm.FcmTokenService

class MyApplication : Application() {

    companion object {
        private const val TAG = "MyApplication"
    }

    override fun onCreate() {
        super.onCreate()

        // REQUIRED: Initialize Firebase
        // This is required for FCM (Firebase Cloud Messaging) to work
        // Make sure you have google-services.json in app/ directory
        FirebaseApp.initializeApp(this)
        logDebug(TAG, "Firebase initialized")

        // REQUIRED: Initialize Treasure Data SDK
        // CUSTOMIZE: Change the encryption key to a unique value for your app
        TreasureData.initializeEncryptionKey("td_push_sample_encryption_key")

        // REQUIRED: Set your Treasure Data credentials
        // TD_WRITE_KEY, TD_ENDPOINT, TD_DATABASE are defined in secrets.properties
        // See secrets.properties.example for reference
        TreasureData.initializeSharedInstance(
            this,
            BuildConfig.TD_WRITE_KEY,
            BuildConfig.TD_ENDPOINT
        )
        TreasureData.sharedInstance().setDefaultDatabase(BuildConfig.TD_DATABASE)

        // REQUIRED: Enable automatic data collection
        // These methods automatically append useful information to all events
        TreasureData.sharedInstance().enableAutoAppendUniqId()
        TreasureData.sharedInstance().enableAutoAppendModelInformation()
        TreasureData.sharedInstance().enableAutoAppendAppInformation()
        TreasureData.sharedInstance().enableAutoAppendLocaleInformation()
        TreasureData.sharedInstance().enableAutoAppendRecordUUID()

        logDebug(TAG, "Treasure Data SDK initialized")
        logDebug(TAG, "Database: ${BuildConfig.TD_DATABASE}")
        logDebug(TAG, "Endpoint: ${BuildConfig.TD_ENDPOINT}")

        // REQUIRED: Register FCM token on app launch
        // This sends the FCM token to Treasure Data for tracking
        FcmTokenService.registerToken(this)
    }

    // MARK: - Logging Helpers

    private fun logDebug(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(tag, message)
        }
    }
}
