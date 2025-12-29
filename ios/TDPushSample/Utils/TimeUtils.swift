import Foundation

/// Utility class for timestamp generation
/// Thread-safe singleton for consistent ISO 8601 timestamp formatting
class TimeUtils {

    static let shared = TimeUtils()

    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private init() {}

    /// Get current timestamp in ISO 8601 format (UTC)
    /// Thread-safe: DateFormatter is thread-safe in iOS 7+
    func getCurrentTimestamp() -> String {
        return timestampFormatter.string(from: Date())
    }
}
