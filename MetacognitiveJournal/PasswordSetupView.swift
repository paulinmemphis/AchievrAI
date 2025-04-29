//
//  PasswordSetupView.swift
//  MetacognitiveJournal
//
//  Created by Cascade on 4/27/25.
//

import SwiftUI

/// A view for the user to set their initial encryption password.
struct PasswordSetupView: View {
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil

    // Callback to notify the parent when the password is set
    var onPasswordSet: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Your Journal Password")
                .font(.title)
                .padding(.bottom)

            Text("Create a strong password to encrypt your journal entries. This password cannot be recovered if lost.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Enter Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textContentType(.newPassword)

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textContentType(.newPassword)

            if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Set Password") {
                setPassword()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .disabled(password.isEmpty || confirmPassword.isEmpty)

            Spacer()
        }
        .padding()
    }

    private func setPassword() {
        errorMessage = nil // Clear previous errors

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        // Basic password strength check (example - enhance as needed)
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long."
            return
        }

        // If validation passes, call the callback
        onPasswordSet(password)
    }
}

struct PasswordSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordSetupView(onPasswordSet: { password in
            print("Password set: \(password)")
        })
    }
}
