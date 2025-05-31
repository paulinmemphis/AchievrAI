import SwiftUI

struct PromptResponseView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let prompt: PromptResponse
    let onDelete: () -> Void
    let onResponseChanged: (String) -> Void
    
    @State private var responseText: String
    
    init(prompt: PromptResponse, onDelete: @escaping () -> Void, onResponseChanged: @escaping (String) -> Void) {
        self.prompt = prompt
        self.onDelete = onDelete
        self.onResponseChanged = onResponseChanged
        self._responseText = State(initialValue: prompt.response ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.prompt)
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            TextEditor(text: $responseText)
                .frame(minHeight: 100)
                .padding(8)
                .background(themeManager.selectedTheme.cardBackgroundColor)
                .cornerRadius(8)
                .onChange(of: responseText) { newValue in
                    // Call the response changed callback
                    onResponseChanged(newValue)
                }
        }
        .padding(.vertical, 4)
    }
}

// Preview
struct PromptResponseView_Previews: PreviewProvider {
    static var previews: some View {
        PromptResponseView(
            prompt: PromptResponse(
                id: UUID(),
                prompt: "What did you learn today?",
                response: "I learned about SwiftUI and how to create custom views."
            ),
            onDelete: {},
            onResponseChanged: { _ in }
        )
        .environmentObject(ThemeManager())
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
