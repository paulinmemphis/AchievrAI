import Foundation
import LocalAuthentication
import SwiftUI

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showLockScreen = false
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your journal") { success, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        ErrorHandler.shared.handle(authError, type: { msg in AppError.internalError(message: "Biometric authentication failed: \(msg)") })
                    }
                    self.isUnlocked = success
                    self.showLockScreen = !success
                }
            }
        } else {
            DispatchQueue.main.async {
                if let error = error {
                    ErrorHandler.shared.handle(error, type: { msg in AppError.internalError(message: "Biometric authentication unavailable: \(msg)") })
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
