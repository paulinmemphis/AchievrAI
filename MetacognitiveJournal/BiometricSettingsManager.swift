//
//  BiometricSettingsManager.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// BiometricSettingsManager.swift
// MetacognitiveJournal

import Foundation
import LocalAuthentication
import SwiftUI

class BiometricSettingsManager: ObservableObject {
    @Published var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: "isBiometricEnabled")
        }
    }

    @Published var fallbackPIN: String? {
        didSet {
            UserDefaults.standard.set(fallbackPIN, forKey: "fallbackPIN")
        }
    }

    init() {
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "isBiometricEnabled")
        self.fallbackPIN = UserDefaults.standard.string(forKey: "fallbackPIN")
    }

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        guard isBiometricEnabled else {
            completion(false)
            return
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access secure features"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    func validatePIN(_ inputPIN: String) -> Bool {
        return inputPIN == fallbackPIN
    }
}

// BiometricSettingsView.swift

struct BiometricSettingsView: View {
    @ObservedObject var biometricManager: BiometricSettingsManager
    @State private var pinInput = ""
    @State private var showAlert = false

    var body: some View {
        Form {
            Toggle("Enable Biometric Login", isOn: $biometricManager.isBiometricEnabled)

            SecureField("Set/Update Fallback PIN", text: $pinInput)
                .keyboardType(.numberPad)

            Button("Save PIN") {
                biometricManager.fallbackPIN = pinInput
                showAlert = true
            }
        }
        .navigationTitle("Security Settings")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Saved"), message: Text("Your fallback PIN was updated."), dismissButton: .default(Text("OK")))
        }
    }
}
