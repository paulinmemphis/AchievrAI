//
//  PromptView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//
// File: PromptView.swift
import SwiftUI

/// A view for displaying and editing a single PromptResponse.
struct PromptView: View {
    @Binding var promptResponse: PromptResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prompt text
            Text(promptResponse.prompt)
                .font(.headline)

            // If there are predefined options, show a Picker
            if let options = promptResponse.options, !options.isEmpty {
                Picker("Select an option", selection: Binding(
                    get: { promptResponse.selectedOption ?? "" },
                    set: { promptResponse.selectedOption = $0 }
                )) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Free-text response
            Section(header: Text("Your Response")) {
                TextEditor(text: Binding(
                    get: { promptResponse.response ?? "" },
                    set: { promptResponse.response = $0 }
                ))
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            // Optional feedback: show Save button only when non-empty
            if let resp = promptResponse.response, !resp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: saveResponse) {
                    Text("Save Response")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }

    // MARK: - Actions
    private func saveResponse() {
        // Persist changes if needed, e.g., update your store or view model
        // For example:
        // journalStore.updatePromptResponse(promptResponse)
    }
}

// MARK: - Preview
struct PromptView_Previews: PreviewProvider {
    @State static var sample = PromptResponse(
        id: UUID(),
        prompt: "What challenged you most?",
        options: ["Time management", "Complexity", "Resources"],
        selectedOption: nil,
        response: nil
    )

    static var previews: some View {
        NavigationView {
            PromptView(promptResponse: $sample)
        }
    }
}

