import Foundation
import CryptoKit
import LocalAuthentication

// MARK: - Security Service
class SecurityService {
    static let shared = SecurityService()
    
    private let encryptionKeyTag = "com.metacognitivejournal.encryptionKey"
    private var cachedKey: SymmetricKey?
    
    private init() {}
    
    // MARK: - Encryption/Decryption
    
    /// Encrypt data using AES-GCM
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    /// Decrypt data using AES-GCM
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Biometric Authentication
    
    /// Authenticate user with biometrics
    func authenticateWithBiometrics(reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        let error = NSError(domain: "SecurityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
                        completion(.failure(error))
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        let error = NSError(domain: "SecurityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
                        completion(.failure(error))
                    }
                }
            }
        } else {
            // No authentication available
            let error = NSError(domain: "SecurityService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No authentication method available"])
            completion(.failure(error))
        }
    }
    
    // MARK: - Key Management
    
    /// Get or create the encryption key from Keychain
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Check cache
        if let key = cachedKey {
            return key
        }
        
        // Try keychain
        do {
            let keyData = try KeychainManager.retrieve(key: encryptionKeyTag)
            let key = SymmetricKey(data: keyData)
            cachedKey = key
            return key
        } catch KeychainManager.KeychainError.itemNotFound {
            // Key not found, create a new one
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            do {
                try KeychainManager.save(key: encryptionKeyTag, data: keyData)
                cachedKey = newKey
                return newKey
            } catch {
                // Handle save error
                throw JournalAppError.internalError(message: "Failed to save new encryption key: \(error.localizedDescription)")
            }
        } catch {
            // Handle other keychain errors
            throw JournalAppError.internalError(message: "Failed to retrieve encryption key: \(error.localizedDescription)")
        }
    }
}
