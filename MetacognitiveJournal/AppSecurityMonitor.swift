//
//  AppSecurityMonitor.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


import Foundation
import UIKit

class AppSecurityMonitor {
    private static let checksumVerificationInterval: TimeInterval = 30.0
    private static var timer: Timer?
    private static var initialChecksums: [String: String] = [:]

    // MARK: - Start Monitoring
    static func startMonitoring() {
        captureInitialChecksums()

        timer = Timer.scheduledTimer(withTimeInterval: checksumVerificationInterval, repeats: true) { _ in
            verifyRuntimeIntegrity()
        }
    }

    // MARK: - Stop Monitoring
    static func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Capture Initial Checksums
    private static func captureInitialChecksums() {
        initialChecksums = [:]

        let criticalResources = [
            "MainConfiguration": Bundle.main.path(forResource: "MainConfiguration", ofType: "plist"),
            "AppSettings": UserDefaults.standard.string(forKey: "AppSettingsPath")
        ]

        for (name, path) in criticalResources {
            if let path = path, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                initialChecksums[name] = AppIntegrityValidator.generateSHA256(data: data)
            }
        }
    }

    // MARK: - Verify Runtime Integrity
    private static func verifyRuntimeIntegrity() {
        for (name, initialChecksum) in initialChecksums {
            var path: String?

            switch name {
            case "MainConfiguration":
                path = Bundle.main.path(forResource: "MainConfiguration", ofType: "plist")
            case "AppSettings":
                path = UserDefaults.standard.string(forKey: "AppSettingsPath")
            default:
                continue
            }

            if let path = path, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let currentChecksum = AppIntegrityValidator.generateSHA256(data: data)
                if currentChecksum != initialChecksum {
                    handleTamperingDetected(resourceName: name)
                    return
                }
            } else {
                handleTamperingDetected(resourceName: name)
                return
            }
        }
    }

    // MARK: - Handle Tampering
    private static func handleTamperingDetected(resourceName: String) {
        print("Tampering detected: \(resourceName) was modified.")

        // Optional: Clear data
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")

        // Show alert and terminate
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Security Alert",
                message: "This app has detected a potential integrity issue and will restart.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
                exit(0)
            })

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
}
