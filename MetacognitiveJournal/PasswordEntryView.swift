//
//  PasswordEntryView.swift
//  MetacognitiveJournal
//
//  Created by Cascade on 4/27/25.
//

import SwiftUI

/// A view for the user to enter their existing encryption password when biometrics fail or are unavailable.
struct PasswordEntryView: View {
    @State private var password = ""
    @Binding var errorMessage: String?

    // Callback to notify the parent with the entered password
    var onPasswordEntered: (String) -> Void
    // Callback for when the user cancels or wants to retry biometrics (optional)
    // var onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield") // Or a relevant app icon
                .font(.largeTitle)
                .padding(.bottom)

            Text("Enter Password")
                .font(.title2)

            Text("Enter the password you created to unlock your encrypted journal.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textContentType(.password) // Use existing password type

            if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Unlock Journal") {
                // Basic check before calling back
                guard !password.isEmpty else {
                    errorMessage = "Password cannot be empty."
                    return
                }
                errorMessage = nil // Clear error on new attempt
                onPasswordEntered(password)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .disabled(password.isEmpty)

            // Optional: Add a cancel or retry biometrics button
            // Button("Cancel") { onCancel?() }
            //    .padding(.top, 5)

            Spacer()
        }
        .padding()
    }
}

struct PasswordEntryView_Previews: PreviewProvider {
    @State static var previewError: String? = nil
    @State static var previewErrorNotEmpty: String? = "Preview error message"

    static var previews: some View {
        Group {
            PasswordEntryView(errorMessage: $previewError, onPasswordEntered: { password in
                print("Password entered: \(password)")
            })
            .previewDisplayName("Empty Error")

            PasswordEntryView(errorMessage: $previewErrorNotEmpty, onPasswordEntered: { password in
                print("Password entered: \(password)")
            })
            .previewDisplayName("With Error")
        }
    }
}
