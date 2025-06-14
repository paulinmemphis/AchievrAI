// File: ParentalControlManager.swift
import Foundation
import Security
import Combine
import SwiftUI

/// Manages parental control features, primarily the PIN for accessing the Parent Dashboard.
///
/// This class handles setting, verifying, and storing the PIN securely using the keychain.
/// It conforms to `ObservableObject` to publish changes related to PIN status.
class ParentalControlManager: ObservableObject {
    /// Published property indicating whether parent mode is enabled.
    @Published var isParentModeEnabled: Bool = false
    
    /// Published property indicating whether app login is required.
    @Published var isAppLoginRequired: Bool = false
    
    /// Published property indicating whether password login is required at startup.
    @Published var isPasswordLoginRequired: Bool = false
    
    /// AppStorage key for storing the app login requirement preference
    private let appLoginRequiredKey = "com.metacognitive.appLoginRequired"
    
    /// AppStorage key for storing the password login requirement preference
    private let passwordLoginRequiredKey = "com.metacognitive.passwordLoginRequired"
    
    /// The key used to store the PIN in the keychain.
    private let pinKey = "com.metacognitive.parentPIN"
    
    /// Initialize the manager and load saved preferences
    init() {
        // Load the app login requirement preference
        let defaults = UserDefaults.standard
        isAppLoginRequired = defaults.bool(forKey: appLoginRequiredKey)
        
        // Load the password login requirement preference
        // Default to true for security reasons
        isPasswordLoginRequired = defaults.object(forKey: passwordLoginRequiredKey) == nil ? 
            true : defaults.bool(forKey: passwordLoginRequiredKey)
    }

    /// Saves a new PIN to the keychain, replacing any existing one.
    ///
    /// - Parameter pin: The new PIN string to set.
    func savePIN(_ pin: String) {
        guard let pinData = pin.data(using: .utf8) else { return }

        // Delete existing PIN if present
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new PIN entry
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey,
            kSecValueData as String: pinData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Validates the provided PIN against the stored value.
    ///
    /// - Parameter input: The PIN string to verify.
    /// - Returns: `true` if the PIN is correct, `false` otherwise.
    func validatePIN(_ input: String) -> Bool {
        guard let stored = retrievePIN() else { return false }
        return input == stored
    }

    /// Retrieves the stored PIN from the keychain.
    ///
    /// - Returns: The stored PIN string, or `nil` if not found.
    func retrievePIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8)
        else { return nil }

        return pin
    }

    /// Checks if a PIN is already set.
    ///
    /// - Returns: `true` if a PIN is set, `false` otherwise.
    func isPINSet() -> Bool {
        retrievePIN() != nil
    }

    /// Clears the stored PIN.
    func clearPIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Enables parent mode (e.g., after successful PIN validation).
    func enableParentMode() {
        DispatchQueue.main.async { // Ensure UI updates on main thread
            self.isParentModeEnabled = true
        }
    }

    /// Disables parent mode (e.g., when leaving parent sections).
    func disableParentMode() {
        DispatchQueue.main.async { // Ensure UI updates on main thread
            self.isParentModeEnabled = false
        }
    }
    
    /// Sets whether app login is required.
    /// - Parameter required: Boolean indicating whether app login should be required.
    func setAppLoginRequired(_ required: Bool) {
        isAppLoginRequired = required
        UserDefaults.standard.set(required, forKey: appLoginRequiredKey)
        
        // If login is no longer required, reset authentication state
        if !required {
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
    }
    
    /// Checks whether app login is required.
    /// - Returns: Boolean indicating whether app login is required.
    func isLoginRequired() -> Bool {
        return isAppLoginRequired
    }
    
    /// Sets whether password login is required at app startup.
    /// - Parameter required: Boolean indicating whether password login should be required.
    func setPasswordLoginRequired(_ required: Bool) {
        isPasswordLoginRequired = required
        UserDefaults.standard.set(required, forKey: passwordLoginRequiredKey)
    }
    
    /// Checks whether password login is required at app startup.
    /// - Returns: Boolean indicating whether password login is required.
    func getPasswordLoginRequired() -> Bool {
        return isPasswordLoginRequired
    }
}
