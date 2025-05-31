import SwiftUI
import Combine

/// A modern, visually appealing view for selecting journal prompts based on age group
struct JournalPromptSelectionView: View {
    // MARK: - Properties
    @EnvironmentObject private var userProfile: UserProfile
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var promptManager = AgeAppropriatePromptManager(userProfile: UserProfile())
    
    @State private var selectedCategory: PromptCategory?
    @State private var selectedPrompt: JournalPrompt?
    @State private var isShowingPromptView = false
    @State private var searchText = ""
    @State private var isAnimating = false
    @State private var showWelcomeMessage = true
    @State private var promptResponse = PromptResponse(id: UUID(), prompt: "", options: nil, selectedOption: nil, response: nil)
    
    // MARK: - Computed Properties
    private var uxStyle: UXCustomization {
        promptManager.uiCustomizations
    }
    
    private var isChild: Bool {
        userProfile.ageGroup == .child
    }
    
    private var isTeen: Bool {
        userProfile.ageGroup == .teen
    }
    
    private var filteredPrompts: [JournalPrompt] {
        if searchText.isEmpty {
            if let category = selectedCategory {
                return promptManager.getPrompts(for: category)
            } else {
                return promptManager.currentPrompts
            }
        } else {
            return promptManager.currentPrompts.filter { 
                $0.text.lowercased().contains(searchText.lowercased()) ||
                $0.category.rawValue.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.selectedTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome message
                        if showWelcomeMessage {
                            welcomeMessage
                        }
                        
                        // Categories
                        categorySelector
                        
                        // Prompts
                        promptsGrid
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $isShowingPromptView) {
            if let selectedPrompt = selectedPrompt {
                NavigationView {
                    EnhancedPromptView(promptResponse: $promptResponse)
                        .environmentObject(userProfile)
                        .environmentObject(themeManager)
                        .navigationTitle(isChild ? "My Journal" : "Journal Entry")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    isShowingPromptView = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            // Initialize promptManager with the actual userProfile
            promptManager.updatePromptsForCurrentAgeGroup()
            promptManager.updateUXForCurrentAgeGroup()
            
            // Animate in
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
            
            // Hide welcome message after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showWelcomeMessage = false
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Header view with title and search
    private var headerView: some View {
        VStack(spacing: 15) {
            // Title
            HStack {
                Text(isChild ? "My Journal Prompts" : "Journal Prompts")
                    .font(uxStyle.primaryFont)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                // Random prompt button
                Button(action: selectRandomPrompt) {
                    Label("", systemImage: "shuffle")
                        .font(.title3)
                        .foregroundColor(uxStyle.primaryColor)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(uxStyle.primaryColor.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.selectedTheme.placeholderColor)
                
                TextField(isChild ? "Find a prompt..." : "Search prompts...", text: $searchText)
                    .font(uxStyle.bodyFont)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                    .fill(themeManager.selectedTheme.inputBackgroundColor)
            )
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(themeManager.selectedTheme.backgroundColor)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
    
    /// Welcome message with personalization
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(getWelcomeText())
                        .font(uxStyle.secondaryFont)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text(getSubtitleText())
                        .font(uxStyle.bodyFont)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Avatar or icon
                if uxStyle.useAvatars {
                    Image(systemName: isChild ? "face.smiling.fill" : "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(uxStyle.primaryColor)
                        .padding()
                        .background(
                            Circle()
                                .fill(uxStyle.primaryColor.opacity(0.2))
                        )
                }
            }
            
            // Tip for children
            if isChild {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(uxStyle.secondaryColor)
                    
                    Text("Tap on a card to start writing!")
                        .font(uxStyle.bodyFont)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Category selector
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(isChild ? "Pick a category:" : "Categories")
                .font(uxStyle.secondaryFont)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // All category
                    categoryButton(nil, name: "All")
                    
                    // Other categories
                    ForEach(PromptCategory.allCases) { category in
                        categoryButton(category, name: category.rawValue)
                    }
                }
                .padding(.horizontal)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Category button
    private func categoryButton(_ category: PromptCategory?, name: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            HStack {
                if let category = category {
                    Image(systemName: category.iconName)
                        .foregroundColor(selectedCategory == category ? .white : category.color)
                } else {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundColor(selectedCategory == nil ? .white : uxStyle.primaryColor)
                }
                
                Text(name)
                    .font(uxStyle.bodyFont)
                    .foregroundColor(
                        (selectedCategory == category || (selectedCategory == nil && category == nil)) 
                        ? .white 
                        : themeManager.selectedTheme.textColor
                    )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                    .fill(
                        (selectedCategory == category || (selectedCategory == nil && category == nil))
                        ? (category?.color ?? uxStyle.primaryColor)
                        : themeManager.selectedTheme.cardBackgroundColor
                    )
            )
            .shadow(
                color: (selectedCategory == category || (selectedCategory == nil && category == nil))
                ? (category?.color ?? uxStyle.primaryColor).opacity(0.3)
                : Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2
            )
        }
    }
    
    /// Prompts grid
    private var promptsGrid: some View {
        VStack(alignment: .leading, spacing: 15) {
            if searchText.isEmpty && selectedCategory == nil {
                Text(isChild ? "Today's Prompts:" : "Featured Prompts")
                    .font(uxStyle.secondaryFont)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .padding(.horizontal)
            } else if !filteredPrompts.isEmpty {
                Text("\(filteredPrompts.count) \(filteredPrompts.count == 1 ? "Prompt" : "Prompts")")
                    .font(uxStyle.secondaryFont)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .padding(.horizontal)
            }
            
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(filteredPrompts) { prompt in
                        promptCard(prompt)
                            .onTapGesture {
                                selectPrompt(prompt)
                            }
                    }
                }
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(uxStyle.secondaryColor.opacity(0.5))
            
            Text(isChild ? "No prompts found" : "No matching prompts found")
                .font(uxStyle.secondaryFont)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            Button(action: {
                searchText = ""
                selectedCategory = nil
            }) {
                Text(isChild ? "Show all prompts" : "Clear filters")
                    .font(uxStyle.bodyFont)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                            .fill(uxStyle.primaryColor)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    /// Prompt card
    private func promptCard(_ prompt: JournalPrompt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category and emoji
            HStack {
                Text(prompt.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(prompt.category.color)
                
                Spacer()
                
                if uxStyle.useEmojis {
                    Text(prompt.category.emoji)
                        .font(.title3)
                }
            }
            
            // Prompt text
            Text(prompt.text)
                .font(uxStyle.bodyFont)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Button or indicator
            HStack {
                Spacer()
                
                Image(systemName: isChild ? "pencil.circle.fill" : "chevron.right.circle.fill")
                    .foregroundColor(prompt.category.color)
                    .font(.title3)
            }
        }
        .frame(height: 160)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .stroke(prompt.category.color.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Get personalized welcome text based on age group
    private func getWelcomeText() -> String {
        let name = userProfile.name
        
        switch userProfile.ageGroup {
        case .child:
            return "Hey \(name)! 👋 Ready to journal?"
        case .teen:
            return "What's up, \(name)!"
        case .adult, .parent:
            return "Welcome, \(name)"
        }
    }
    
    /// Get subtitle text based on age group
    private func getSubtitleText() -> String {
        switch userProfile.ageGroup {
        case .child:
            return "Pick a fun prompt to get started!"
        case .teen:
            return "What's on your mind today?"
        case .adult, .parent:
            return "Select a prompt to begin your journal entry."
        }
    }
    
    /// Select a random prompt
    private func selectRandomPrompt() {
        let randomPrompt = promptManager.getRandomPrompt()
        selectPrompt(randomPrompt)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Select a prompt and show the prompt view
    private func selectPrompt(_ prompt: JournalPrompt) {
        selectedPrompt = prompt
        
        // Create a new prompt response
        promptResponse = PromptResponse(
            id: UUID(),
            prompt: prompt.text,
            options: nil, // Pass nil as JournalPrompt has no options
            selectedOption: nil,
            response: nil
        )
        
        // Show the prompt view
        isShowingPromptView = true
    }
}

// MARK: - Preview
struct JournalPromptSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Child preview
            childPreview
                .previewDisplayName("Child (6-12)")
            
            // Teen preview
            teenPreview
                .previewDisplayName("Teen (13-17)")
            
            // Adult preview
            adultPreview
                .previewDisplayName("Adult (18+)")
        }
        .environmentObject(ThemeManager())
    }
    
    static var childPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.child)
        
        return JournalPromptSelectionView()
            .environmentObject(userProfile)
    }
    
    static var teenPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.teen)
        
        return JournalPromptSelectionView()
            .environmentObject(userProfile)
    }
    
    static var adultPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.adult)
        
        return JournalPromptSelectionView()
            .environmentObject(userProfile)
    }
}
