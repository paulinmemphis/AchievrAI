//
//  SecureLogger.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//


import Foundation
import os.log

struct SecureLogger {
    static func log(_ message: String, level: OSLogType = .default, category: String = "App") {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.metacognitive.app"
        let logger = OSLog(subsystem: subsystem, category: category)
        // Use %{private}@ by default to redact potentially sensitive info in release logs
        os_log("%{private}@", log: logger, type: level, message)
    }

    static func info(_ message: String, category: String = "App") {
        log(message, level: .info, category: category)
    }

    static func debug(_ message: String, category: String = "App") {
        log(message, level: .debug, category: category)
    }

    static func error(_ message: String, category: String = "App") {
        log(message, level: .error, category: category)
    }

    static func fault(_ message: String, category: String = "App") {
        log(message, level: .fault, category: category)
    }

    static func logSecurityEvent(event: String, details: [String: Any] = [:]) {
        let detailsString = details.map { "\($0): \($1)" }.joined(separator: ", ")
        // Keep event name public, but details potentially sensitive
        let message = "[SECURITY] \(event) | Details: \(detailsString)"
        // Log the composite message as private for safety
        log(message, level: .error, category: "Security")
    }
}
