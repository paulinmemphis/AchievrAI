import Foundation
import LocalAuthentication
import SwiftUI

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showLockScreen = false
    
    init() {
        // Check authentication status when app starts
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Get the stored authentication state
        let defaults = UserDefaults.standard
        let wasAuthenticated = defaults.bool(forKey: "isAuthenticated")
        
        // If previously authenticated, don't show lock screen
        if wasAuthenticated {
            isUnlocked = true
            showLockScreen = false
        } else {
            // Otherwise, show lock screen if biometrics are available
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                showLockScreen = true
                isUnlocked = false
            } else {
                // If biometrics aren't available, don't show lock screen
                showLockScreen = false
                isUnlocked = true
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your journal") { success, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        ErrorHandler.shared.handle(authError, type: { msg in JournalAppError.internalError(message: "Biometric authentication failed: \(msg)") })
                    }
                    self.isUnlocked = success
                    self.showLockScreen = !success
                    
                    // Save authentication state if successful
                    if success {
                        UserDefaults.standard.set(true, forKey: "isAuthenticated")
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                if let error = error {
                    ErrorHandler.shared.handle(error, type: { msg in JournalAppError.internalError(message: "Biometric authentication unavailable: \(msg)") })
                }
                self.showLockScreen = false // fallback if biometrics unavailable
                self.isUnlocked = true
            }
        }
    }
}

struct AppLockView: View {
    @ObservedObject var appLock: AppLockManager
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Unlock Journal")
                .font(.title2)
            Button("Unlock with Face ID / Touch ID") {
                appLock.authenticate()
            }
            .padding()
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
