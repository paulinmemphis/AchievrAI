import SwiftUI

struct AddPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var promptText = ""
    let onAdd: (String) -> Void
    
    // Predefined prompts that users can select
    let suggestedPrompts = [
        "What did you learn today?",
        "What was challenging?",
        "How will you apply this knowledge?",
        "What connections can you make to previous learning?",
        "What questions do you still have?",
        "What strategies worked well for you?",
        "What would you do differently next time?",
        "How did this experience change your thinking?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Custom prompt input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create a Custom Prompt")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    
                    TextField("Enter your prompt question", text: $promptText)
                        .padding()
                        .background(themeManager.selectedTheme.cardBackgroundColor)
                        .cornerRadius(8)
                    
                    Button(action: {
                        if !promptText.isEmpty {
                            onAdd(promptText)
                            dismiss()
                        }
                    }) {
                        Text("Add Custom Prompt")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(promptText.isEmpty ? Color.gray : themeManager.selectedTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(promptText.isEmpty)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Suggested prompts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or Choose a Suggested Prompt")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(suggestedPrompts, id: \.self) { prompt in
                                Button(action: {
                                    onAdd(prompt)
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(prompt)
                                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(themeManager.selectedTheme.accentColor)
                                    }
                                    .padding()
                                    .background(themeManager.selectedTheme.cardBackgroundColor)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .navigationTitle("Add Reflection Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
