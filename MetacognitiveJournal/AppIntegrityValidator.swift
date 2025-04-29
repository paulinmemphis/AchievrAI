//
//  AppIntegrityValidator.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//


//
//  AppIntegrityValidator.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//

import Foundation
import CommonCrypto

#if os(macOS)
import Security
#endif

class AppIntegrityValidator {
    // Generate SHA-256 hash of given data
    static func generateSHA256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // Verify the integrity of a specific file
    static func verifyFileIntegrity(filePath: String, expectedHash: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return false
        }

        let calculatedHash = generateSHA256(data: data)
        return calculatedHash == expectedHash
    }

    // Verify the integrity of bundled resources
    static func verifyBundledResources() -> Bool {
        let criticalResources: [String: String] = [
            "MainConfiguration.plist": "expected_hash_1",
            "CriticalDatabase.sqlite": "expected_hash_2"
        ]

        for (resource, expectedHash) in criticalResources {
            guard let path = Bundle.main.path(forResource: resource, ofType: nil) else {
                return false
            }

            if !verifyFileIntegrity(filePath: path, expectedHash: expectedHash) {
                return false
            }
        }

        return true
    }

    // Perform runtime code signature validation (macOS only)
    static func verifyCodeSignature() -> Bool {
        #if os(macOS)
        let bundlePath = Bundle.main.bundlePath
        let bundleURL = NSURL(fileURLWithPath: bundlePath)

        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(bundleURL, [], &staticCode)

        guard status == errSecSuccess, let code = staticCode else {
            return false
        }

        let validationStatus = SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: 0), nil)
        return validationStatus == errSecSuccess
        #else
        // Not supported on iOS
        return true
        #endif
    }
}
