import SwiftUI

/// A view that allows children to select a theme appropriate for their age
struct ChildThemeSelector: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    let journalMode: ChildJournalMode
    
    // MARK: - State
    @State private var selectedTheme: ThemeManager.ChildTheme
    @State private var showConfetti = false
    
    // MARK: - Initialization
    init(journalMode: ChildJournalMode) {
        self.journalMode = journalMode
        // Initialize with the current selected theme
        _selectedTheme = State(initialValue: UserDefaults.standard.string(forKey: "childSelectedTheme").flatMap { ThemeManager.ChildTheme(rawValue: $0) } ?? .rainbow)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Choose Your Theme")
                    .font(fontForAge(size: 28, weight: .bold))
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                    .padding(.top, 20)
                
                // Theme grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(ThemeManager.ChildTheme.allCases) { theme in
                            if theme.isAppropriateFor(mode: journalMode) {
                                themeCard(theme)
                            }
                        }
                    }
                    .padding()
                }
                
                // Save button
                Button(action: {
                    saveTheme()
                }) {
                    Text("Save My Theme")
                        .font(fontForAge(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            Capsule()
                                .fill(selectedTheme.primaryColor)
                        )
                        .shadow(radius: 3)
                }
                .padding(.bottom, 30)
            }
            
            // Confetti animation
            if showConfetti {
                confettiView
            }
        }
        .navigationBarTitle("Theme", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(fontForAge(size: 16, weight: .medium))
                }
            }
        }
    }
    
    // MARK: - Theme Card
    private func themeCard(_ theme: ThemeManager.ChildTheme) -> some View {
        Button(action: {
            withAnimation {
                selectedTheme = theme
            }
        }) {
            VStack(spacing: 12) {
                // Theme icon
                ZStack {
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: theme.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                // Theme name
                Text(theme.rawValue)
                    .font(fontForAge(size: 16, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                
                // Theme description
                Text(theme.description)
                    .font(fontForAge(size: 12, weight: .regular))
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Color samples
                HStack(spacing: 5) {
                    ForEach(theme.secondaryColors.prefix(4), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.top, 5)
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
                    .shadow(color: selectedTheme == theme ? theme.primaryColor.opacity(0.5) : Color.gray.opacity(0.2), 
                            radius: selectedTheme == theme ? 8 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(selectedTheme == theme ? theme.primaryColor : Color.clear, lineWidth: 3)
            )
            .scaleEffect(selectedTheme == theme ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Confetti View
    private var confettiView: some View {
        // In a real app, this would be a proper confetti animation
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(selectedTheme.secondaryColors.randomElement() ?? .blue)
                    .frame(width: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
    }
    
    // MARK: - Helper Methods
    private func fontForAge(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight, design: .default)
        }
    }
    
    private func saveTheme() {
        // Save the selected theme
        themeManager.setChildTheme(selectedTheme)
        
        // Show success animation
        withAnimation {
            showConfetti = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}

// MARK: - Preview
struct ChildThemeSelector_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChildThemeSelector(journalMode: .middleChildhood)
                .environmentObject(ThemeManager())
        }
    }
}
