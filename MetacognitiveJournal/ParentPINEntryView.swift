// File: ParentPINEntryView.swift
import SwiftUI

/// View for entering or resetting the parental control PIN.
struct ParentPINEntryView: View {
    @ObservedObject var parentalControlManager: ParentalControlManager
    @Environment(\.dismiss) private var dismiss

    @State private var pinInput: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        Form {
            Section(header: Text("Enter Parent PIN")) {
                SecureField("PIN", text: $pinInput)
                    .keyboardType(.numberPad)
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                Button("Submit") {
                    submitPIN()
                }
                .disabled(pinInput.isEmpty)
            }

            if parentalControlManager.isPINSet() {
                Section(header: Text("Reset PIN")) {
                    Button("Clear Current PIN") {
                        parentalControlManager.clearPIN()
                        errorMessage = nil
                        pinInput = ""
                    }
                }
            }
        }
        .navigationTitle("Parent PIN")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Reset fields when view appears
            pinInput = ""
            errorMessage = nil
        }
    }

    private func submitPIN() {
        if parentalControlManager.validatePIN(pinInput) {
            // Correct PIN: enable parent mode and dismiss
            parentalControlManager.enableParentMode()
            dismiss()
        } else {
            // Incorrect PIN
            errorMessage = "Incorrect PIN. Please try again."
        }
    }
}

// MARK: - Preview
struct ParentPINEntryView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @StateObject var manager = ParentalControlManager()
        
        var body: some View {
            NavigationView {
                ParentPINEntryView(parentalControlManager: manager)
                    .environmentObject(manager)
            }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
