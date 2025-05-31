import Foundation
import SwiftUI
import Combine

/// Manages age-appropriate journal prompts and UX customizations for different age groups
class AgeAppropriatePromptManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPrompts: [JournalPrompt] = []
    @Published var uiCustomizations: UXCustomization = UXCustomization(
        primaryFont: .title,
        secondaryFont: .headline,
        bodyFont: .body,
        primaryColor: .blue,
        secondaryColor: .orange,
        accentColor: .green,
        backgroundColor: .white,
        cornerRadius: 12,
        animationsEnabled: true,
        soundEffectsEnabled: false,
        useEmojis: true,
        useStickerRewards: false,
        useAvatars: false,
        useGameElements: false,
        textEntryPrompt: "Enter your response...",
        saveButtonText: "Save",
        congratsMessage: "Entry saved.",
        buttonStyle: .standard
    )
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userProfile: UserProfile
    
    // MARK: - Initialization
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        
        // Listen for changes to age group
        userProfile.objectWillChange
            .sink { [weak self] _ in
                self?.updatePromptsForCurrentAgeGroup()
                self?.updateUXForCurrentAgeGroup()
            }
            .store(in: &cancellables)
        
        // Initial setup
        updatePromptsForCurrentAgeGroup()
        updateUXForCurrentAgeGroup()
    }
    
    // MARK: - Public Methods
    
    /// Gets a random prompt appropriate for the user's age group
    func getRandomPrompt() -> JournalPrompt {
        guard !currentPrompts.isEmpty else {
            // Fallback prompt if somehow we have no prompts
            return JournalPrompt(
                id: UUID().uuidString,
                text: "How are you feeling today?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade1to2,
                hasAudio: false,
                hasVisualSupport: false
            )
        }
        
        return currentPrompts.randomElement()!
    }
    
    /// Gets prompts filtered by category
    func getPrompts(for category: PromptCategory) -> [JournalPrompt] {
        return currentPrompts.filter { $0.category == category }
    }
    
    // MARK: - Private Methods
    
    /// Updates the prompts based on the current age group
    /// Updates the available prompts based on the current age group
    func updatePromptsForCurrentAgeGroup() {
        switch userProfile.ageGroup {
        case .child:
            currentPrompts = childPrompts
        case .teen:
            currentPrompts = teenPrompts
        case .adult, .parent:
            currentPrompts = adultPrompts
        }
    }
    
    /// Updates the UX customizations based on the current age group
    /// Updates the UI customizations based on the current age group
    func updateUXForCurrentAgeGroup() {
        switch userProfile.ageGroup {
        case .child:
            uiCustomizations = childUX
        case .teen:
            uiCustomizations = teenUX
        case .adult, .parent:
            uiCustomizations = adultUX
        }
    }
    
    // MARK: - Age-Appropriate Prompts
    
    /// Prompts designed for children (6-12)
    private var childPrompts: [JournalPrompt] {
        [
            // Emotional Awareness
            JournalPrompt(
                id: UUID().uuidString,
                text: "How are you feeling today? Draw a picture or pick an emoji that shows your mood!",
                category: PromptCategory.emotions,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What made you super happy today?",
                category: PromptCategory.emotions,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If your feelings were a color today, what color would they be? Why?",
                category: PromptCategory.emotions,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Growth Mindset -> Learning Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something new you learned today? It can be anything!",
                category: PromptCategory.learning,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something tricky you tried today? How did it go?",
                category: PromptCategory.learning,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could have any superpower to help others, what would it be?",
                category: PromptCategory.learning,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Reflection
            JournalPrompt(
                id: UUID().uuidString,
                text: "What was the best part of your day? Why was it so awesome?",
                category: PromptCategory.reflection,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Who did you play with today? What games did you play?",
                category: PromptCategory.reflection,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could make today even better, what would you add?",
                category: PromptCategory.reflection,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Gratitude -> Goals Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "Name three things that made you smile today!",
                category: PromptCategory.goals,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Who is someone who helped you today? What did they do?",
                category: PromptCategory.goals,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's your favorite toy or game? Why do you love it so much?",
                category: PromptCategory.goals,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Creative
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could go anywhere in the world tomorrow, where would you go?",
                category: PromptCategory.creativity,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Imagine you found a magic treasure chest. What's inside?",
                category: PromptCategory.creativity,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If your pet (or favorite animal) could talk, what would they say to you?",
                category: PromptCategory.creativity,
                ageRanges: [.earlyChildhood, .middleChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            )
        ]
    }
    
    /// Prompts designed for teens (13-17)
    private var teenPrompts: [JournalPrompt] {
        [
            // Emotional Awareness
            JournalPrompt(
                id: UUID().uuidString,
                text: "Rate your mood today. What influenced it the most?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something that's been on your mind lately?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could create a playlist for how you're feeling right now, what would be the first three songs?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Growth Mindset -> Learning Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a skill you want to level up in? What's your next step?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something challenging you're working through right now?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Who's someone you look up to? What qualities do you admire in them?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Reflection
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something you're proud of from today or this week?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "How did you handle a difficult situation recently?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something you wish others understood about you?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Gratitude -> Goals Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something small that brought you joy today?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Who's someone in your life you're grateful for right now?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something you have that you sometimes take for granted?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Creative
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could start a business or creative project, what would it be?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If your life was a movie or show, what genre would it be right now?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could have dinner with any person (living or historical), who would it be and what would you ask them?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: true
            )
        ]
    }
    
    /// Prompts designed for adults (18+)
    private var adultPrompts: [JournalPrompt] {
        [
            // Emotional Awareness
            JournalPrompt(
                id: UUID().uuidString,
                text: "How would you describe your emotional state today? What factors contributed to it?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What emotions have been most present for you lately? How have they manifested?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Describe a moment today when you felt a strong emotion. What triggered it?",
                category: PromptCategory.emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Growth Mindset -> Learning Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's one area of personal growth you're currently focused on?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a challenge you're facing? What resources might help you overcome it?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a belief or perspective you've recently reconsidered?",
                category: PromptCategory.learning,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Reflection
            JournalPrompt(
                id: UUID().uuidString,
                text: "What accomplishment are you proud of today, no matter how small?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "How did your actions today align with your values and priorities?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something you learned about yourself recently?",
                category: PromptCategory.reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Gratitude -> Goals Category
            JournalPrompt(
                id: UUID().uuidString,
                text: "What are three things you're grateful for today?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a relationship in your life that you value deeply? Why?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's an aspect of your daily routine that brings you satisfaction?",
                category: PromptCategory.goals,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Creative
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could design your ideal day, what would it look like?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a creative project or idea you've been considering?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could give advice to your younger self, what would you say?",
                category: PromptCategory.creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: true,
                hasVisualSupport: true
            )
        ]
    }
    
    // MARK: - Age-Appropriate UX Customizations
    
    /// UX customizations for children (6-12)
    private var childUX: UXCustomization {
        UXCustomization(
            primaryFont: Font.largeTitle.bold(),
            secondaryFont: Font.title3.weight(.medium),
            bodyFont: Font.body,
            primaryColor: Color(red: 0.3, green: 0.7, blue: 0.9), // Bright blue
            secondaryColor: Color(red: 1.0, green: 0.6, blue: 0.2), // Orange
            accentColor: Color(red: 0.5, green: 0.8, blue: 0.3), // Bright green
            backgroundColor: Color(red: 0.95, green: 0.97, blue: 1.0), // Light blue-white
            cornerRadius: 20,
            animationsEnabled: true,
            soundEffectsEnabled: true,
            useEmojis: true,
            useStickerRewards: true,
            useAvatars: true,
            useGameElements: true,
            textEntryPrompt: "Write or draw your thoughts here...",
            saveButtonText: "Save My Journal!",
            congratsMessage: "Awesome job! 🎉",
            buttonStyle: .capsule
        )
    }
    
    /// UX customizations for teens (13-17)
    private var teenUX: UXCustomization {
        UXCustomization(
            primaryFont: Font.title.bold(),
            secondaryFont: Font.title3.weight(.semibold),
            bodyFont: Font.body,
            primaryColor: Color(red: 0.2, green: 0.5, blue: 0.8), // Deep blue
            secondaryColor: Color(red: 0.6, green: 0.2, blue: 0.8), // Purple
            accentColor: Color(red: 0.0, green: 0.7, blue: 0.6), // Teal
            backgroundColor: Color(red: 0.97, green: 0.97, blue: 0.97), // Light gray
            cornerRadius: 16,
            animationsEnabled: true,
            soundEffectsEnabled: false,
            useEmojis: true,
            useStickerRewards: false,
            useAvatars: true,
            useGameElements: true,
            textEntryPrompt: "Share your thoughts...",
            saveButtonText: "Save Entry",
            congratsMessage: "Entry saved! 👍",
            buttonStyle: .rounded
        )
    }
    
    /// UX customizations for adults (18+)
    private var adultUX: UXCustomization {
        UXCustomization(
            primaryFont: Font.title.weight(.semibold),
            secondaryFont: Font.headline,
            bodyFont: Font.body,
            primaryColor: Color(red: 0.2, green: 0.4, blue: 0.6), // Navy blue
            secondaryColor: Color(red: 0.6, green: 0.4, blue: 0.2), // Brown
            accentColor: Color(red: 0.8, green: 0.3, blue: 0.3), // Red
            backgroundColor: Color(red: 0.98, green: 0.98, blue: 0.98), // Off-white
            cornerRadius: 12,
            animationsEnabled: false,
            soundEffectsEnabled: false,
            useEmojis: false,
            useStickerRewards: false,
            useAvatars: false,
            useGameElements: false,
            textEntryPrompt: "Enter your response...",
            saveButtonText: "Save",
            congratsMessage: "Entry saved.",
            buttonStyle: .standard
        )
    }
}

// MARK: - Supporting Types

/// Button styles for different age groups
enum ButtonStyle {
    case standard // Rectangular
    case rounded  // Rounded corners
    case capsule  // Pill-shaped
}

/// UX customizations for different age groups
class UXCustomization: ObservableObject {
    // Typography
    let primaryFont: Font
    let secondaryFont: Font
    let bodyFont: Font
    
    // Colors
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let backgroundColor: Color
    
    // Visual Elements
    let cornerRadius: CGFloat
    let animationsEnabled: Bool
    let soundEffectsEnabled: Bool
    let useEmojis: Bool
    let useStickerRewards: Bool
    let useAvatars: Bool
    let useGameElements: Bool
    
    // Text
    let textEntryPrompt: String
    let saveButtonText: String
    let congratsMessage: String
    
    // Button Style
    let buttonStyle: ButtonStyle
    
    // Initializer
    init(primaryFont: Font, secondaryFont: Font, bodyFont: Font, 
         primaryColor: Color, secondaryColor: Color, accentColor: Color, backgroundColor: Color,
         cornerRadius: CGFloat, animationsEnabled: Bool, soundEffectsEnabled: Bool,
         useEmojis: Bool, useStickerRewards: Bool, useAvatars: Bool, useGameElements: Bool,
         textEntryPrompt: String, saveButtonText: String, congratsMessage: String,
         buttonStyle: ButtonStyle) {
        self.primaryFont = primaryFont
        self.secondaryFont = secondaryFont
        self.bodyFont = bodyFont
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.animationsEnabled = animationsEnabled
        self.soundEffectsEnabled = soundEffectsEnabled
        self.useEmojis = useEmojis
        self.useStickerRewards = useStickerRewards
        self.useAvatars = useAvatars
        self.useGameElements = useGameElements
        self.textEntryPrompt = textEntryPrompt
        self.saveButtonText = saveButtonText
        self.congratsMessage = congratsMessage
        self.buttonStyle = buttonStyle
    }
}
