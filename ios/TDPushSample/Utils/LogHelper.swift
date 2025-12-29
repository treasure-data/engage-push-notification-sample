import Foundation
import os.log

/// Logging helper for conditional debug logging
/// Logs are only output in DEBUG builds
class LogHelper {

    /// Log debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (default: current file)
    ///   - function: Function name (default: current function)
    ///   - line: Line number (default: current line)
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        NSLog("[DEBUG] [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Log error message
    /// - Parameters:
    ///   - message: The error message to log
    ///   - error: Optional error object
    ///   - file: Source file (default: current file)
    ///   - function: Function name (default: current function)
    ///   - line: Line number (default: current line)
    static func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            NSLog("[ERROR] [\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            NSLog("[ERROR] [\(fileName):\(line)] \(function) - \(message)")
        }
        #endif
    }

    /// Log warning message
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - file: Source file (default: current file)
    ///   - function: Function name (default: current function)
    ///   - line: Line number (default: current line)
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        NSLog("[WARNING] [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }
}
