//
//  ParentPINSetupView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/20/25.
//


import SwiftUI

struct ParentPINSetupView: View {
    @ObservedObject var parentalControlManager: ParentalControlManager
    @Environment(\.dismiss) var dismiss

    @State private var newPIN: String = ""
    @State private var confirmPIN: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set a 4-digit PIN")) {
                    SecureField("Enter new PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                    SecureField("Confirm PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }

                Section {
                    Button("Save PIN") {
                        validateAndSavePIN()
                    }
                    .disabled(newPIN.count != 4 || confirmPIN.count != 4)
                }
            }
            .navigationTitle("Parent PIN Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func validateAndSavePIN() {
        guard newPIN == confirmPIN else {
            errorMessage = "PINs do not match."
            successMessage = nil
            return
        }

        parentalControlManager.savePIN(newPIN)
        errorMessage = nil
        successMessage = "PIN saved successfully!"
        newPIN = ""
        confirmPIN = ""
    }
}