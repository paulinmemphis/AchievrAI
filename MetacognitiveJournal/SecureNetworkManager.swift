//
//  SecureNetworkManager.swift
//  MetacognitiveJournal
//
//  Updated to replace deprecated SecTrustGetCertificateAtIndex

import Foundation

class SecureNetworkManager {
    func validateCertificate(trust: SecTrust) -> Bool {
        // New recommended method for iOS 15+
        if #available(iOS 15.0, *) {
            guard let certChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate], !certChain.isEmpty else {
                return false
            }
            return true
        } else {
            // Fallback for earlier versions
            guard let cert = SecTrustGetCertificateAtIndex(trust, 0) else {
                return false
            }
            let certData = SecCertificateCopyData(cert) as Data
            return !certData.isEmpty
        }
    }
}
