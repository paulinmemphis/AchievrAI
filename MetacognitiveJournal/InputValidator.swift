//
//  InputValidator.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/16/25.
//

import Foundation


// MARK: - Input Validation Helper
struct InputValidator {
    // Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Sanitize user input to prevent injection
    static func sanitizeInput(_ input: String) -> String {
        // Remove potential HTML/script injection
        var sanitized = input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Additional sanitization for SQL injection prevention
        let sqlInjectionPatterns = ["DROP", "DELETE", "UPDATE", "INSERT", "SELECT", "--", ";", "1=1", "'OR'"]
        for pattern in sqlInjectionPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
