package com.treasuredata.pushsample

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.treasuredata.pushsample.databinding.ActivityCategoryBinding
import org.json.JSONObject

class CategoryActivity : AppCompatActivity() {

    private lateinit var binding: ActivityCategoryBinding

    companion object {
        private const val TAG = "CategoryActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCategoryBinding.inflate(layoutInflater)
        setContentView(binding.root)

        logDebug(TAG, "onCreate called")

        setupUI()
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        logDebug(TAG, "onNewIntent called")
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun setupUI() {
        binding.backButton.setOnClickListener {
            finish()
        }

        binding.shareButton.setOnClickListener {
            val categoryId = binding.categoryIdTextView.text.toString()
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                putExtra(Intent.EXTRA_TEXT, "Check out this category: ${BuildConfig.DEEP_LINK_SCHEME}://category/$categoryId")
                type = "text/plain"
            }
            startActivity(Intent.createChooser(shareIntent, getString(R.string.share_category)))
        }

        // Example product items
        binding.productItem1.setOnClickListener {
            navigateToProduct("PROD001")
        }
        binding.productItem2.setOnClickListener {
            navigateToProduct("PROD002")
        }
        binding.productItem3.setOnClickListener {
            navigateToProduct("PROD003")
        }
    }

    private fun handleDeepLink(intent: Intent?) {
        if (intent == null) {
            logDebug(TAG, "Intent is null")
            return
        }

        // Log intent as JSON
        logDebug(TAG, "========== Intent (JSON) ==========")
        try {
            val intentJson = JSONObject().apply {
                put("action", intent.action)
                put("data", intent.data?.toString())
                put("scheme", intent.data?.scheme)
                put("host", intent.data?.host)
                put("path", intent.data?.path)
                put("pathSegments", intent.data?.pathSegments?.toString())
            }
            logDebug(TAG, intentJson.toString(2))
        } catch (e: Exception) {
            logError(TAG, "Error formatting Intent as JSON", e)
        }
        logDebug(TAG, "===================================")

        // Extract category ID from deep link
        val data: Uri? = intent.data
        val categoryId = data?.lastPathSegment ?: intent.getStringExtra("categoryId") ?: "unknown"

        // Extract campaign tracking info
        val campaignId = intent.getStringExtra("campaign_id") ?: ""
        val messageId = intent.getStringExtra("message_id") ?: ""

        updateCategoryInfo(categoryId, campaignId, messageId)
    }

    private fun updateCategoryInfo(categoryId: String, campaignId: String, messageId: String) {
        binding.categoryIdTextView.text = categoryId
        binding.categoryNameTextView.text = getString(R.string.category_name_format, categoryId)
        binding.categoryDescriptionTextView.text = getString(R.string.category_description_format, categoryId)

        if (campaignId.isNotEmpty()) {
            binding.campaignInfoTextView.text = getString(R.string.campaign_info_format, campaignId, messageId)
        } else {
            binding.campaignInfoTextView.text = getString(R.string.opened_directly)
        }

        logDebug(TAG, "Category details loaded - ID: $categoryId, Campaign: $campaignId, Message: $messageId")
    }

    private fun navigateToProduct(productId: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("${BuildConfig.DEEP_LINK_SCHEME}://product/$productId"))
        startActivity(intent)
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
