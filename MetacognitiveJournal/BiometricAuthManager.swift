//
//  BiometricAuthManager.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// BiometricAuthManager.swift
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    private init() {}

    func authenticateUser(reason: String = "Unlock MetacognitiveJournal", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if biometrics are available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }

    func biometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
}