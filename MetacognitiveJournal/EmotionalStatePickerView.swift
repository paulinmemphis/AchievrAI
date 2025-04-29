import SwiftUI

struct EmotionalStatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedState: EmotionalState
    
    var body: some View {
        NavigationView {
            List {
                ForEach(EmotionalState.allCases, id: \.self) { state in
                    Button(action: {
                        selectedState = state
                        dismiss()
                    }) {
                        HStack {
                            Text(state.emoji)
                                .font(.title2)
                            
                            Text(state.rawValue)
                                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                            
                            Spacer()
                            
                            if state == selectedState {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("How do you feel?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
