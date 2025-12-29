package com.treasuredata.pushsample.utils

import java.text.SimpleDateFormat
import java.util.*

/**
 * Utility class for timestamp generation
 * Thread-safe singleton for consistent ISO 8601 timestamp formatting
 */
object TimeUtils {

    private val timestampFormat = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        Locale.US
    ).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    /**
     * Get current timestamp in ISO 8601 format (UTC)
     * Thread-safe: synchronized to prevent concurrent access to SimpleDateFormat
     */
    @Synchronized
    fun getCurrentTimestamp(): String = timestampFormat.format(Date())
}
