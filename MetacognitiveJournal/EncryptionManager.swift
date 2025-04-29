import Foundation
import UIKit
import CryptoKit
import CommonCrypto

class EncryptionManager {
    // Define the salt length (e.g., 16 bytes)
    private static let saltByteCount = 16
    // Define the key derivation iteration count
    private static let pbkdf2IterationCount = 10000

    // Derives a symmetric key from a password using PBKDF2
    private static func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let key = pbkdf2SHA256(password: passwordData, salt: salt, keyByteCount: 32, rounds: pbkdf2IterationCount)
        return SymmetricKey(data: key)
    }
    
    // PBKDF2 using CommonCrypto
    private static func pbkdf2SHA256(password: Data, salt: Data, keyByteCount: Int, rounds: Int) -> Data {
        var derivedKey = Data(repeating: 0, count: keyByteCount)
        derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    let status = CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress!.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyBytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        keyByteCount
                    )
                    assert(status == kCCSuccess)
                }
            }
        }
        return derivedKey
    }

    // Generates a random salt
    private static func generateSalt() -> Data {
        var salt = Data(count: saltByteCount)
        _ = salt.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, saltByteCount, pointer.baseAddress!)
        }
        return salt
    }

    // Encrypts text using AES.GCM with a unique salt
    func encrypt(text: String, password: String) -> Data? {
        guard let dataToEncrypt = text.data(using: .utf8) else { return nil }

        // Generate a unique salt for this encryption
        let salt = EncryptionManager.generateSalt()
        let symmetricKey = EncryptionManager.deriveKey(password: password, salt: salt)

        do {
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: symmetricKey)
            guard let combined = sealedBox.combined else {
                print("Encryption failed: Could not get combined sealed box data.")
                return nil
            }
            // Prepend the salt to the combined data (nonce + ciphertext + tag)
            return salt + combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }

    // Decrypts data using AES.GCM, extracting the salt first
    func decrypt(encryptedDataWithSalt: Data, password: String) -> String? {
        // Ensure the data is long enough to contain the salt
        guard encryptedDataWithSalt.count > EncryptionManager.saltByteCount else {
            print("Decryption failed: Data too short to contain salt.")
            return nil
        }

        // Extract the salt from the beginning of the data
        let salt = encryptedDataWithSalt.prefix(EncryptionManager.saltByteCount)
        // Extract the actual encrypted payload (nonce + ciphertext + tag)
        let encryptedPayload = encryptedDataWithSalt.dropFirst(EncryptionManager.saltByteCount)

        // Derive the key using the extracted salt
        let symmetricKey = EncryptionManager.deriveKey(password: password, salt: salt)

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedPayload)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil // Decryption failed (wrong password, corrupted data, etc.)
        }
    }
}

extension EncryptionManager {
    // Static convenience methods
    static func encrypt(_ text: String, with password: String) -> Data? {
        let manager = EncryptionManager()
        return manager.encrypt(text: text, password: password)
    }

    // Renamed parameter for clarity
    static func decrypt(_ dataWithSalt: Data, with password: String) -> String? {
        let manager = EncryptionManager()
        return manager.decrypt(encryptedDataWithSalt: dataWithSalt, password: password)
    }
}
