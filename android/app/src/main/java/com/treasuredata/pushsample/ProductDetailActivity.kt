package com.treasuredata.pushsample

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.treasuredata.pushsample.databinding.ActivityProductDetailBinding
import org.json.JSONObject

class ProductDetailActivity : AppCompatActivity() {

    private lateinit var binding: ActivityProductDetailBinding

    companion object {
        private const val TAG = "ProductDetailActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityProductDetailBinding.inflate(layoutInflater)
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
            val productId = binding.productIdTextView.text.toString()
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                putExtra(Intent.EXTRA_TEXT, "Check out this product: ${BuildConfig.DEEP_LINK_SCHEME}://product/$productId")
                type = "text/plain"
            }
            startActivity(Intent.createChooser(shareIntent, getString(R.string.share_product)))
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

        // Extract product ID from deep link
        val data: Uri? = intent.data
        val productId = data?.lastPathSegment ?: intent.getStringExtra("productId") ?: "unknown"

        // Extract campaign tracking info
        val campaignId = intent.getStringExtra("campaign_id") ?: ""
        val messageId = intent.getStringExtra("message_id") ?: ""

        updateProductInfo(productId, campaignId, messageId)
    }

    private fun updateProductInfo(productId: String, campaignId: String, messageId: String) {
        binding.productIdTextView.text = productId
        binding.productNameTextView.text = getString(R.string.product_name_format, productId)
        binding.productDescriptionTextView.text = getString(R.string.product_description_format, productId)

        if (campaignId.isNotEmpty()) {
            binding.campaignInfoTextView.text = getString(R.string.campaign_info_format, campaignId, messageId)
        } else {
            binding.campaignInfoTextView.text = getString(R.string.opened_directly)
        }

        logDebug(TAG, "Product details loaded - ID: $productId, Campaign: $campaignId, Message: $messageId")
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
