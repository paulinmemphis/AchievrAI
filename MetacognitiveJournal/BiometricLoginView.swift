//
//  BiometricLoginView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


import SwiftUI

struct BiometricLoginView: View {
    @State private var isUnlocked = false
    @State private var authError: String?

    var body: some View {
        VStack(spacing: 20) {
            if isUnlocked {
                Text("Welcome to MetacognitiveJournal!")
            } else {
                Text("Authenticate to continue")
                Button("Unlock with Biometrics") {
                    BiometricAuthManager.shared.authenticateUser { success, error in
                        if success {
                            isUnlocked = true
                        } else {
                            authError = error?.localizedDescription ?? "Authentication failed"
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                if let authError = authError {
                    Text(authError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}