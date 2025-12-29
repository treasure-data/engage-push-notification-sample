package com.treasuredata.pushsample

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import com.treasuredata.android.TreasureData
import com.treasuredata.pushsample.databinding.ActivityMainBinding
import com.treasuredata.pushsample.fcm.FcmTokenService
import com.treasuredata.pushsample.fcm.PushAction
import com.treasuredata.pushsample.utils.TimeUtils
import kotlinx.coroutines.launch
import org.json.JSONObject

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    companion object {
        private const val TAG = "MainActivity"

        // CUSTOMIZE: Parse allowlists from BuildConfig
        // These allowlists are defined in build.gradle.kts
        // Modify them to match your app's supported deep link hosts and web domains
        private val ALLOWED_DEEP_LINK_HOSTS by lazy {
            BuildConfig.ALLOWED_DEEP_LINK_HOSTS.split(",").map { it.trim() }.toSet()
        }

        private val ALLOWED_DOMAINS by lazy {
            BuildConfig.ALLOWED_DOMAINS.split(",").map { it.trim() }.toSet()
        }
    }

    // Notification permission launcher (Android 13+)
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            logDebug(TAG, getString(R.string.notification_permission_granted))
            binding.statusTextView.text = getString(R.string.notification_permission_granted)
        } else {
            logDebug(TAG, getString(R.string.notification_permission_denied))
            binding.statusTextView.text = getString(R.string.notification_permission_denied)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        logDebug(TAG, "onCreate called")

        setupListeners()
        updateTokenDisplay()
        updateEventCount()

        // Request notification permission for Android 13+
        requestNotificationPermission()

        // Handle notification tap (if app was opened from notification)
        logDebug(TAG, "Checking onCreate intent")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        logDebug(TAG, "onNewIntent called")
        setIntent(intent) // Important: Update the activity's intent
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        logDebug(TAG, "onResume called")
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    logDebug(TAG, getString(R.string.notification_permission_already_granted))
                }
                else -> {
                    logDebug(TAG, getString(R.string.requesting_notification_permission))
                    requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
        }
    }

    private fun setupListeners() {
        binding.refreshButton.setOnClickListener {
            refreshToken()
        }

        binding.uploadButton.setOnClickListener {
            uploadEvents()
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            logDebug(TAG, "handleIntent: Intent is null")
            return
        }

        // Log complete Intent as JSON
        logDebug(TAG, "========== Intent (JSON) ==========")
        try {
            val intentJson = JSONObject().apply {
                put("action", intent.action)
                put("data", intent.data?.toString())
                put("type", intent.type)
                put("flags", intent.flags)

                // Extras as JSON
                intent.extras?.let { extras ->
                    put("extras", JSONObject().apply {
                        for (key in extras.keySet()) {
                            put(key, extras.get(key)?.toString())
                        }
                    })
                } ?: put("extras", JSONObject.NULL)
            }
            logDebug(TAG, intentJson.toString(2)) // Indent with 2 spaces
        } catch (e: Exception) {
            logError(TAG, "Error formatting Intent as JSON", e)
        }
        logDebug(TAG, "===================================")

        // Handle notification tap
        // Check both action and presence of notification-specific extras
        val hasNotificationExtras = intent.hasExtra("link") ||
                                    intent.hasExtra("deeplink") ||
                                    intent.hasExtra("campaign_id") ||
                                    intent.hasExtra("message_id")

        if (intent.action == PushAction.ACTION_NOTIFICATION_OPENED || hasNotificationExtras) {
            logDebug(TAG, "Detected notification intent (action match or has notification extras)")

            val campaignId = intent.getStringExtra("campaign_id") ?: ""
            val messageId = intent.getStringExtra("message_id") ?: ""
            val deepLinkField = intent.getStringExtra("deeplink")
            val linkField = intent.getStringExtra("link")

            logDebug(TAG, "Notification opened - campaign_id: $campaignId, message_id: $messageId")
            logDebug(TAG, "deeplink field: $deepLinkField, link field: $linkField")

            // Track open event (only if we haven't processed this intent before)
            if (!intent.getBooleanExtra("processed", false)) {
                trackOpenEvent(campaignId, messageId)
                intent.putExtra("processed", true)
            }

            // Process deeplink field (backward compatibility)
            if (!deepLinkField.isNullOrEmpty()) {
                logDebug(TAG, "Processing deeplink field: $deepLinkField")
                handleDeepLink(deepLinkField, campaignId, messageId)
            }

            // Process link field - detect if it's a deep link or web link by URI scheme
            if (!linkField.isNullOrEmpty()) {
                val uri = Uri.parse(linkField)
                val scheme = uri.scheme?.lowercase()

                logDebug(TAG, "Processing link field: $linkField (scheme: $scheme)")

                when (scheme) {
                    BuildConfig.DEEP_LINK_SCHEME -> {
                        // Deep link
                        logDebug(TAG, "Link field contains deep link")
                        handleDeepLink(linkField, campaignId, messageId)
                    }
                    "http", "https" -> {
                        // Web link
                        logDebug(TAG, "Link field contains web link")
                        handleWebLink(linkField, campaignId, messageId)
                    }
                    else -> {
                        logWarn(TAG, "Unknown URI scheme in link field: $scheme")
                    }
                }
            }

            // Log if no links were found
            if (deepLinkField.isNullOrEmpty() && linkField.isNullOrEmpty()) {
                logDebug(TAG, "No deeplink or link field found")
            }
        } else {
            logDebug(TAG, "Not a notification intent - action: ${intent.action}, hasNotificationExtras: false")
        }

        // Handle deep link from custom scheme (direct link, not from notification)
        intent.data?.let { uri ->
            logDebug(TAG, "Intent has data URI: $uri")
            if (uri.scheme == BuildConfig.DEEP_LINK_SCHEME) {
                logDebug(TAG, "Processing deep link URI: $uri")
                // For direct links, campaign/message IDs are empty
                handleDeepLinkUri(uri, uri.toString(), "", "")
            }
        }
    }

    private fun handleDeepLink(deepLink: String, campaignId: String, messageId: String) {
        val uri = Uri.parse(deepLink)

        if (uri.scheme != BuildConfig.DEEP_LINK_SCHEME) {
            logWarn(TAG, getString(R.string.log_invalid_deep_link_scheme, uri.scheme))
            return
        }

        // Track deep link open event
        trackDeepLinkOpenEvent(deepLink, campaignId, messageId)

        // Navigate based on deep link
        handleDeepLinkUri(uri, deepLink, campaignId, messageId)
    }

    // CUSTOMIZE: Deep Link Routing Logic
    // This function handles deep link navigation based on the URI host
    // Modify the when() cases to match your app's screen structure
    // Example deep links:
    //   - myapp://product/12345 -> Product detail screen
    //   - myapp://category/electronics -> Category list screen
    //   - myapp://home -> Home screen
    private fun handleDeepLinkUri(uri: Uri, deepLink: String, campaignId: String, messageId: String) {
        logDebug(TAG, getString(R.string.log_deep_link_opened, uri.toString()))

        // REQUIRED: Validate deep link host against allowlist (Security measure)
        if (uri.host !in ALLOWED_DEEP_LINK_HOSTS) {
            logWarn(TAG, getString(R.string.log_unknown_deep_link_host, uri.host))
            trackLinkFailEvent(deepLink, campaignId, messageId, "unknown_path")
            fallbackToHome()
            return
        }

        // CUSTOMIZE: Add cases for your app's deep link hosts
        when (uri.host) {
            "product" -> {
                // Example: myapp://product/12345
                val productId = uri.lastPathSegment
                if (productId.isNullOrEmpty()) {
                    logWarn(TAG, "Product ID is empty")
                    trackLinkFailEvent(deepLink, campaignId, messageId, "invalid_link")
                    fallbackToHome()
                    return
                }

                logDebug(TAG, getString(R.string.log_navigating_to_product, productId))

                // CUSTOMIZE: Navigate to your product detail screen
                // Replace ProductDetailActivity with your own activity
                val intent = Intent(Intent.ACTION_VIEW, uri, this, ProductDetailActivity::class.java).apply {
                    // Pass through campaign tracking extras if they exist
                    this@MainActivity.intent?.let { mainIntent ->
                        mainIntent.getStringExtra("campaign_id")?.let { putExtra("campaign_id", it) }
                        mainIntent.getStringExtra("message_id")?.let { putExtra("message_id", it) }
                    }
                }
                startActivity(intent)
                binding.statusTextView.text = getString(R.string.deep_link_product, productId)

                // Track successful arrival
                trackLinkArriveEvent(deepLink, campaignId, messageId)
            }
            "category" -> {
                // Example: myapp://category/electronics
                val categoryId = uri.lastPathSegment
                if (categoryId.isNullOrEmpty()) {
                    logWarn(TAG, "Category ID is empty")
                    trackLinkFailEvent(deepLink, campaignId, messageId, "invalid_link")
                    fallbackToHome()
                    return
                }

                logDebug(TAG, getString(R.string.log_navigating_to_category, categoryId))

                // CUSTOMIZE: Navigate to your category screen
                // Replace CategoryActivity with your own activity
                val intent = Intent(Intent.ACTION_VIEW, uri, this, CategoryActivity::class.java).apply {
                    // Pass through campaign tracking extras if they exist
                    this@MainActivity.intent?.let { mainIntent ->
                        mainIntent.getStringExtra("campaign_id")?.let { putExtra("campaign_id", it) }
                        mainIntent.getStringExtra("message_id")?.let { putExtra("message_id", it) }
                    }
                }
                startActivity(intent)
                binding.statusTextView.text = getString(R.string.deep_link_category, categoryId)

                // Track successful arrival
                trackLinkArriveEvent(deepLink, campaignId, messageId)
            }
            "home" -> {
                // Example: myapp://home
                logDebug(TAG, getString(R.string.log_navigating_to_home))
                // Already at home (MainActivity)
                binding.statusTextView.text = getString(R.string.deep_link_home)

                // Track successful arrival
                trackLinkArriveEvent(deepLink, campaignId, messageId)
            }
            // CUSTOMIZE: Add more cases for your app's deep link hosts
            // Example:
            // "settings" -> { /* Navigate to settings screen */ }
            // "search" -> { /* Navigate to search screen with query */ }
        }
    }

    private fun handleWebLink(webLink: String, campaignId: String, messageId: String) {
        logDebug(TAG, "========== handleWebLink (JSON) ==========")
        try {
            val webLinkJson = JSONObject().apply {
                put("webLink", webLink)
                put("campaignId", campaignId)
                put("messageId", messageId)
            }
            logDebug(TAG, webLinkJson.toString(2))
        } catch (e: Exception) {
            logError(TAG, "Error formatting web link as JSON", e)
        }

        // Parse URI
        val uri = try {
            Uri.parse(webLink)
        } catch (e: Exception) {
            logError(TAG, "Failed to parse web link: ${e.message}", e)
            trackLinkFailEvent(webLink, campaignId, messageId, "invalid_link")
            fallbackToHome()
            return
        }

        // Validate domain against allowlist
        val host = uri.host
        if (host == null || !ALLOWED_DOMAINS.contains(host)) {
            logWarn(TAG, "Domain not in allowlist: $host (allowed: ${ALLOWED_DOMAINS.joinToString(", ")})")
            trackLinkFailEvent(webLink, campaignId, messageId, "domain_not_allowed")
            fallbackToHome()
            return
        }

        // Track link open event
        trackLinkOpenEvent(webLink, campaignId, messageId)

        // Open in Chrome Custom Tabs
        try {
            val uriJson = JSONObject().apply {
                put("uri", uri.toString())
                put("scheme", uri.scheme)
                put("host", uri.host)
            }
            logDebug(TAG, "Parsed URI (JSON): ${uriJson.toString(2)}")

            val builder = CustomTabsIntent.Builder()
            val customTabsIntent = builder.build()

            logDebug(TAG, "Launching Chrome Custom Tabs for URL: $webLink")
            customTabsIntent.launchUrl(this, uri)
            logDebug(TAG, "Chrome Custom Tabs launched successfully")

            // Track successful arrival
            trackLinkArriveEvent(webLink, campaignId, messageId)
        } catch (e: Exception) {
            logError(TAG, "Failed to open web link: ${e.message}", e)
            val errorJson = JSONObject().apply {
                put("error", e.message)
                put("exceptionType", e.javaClass.simpleName)
            }
            logError(TAG, "Error details (JSON): ${errorJson.toString(2)}")
            trackLinkFailEvent(webLink, campaignId, messageId, "browser_open_failed")
            fallbackToHome()
        }
        logDebug(TAG, "==========================================")
    }

    private fun fallbackToHome() {
        binding.statusTextView.text = getString(R.string.fallback_to_home)
        logDebug(TAG, "Fallback: Staying at home screen")
    }

    private fun updateTokenDisplay() {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val shortToken = if (token.length > 20) {
                    getString(R.string.fcm_token_shortened, token.take(20))
                } else {
                    token
                }
                binding.tokenTextView.text = getString(R.string.fcm_token_format, shortToken)
            } catch (e: Exception) {
                binding.tokenTextView.text = getString(R.string.fcm_token_not_available)
                logError(TAG, getString(R.string.log_error_fetching_fcm_token), e)
            }
        }
    }

    private fun updateEventCount() {
        // TD SDK handles queue internally
        binding.eventCountTextView.text = getString(R.string.sdk_ready)
    }

    private fun refreshToken() {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                logDebug(TAG, getString(R.string.log_fcm_token, token))
                FcmTokenService.registerToken(this@MainActivity, token)
                updateTokenDisplay()
                binding.statusTextView.text = getString(R.string.token_refreshed)
            } catch (e: Exception) {
                logError(TAG, getString(R.string.log_error_fetching_fcm_token), e)
                binding.statusTextView.text = getString(R.string.error_fetching_token)
            }
        }
    }

    private fun uploadEvents() {
        binding.statusTextView.text = getString(R.string.uploading_events)
        TreasureData.sharedInstance().uploadEvents()
        binding.statusTextView.text = getString(R.string.upload_triggered)
        logDebug(TAG, getString(R.string.log_manual_upload))
    }

    // MARK: - Event Tracking
    // OPTIONAL: These event tracking methods send data to Treasure Data
    // You can add custom properties to events or create new event types

    private fun trackOpenEvent(campaignId: String, messageId: String) {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val event = mutableMapOf<String, Any>(
                    "type" to "open",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to token,
                    "time" to TimeUtils.getCurrentTimestamp()
                    // CUSTOMIZE: Add custom event properties here
                    // Example: "user_id" to getCurrentUserId()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "Open"))
            } catch (e: Exception) {
                logError(TAG, "Failed to track open event", e)
            }
        }
    }

    private fun trackDeepLinkOpenEvent(deepLink: String, campaignId: String, messageId: String) {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val event = mutableMapOf<String, Any>(
                    "type" to "deeplink_open",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to token,
                    "value" to deepLink,
                    "time" to TimeUtils.getCurrentTimestamp()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "DeepLink open"))
            } catch (e: Exception) {
                logError(TAG, "Failed to track deeplink_open event", e)
            }
        }
    }

    private fun trackLinkOpenEvent(webLink: String, campaignId: String, messageId: String) {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val event = mutableMapOf<String, Any>(
                    "type" to "link_open",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to token,
                    "value" to webLink,
                    "time" to TimeUtils.getCurrentTimestamp()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "Link open"))
            } catch (e: Exception) {
                logError(TAG, "Failed to track link_open event", e)
            }
        }
    }

    private fun trackLinkArriveEvent(link: String, campaignId: String, messageId: String) {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val event = mutableMapOf<String, Any>(
                    "type" to "link_arrive",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to token,
                    "value" to link,
                    "time" to TimeUtils.getCurrentTimestamp()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "Link arrive"))
            } catch (e: Exception) {
                logError(TAG, "Failed to track link_arrive event", e)
            }
        }
    }

    private fun trackLinkFailEvent(link: String, campaignId: String, messageId: String, reason: String) {
        lifecycleScope.launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                val event = mutableMapOf<String, Any>(
                    "type" to "link_fail",
                    "campaign_id" to campaignId,
                    "message_id" to messageId,
                    "platform" to "android",
                    "fcm_token" to token,
                    "value" to link,
                    "reason" to reason,
                    "time" to TimeUtils.getCurrentTimestamp()
                )

                TreasureData.sharedInstance().addEvent(BuildConfig.TD_TABLE, event)
                logDebug(TAG, getString(R.string.log_event_added, "Link fail ($reason)"))
            } catch (e: Exception) {
                logError(TAG, "Failed to track link_fail event", e)
            }
        }
    }

    // MARK: - Logging Helpers

    private fun logDebug(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(tag, message)
        }
    }

    private fun logWarn(tag: String, message: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.w(tag, message)
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
