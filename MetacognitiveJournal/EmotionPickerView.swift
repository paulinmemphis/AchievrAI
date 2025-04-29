import SwiftUI

/// A view for selecting emotions with age-appropriate UI
struct EmotionPickerView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    var currentMode: ChildJournalMode
    @Binding var selectedMood: MultiModal.Emotion?
    
    // State for the emotion selection
    @State private var selectedCategory: String?
    @State private var selectedIntensity: Int = 3
    
    // MARK: - Emotion Data
    // Organized by categories for better UI presentation
    private let emotionCategories: [String: [String]] = [
        "Joy": ["Happy", "Excited", "Proud", "Grateful", "Peaceful"],
        "Sadness": ["Sad", "Disappointed", "Lonely", "Hurt", "Discouraged"],
        "Anger": ["Angry", "Frustrated", "Annoyed", "Irritated", "Furious"],
        "Fear": ["Worried", "Nervous", "Scared", "Anxious", "Overwhelmed"],
        "Surprise": ["Surprised", "Curious", "Confused", "Amazed", "Interested"]
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header text
                Text(headerText)
                    .font(fontForMode(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.themeForChildMode(currentMode).primaryTextColor)
                    .padding()
                
                // Emotion category selection
                if selectedCategory == nil {
                    emotionCategoryGrid
                } else {
                    // Emotion selection within category
                    emotionSelectionView
                }
            }
            .padding()
            .background(themeManager.themeForChildMode(currentMode).backgroundColor)
            .navigationTitle("How Do You Feel?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                // Back button if category is selected
                if selectedCategory != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Emotion Category Grid
    private var emotionCategoryGrid: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose a feeling category")
                    .font(fontForMode(size: 18))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(Array(emotionCategories.keys.sorted()), id: \.self) { category in
                        emotionCategoryCard(category)
                    }
                }
                .padding()
            }
        }
    }
    
    // Individual emotion category card
    private func emotionCategoryCard(_ category: String) -> some View {
        Button(action: {
            selectedCategory = category
        }) {
            VStack(spacing: 12) {
                // Icon for the category
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(colorForCategory(category))
                    .cornerRadius(currentMode == .earlyChildhood ? 35 : 16)
                
                // Category name
                Text(category)
                    .font(fontForMode(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).primaryTextColor)
            }
            .padding()
            .frame(minWidth: 120, minHeight: 140)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Emotion Selection View
    private var emotionSelectionView: some View {
        VStack(spacing: 24) {
            if let category = selectedCategory {
                Text("Choose how you feel")
                    .font(fontForMode(size: 18))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
                
                // Emotions in the selected category
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(emotionCategories[category] ?? [], id: \.self) { emotion in
                            emotionButton(emotion, category: category)
                        }
                    }
                    .padding()
                }
                
                // Intensity slider
                intensitySlider
            }
        }
    }
    
    // Individual emotion button
    private func emotionButton(_ emotion: String, category: String) -> some View {
        Button(action: {
            selectedMood = MultiModal.Emotion(
                name: emotion,
                intensity: selectedIntensity,
                category: category
            )
            
            // Dismiss after a short delay to show the selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }) {
            HStack {
                // Emotion icon
                Circle()
                    .fill(colorForCategory(category))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .foregroundColor(.white)
                    )
                
                // Emotion name
                Text(emotion)
                    .font(fontForMode(size: 18))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).primaryTextColor)
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Intensity slider
    private var intensitySlider: some View {
        VStack(spacing: 12) {
            Text("How strong is this feeling?")
                .font(fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
            
            // Slider with custom styling
            HStack {
                Text("A little")
                    .font(fontForMode(size: 14))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
                
                Slider(value: Binding(
                    get: { Double(selectedIntensity) },
                    set: { selectedIntensity = Int($0) }
                ), in: 1...5, step: 1)
                .accentColor(selectedCategory.map { colorForCategory($0) } ?? .blue)
                
                Text("A lot")
                    .font(fontForMode(size: 14))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
            }
            
            // Visual indicator of intensity
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { intensity in
                    Circle()
                        .fill(intensity <= selectedIntensity ? 
                              (selectedCategory.map { colorForCategory($0) } ?? .blue) : 
                              Color(.systemGray4))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    // Header text based on age
    private var headerText: String {
        switch currentMode {
        case .earlyChildhood:
            return "How are you feeling right now?"
        case .middleChildhood:
            return "What emotion best describes how you're feeling?"
        case .adolescent:
            return "Select the emotion that most accurately represents your current state."
        }
    }
    
    // Icon for emotion category
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Joy": return "face.smiling"
        case "Sadness": return "cloud.rain"
        case "Anger": return "flame"
        case "Fear": return "exclamationmark.triangle"
        case "Surprise": return "star.circle"
        default: return "questionmark.circle"
        }
    }
    
    // Color for emotion category
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Joy": return .yellow
        case "Sadness": return .blue
        case "Anger": return .red
        case "Fear": return .purple
        case "Surprise": return .orange
        default: return .gray
        }
    }
    
    // Font based on journal mode
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch currentMode {
        case .earlyChildhood:
            return .system(size: size + 2, weight: weight, design: .rounded)
        case .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

// MARK: - Preview
struct EmotionPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionPickerView(
            currentMode: .middleChildhood,
            selectedMood: .constant(nil)
        )
        .environmentObject(ThemeManager())
    }
}
