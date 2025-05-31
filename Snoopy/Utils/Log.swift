//
//  Log.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-03-09.
//

import Foundation
import os

enum Log {
    private static let logger = Logger(subsystem: "com.ycheng.Snoopy", category: "UI")
    
    /// Logs a message at the debug level.
    public static func debug(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        // Construct the final log message *inside* the wrapper
        logger.debug("\(message) -- [\(file):\(line) - \(function)]")
    }
    
    /// Logs a message at the info level.
    public static func info(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.info("\(message) -- [\(file):\(line) - \(function)]")
    }
    
    /// Logs a message at the notice level (persisted by default).
    public static func notice(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.notice("\(message) -- [\(file):\(line) - \(function)]")
    }
    
    /// Logs an error message, optionally including an Error object. (Persisted by default).
    public static func error(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        let location = "[\(file):\(line) - \(function)]" // Capture call site info
        
        if let error = error {
            // Log both the custom message and the error details
            // Note: error.localizedDescription might contain sensitive info depending on the error.
            // Consider privacy carefully. Using `\(error, privacy: .private)` logs the object details privately.
            logger.error("\(message) | Error: \(error.localizedDescription, privacy: .private(mask: .hash)) | Location: \(location) | Full Error: \(error, privacy: .private)")
        } else {
            logger.error("\(message) | Location: \(location)")
        }
    }
    
    /// Logs a critical fault message. (Persisted by default).
    public static func fault(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) -> Never {
        logger.fault("\(message) -- [\(file):\(line) - \(function)]")
        fatalError("\(message) -- [\(file):\(line) - \(function)")
    }
}

/// unreachable indicates this part of the code should never be reached.
/// This function will print out the message and exit the program.
func unreachable(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) -> Never {
    fatalError("[UNREACHABLE]: \(message) -- [\(file):\(line) - \(function)]")
}
