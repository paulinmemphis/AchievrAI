//
//  AppDelegate.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// AppDelegate.swift (Enhanced)
// MetacognitiveJournal

import UIKit
import LocalAuthentication

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestBiometricAuthenticationIfNeeded()
        setupSecurityMeasures()
        return true
    }

    private func requestBiometricAuthenticationIfNeeded() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Metacognitive Journal") { success, authError in
                if !success {
                    DispatchQueue.main.async {
                        self.promptForFallbackPIN()
                    }
                }
            }
        } else {
            promptForFallbackPIN()
        }
    }

    private func promptForFallbackPIN() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Enter PIN", message: "Biometric authentication failed. Please enter your fallback PIN.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "PIN"
                textField.isSecureTextEntry = true
                textField.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
                let enteredPIN = alert.textFields?.first?.text ?? ""
                if enteredPIN != "1234" { // Example: replace with secure storage or Keychain
                    exit(0)
                }
            })
            self.window?.rootViewController?.present(alert, animated: true)
        }
    }

    private func setupSecurityMeasures() {
        DispatchQueue.global(qos: .userInitiated).async {
            if SecurityUtils.isDeviceJailbroken() {
                self.handleSecurityViolation(reason: "jailbreak_detected")
                return
            }
            #if !DEBUG
            if SecurityUtils.isBeingDebugged() {
                self.handleSecurityViolation(reason: "debugger_detected")
                return
            }
            #endif
            if !AppIntegrityValidator.verifyBundledResources() ||
               !AppIntegrityValidator.verifyCodeSignature() {
                self.handleSecurityViolation(reason: "tampering_detected")
                return
            }
            DispatchQueue.main.async {
                AppSecurityMonitor.startMonitoring()
                SecureLogger.logSecurityEvent(event: "Security measures initialized successfully")
            }
        }
    }

    private func handleSecurityViolation(reason: String) {
        SecureLogger.logSecurityEvent(event: "Security violation", details: ["reason": reason])
        DispatchQueue.main.async {
            self.clearSensitiveData()
            self.showSecurityAlert(reason: reason)
        }
    }

    private func clearSensitiveData() {
        try? KeychainManager.delete(key: "authToken")
        try? KeychainManager.delete(key: "userCredentials")
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    private func showSecurityAlert(reason: String) {
        let message = "Security issue detected: \(reason). The app will close."
        let alert = UIAlertController(title: "Security Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in exit(0) })

        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let rootVC = scene?.windows.first?.rootViewController
        rootVC?.present(alert, animated: true)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        addSecurityOverlay()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        removeSecurityOverlay()
        DispatchQueue.global(qos: .userInitiated).async {
            if !AppIntegrityValidator.verifyBundledResources() ||
               !AppIntegrityValidator.verifyCodeSignature() {
                self.handleSecurityViolation(reason: "tampering_detected_on_resume")
            }
        }
    }

    private func addSecurityOverlay() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .black
        overlay.tag = 9999

        let label = UILabel()
        label.text = "Application Locked"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        window.addSubview(overlay)
    }

    private func removeSecurityOverlay() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if let overlay = window.viewWithTag(9999) {
            overlay.removeFromSuperview()
        }
    }
}
