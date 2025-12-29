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

        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        logDebug(TAG, "Firebase initialized")

        // Initialize Treasure Data SDK
        TreasureData.initializeEncryptionKey("td_push_sample_encryption_key")
        TreasureData.initializeSharedInstance(
            this,
            BuildConfig.TD_WRITE_KEY,
            BuildConfig.TD_ENDPOINT
        )
        TreasureData.sharedInstance().setDefaultDatabase(BuildConfig.TD_DATABASE)
        logDebug(TAG, "Treasure Data SDK initialized")
        logDebug(TAG, "Database: ${BuildConfig.TD_DATABASE}")
        logDebug(TAG, "Endpoint: ${BuildConfig.TD_ENDPOINT}")

        // Register FCM token on app launch
        FcmTokenService.registerToken(this)
    }

    // MARK: - Logging Helpers

    private fun logDebug(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(tag, message)
        }
    }
}
