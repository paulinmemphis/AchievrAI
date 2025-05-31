import SwiftUI
import Combine
import AVFoundation

/// A view model for managing the GuidedMultiModalJournalView state
@MainActor
class GuidedMultiModalJournalViewModel: ObservableObject {
    // MARK: - Dependencies
    var analyzer: MetacognitiveAnalyzer?
    var journalManager: MultiModal.JournalManager?
    
    // MARK: - Published Properties
    @Published var entry: MultiModal.JournalEntry
    @Published var entryTitle: String
    @Published var selectedEmotion: MultiModal.Emotion?
    
    // Media state
    @Published var selectedMediaType: MultiModal.MediaType?
    @Published var currentDrawingData: MultiModal.DrawingData?
    @Published var currentPhotoData: Data?
    @Published var currentAudioURL: URL?
    @Published var textContent: String = ""
    
    // UI state
    @Published var showingMediaPicker = false
    @Published var showingEmotionPicker = false
    @Published var currentStep: JournalStep = .introduction
    @Published var isGeneratingInsights = false
    @Published var aiInsights = "Complete your journal entry to generate insights."
    @Published var aiError: Error?
    
    // Age-appropriate prompts
    @Published var currentPrompts: [JournalPrompt] = []
    @Published var promptResponses: [UUID: String] = [:]
    
    // MARK: - Private Properties
    private let childId: String
    let readingLevel: ReadingLevel
    let journalMode: ChildJournalMode
    private let onSave: (MultiModal.JournalEntry) -> Void
    private let onCancel: () -> Void
    
    // MARK: - Initialization
    init(childId: String, readingLevel: ReadingLevel, journalMode: ChildJournalMode, 
         onSave: @escaping (MultiModal.JournalEntry) -> Void, 
         onCancel: @escaping () -> Void) {
        self.childId = childId
        self.readingLevel = readingLevel
        self.journalMode = journalMode
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Create a new entry
        let newEntry = MultiModal.JournalEntry(childId: childId, title: "My Journal Entry")
        self.entry = newEntry
        self.entryTitle = newEntry.title
        self.selectedEmotion = newEntry.mood
        
        // Set age-appropriate prompts
        self.currentPrompts = self.getPromptsForJournalMode(journalMode)
        
        // Initialize prompt responses
        for prompt in self.currentPrompts {
            self.promptResponses[prompt.id] = ""
        }
    }
    
    // MARK: - Journal Steps
    enum JournalStep: Int, CaseIterable {
        case introduction
        case emotion
        case prompts
        case media
        case insights
        case review
        
        var title: String {
            switch self {
            case .introduction: return "Welcome"
            case .emotion: return "How Do You Feel?"
            case .prompts: return "Reflect"
            case .media: return "Express Yourself"
            case .insights: return "Insights"
            case .review: return "Review"
            }
        }
        
        var systemImage: String {
            switch self {
            case .introduction: return "hand.wave"
            case .emotion: return "heart"
            case .prompts: return "text.bubble"
            case .media: return "square.and.pencil"
            case .insights: return "lightbulb"
            case .review: return "checkmark.circle"
            }
        }
    }
    
    // MARK: - Journal Prompts
    struct JournalPrompt: Identifiable {
        let id: UUID
        let text: String
        let hint: String
        let mediaTypeHint: MultiModal.MediaType?
        
        init(text: String, hint: String, mediaTypeHint: MultiModal.MediaType?) {
            self.id = UUID()
            self.text = text
            self.hint = hint
            self.mediaTypeHint = mediaTypeHint
        }
    }
    
    // MARK: - Navigation Methods
    func moveToNextStep() {
        let allSteps = JournalStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            // Move to the next step
            currentStep = allSteps[currentIndex + 1]
            
            // If moving to insights step, generate insights
            if currentStep == .insights {
                // Generate simple insights immediately to avoid blank state
                aiInsights = generateSimpleInsights()
                
                // Then generate more detailed insights asynchronously
                Task {
                    await generateInsights()
                }
            }
        }
    }
    
    func moveToPreviousStep() {
        let allSteps = JournalStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = allSteps[currentIndex - 1]
        }
    }
    
    // MARK: - Save Methods
    func saveEntryAndDismiss() {
        // Save all prompt responses as text media items
        for (promptId, response) in promptResponses where !response.isEmpty {
            if let prompt = currentPrompts.first(where: { $0.id == promptId }) {
                // Create a MediaItem with the correct parameters
                let mediaItem = MultiModal.MediaItem(
                    id: UUID(),
                    type: .text,
                    createdAt: Date(),
                    title: prompt.text,
                    description: nil,
                    fileURL: nil,
                    textContent: response,
                    colorData: nil,
                    drawingData: nil,
                    emotionMusicData: nil,
                    emotionMovementData: nil,
                    visualMetaphorData: nil
                )
                journalManager?.addMediaItem(mediaItem, to: entry.id)
            }
        }
        
        // The onSave closure expects a MultiModal.JournalEntry, not a MetacognitiveJournal.JournalEntry
        // So we pass the current entry directly
        onSave(entry)
    }
    
    // MARK: - Model Conversion
    
    /// Converts the MultiModal.JournalEntry to a standard MetacognitiveJournal.JournalEntry
    /// for compatibility with the existing JournalStore
    func convertToStandardEntry() -> MetacognitiveJournal.JournalEntry {
        // Fallback custom conversion if the adapter fails
        var reflectionPrompts: [PromptResponse] = []
        
        // Convert prompt responses to PromptResponse objects
        for (promptId, response) in promptResponses where !response.isEmpty {
            if let prompt = currentPrompts.first(where: { $0.id == promptId }) {
                let promptResponse = PromptResponse(
                    id: UUID(),
                    prompt: prompt.text,
                    response: response
                )
                reflectionPrompts.append(promptResponse)
            }
        }
        
        // Map emotion to EmotionalState
        let emotionalState: EmotionalState
        if let emotion = selectedEmotion {
            switch emotion.category.lowercased() {
            case "joy", "happiness", "excited":
                emotionalState = .confident
            case "sadness", "disappointed":
                emotionalState = .frustrated
            case "anger", "frustrated":
                emotionalState = .frustrated
            case "fear", "anxious", "nervous":
                emotionalState = .overwhelmed
            case "surprise", "curious":
                emotionalState = .curious
            default:
                emotionalState = .neutral
            }
        } else {
            emotionalState = .neutral
        }
        
        // Create the standard journal entry
        return MetacognitiveJournal.JournalEntry(
            id: UUID(),
            assignmentName: entryTitle,
            date: Date(),
            subject: .other, // Default subject
            emotionalState: emotionalState,
            reflectionPrompts: reflectionPrompts,
            aiSummary: aiInsights
        )
    }
    
    func cancelEntry() {
        onCancel()
    }
    
    // MARK: - Media Methods
    func saveDrawingEntry(_ data: MultiModal.DrawingData) {
        let mediaItem = MultiModal.MediaItem(
            id: UUID(),
            type: .drawing,
            createdAt: Date(),
            title: "Drawing",
            description: nil,
            fileURL: nil,
            textContent: nil,
            colorData: nil,
            drawingData: data,
            emotionMusicData: nil,
            emotionMovementData: nil,
            visualMetaphorData: nil
        )
        
        journalManager?.addMediaItem(mediaItem, to: entry.id)
        currentDrawingData = nil
        selectedMediaType = nil
    }
    
    func savePhotoEntry(_ data: Data) {
        // Note: The actual MultiModal.MediaItem doesn't have an imageData property
        // We need to save the image data to a file and use fileURL instead
        // This is a simplified implementation
        let mediaItem = MultiModal.MediaItem(
            id: UUID(),
            type: .photo,
            createdAt: Date(),
            title: "Photo",
            description: nil,
            fileURL: nil, // In a real implementation, we would save the image to a file and use the URL
            textContent: nil,
            colorData: nil,
            drawingData: nil,
            emotionMusicData: nil,
            emotionMovementData: nil,
            visualMetaphorData: nil
        )
        
        journalManager?.addMediaItem(mediaItem, to: entry.id)
        currentPhotoData = nil
        selectedMediaType = nil
    }
    
    func saveAudioEntry(_ url: URL) {
        let mediaItem = MultiModal.MediaItem(
            id: UUID(),
            type: .audio,
            createdAt: Date(),
            title: "Audio Recording",
            description: nil,
            fileURL: url, // Use fileURL for the audio file
            textContent: nil,
            colorData: nil,
            drawingData: nil,
            emotionMusicData: nil,
            emotionMovementData: nil,
            visualMetaphorData: nil
        )
        
        journalManager?.addMediaItem(mediaItem, to: entry.id)
        currentAudioURL = nil
        selectedMediaType = nil
    }
    
    func saveTextEntry(_ text: String, title: String = "Text Note") {
        let mediaItem = MultiModal.MediaItem(
            id: UUID(),
            type: .text,
            createdAt: Date(),
            title: title,
            description: nil,
            fileURL: nil,
            textContent: text,
            colorData: nil,
            drawingData: nil,
            emotionMusicData: nil,
            emotionMovementData: nil,
            visualMetaphorData: nil
        )
        
        journalManager?.addMediaItem(mediaItem, to: entry.id)
        textContent = ""
        selectedMediaType = nil
    }
    
    // MARK: - AI Insights
    func generateInsights() async {
        await MainActor.run {
            isGeneratingInsights = true
            aiError = nil
        }
        
        do {
            // Combine all prompt responses into a single text
            var journalText = ""
            for (promptId, response) in promptResponses where !response.isEmpty {
                if let prompt = currentPrompts.first(where: { $0.id == promptId }) {
                    journalText += "Question: \(prompt.text)\nAnswer: \(response)\n\n"
                }
            }
            
            // Add emotion if available
            if let emotion = selectedEmotion {
                journalText += "Feeling: \(emotion.name) (Intensity: \(emotion.intensity))\n\n"
            }
            
            // Generate insights based on journal text
            if let analyzer = analyzer, !journalText.isEmpty {
                // Since MetacognitiveAnalyzer doesn't have generateInsights method, use a simple analysis
                // In a real implementation, this would call the appropriate analyzer method
                let sentiment = try await analyzer.analyzeTone(entry: convertToStandardEntry())
                let insightText = "Based on your journal entry, your overall emotional tone appears to be "
                let toneDescription = sentiment > 0.3 ? "positive" : (sentiment < -0.3 ? "somewhat challenging" : "balanced")
                
                await MainActor.run {
                    self.aiInsights = insightText + toneDescription + ".\n\n" + self.generateSimpleInsights()
                    self.isGeneratingInsights = false
                }
            } else {
                // Fallback to simple insights if no analyzer or empty text
                await MainActor.run {
                    self.aiInsights = self.generateSimpleInsights()
                    self.isGeneratingInsights = false
                }
            }
        } catch {
            await MainActor.run {
                self.aiError = error
                self.aiInsights = self.generateSimpleInsights()
                self.isGeneratingInsights = false
            }
        }
    }
    
    func generateSimpleInsights() -> String {
        var insights = "Based on your journal entry:\n\n"
        
        // Count non-empty responses
        let completedPrompts = promptResponses.values.filter { !$0.isEmpty }.count
        let totalPrompts = currentPrompts.count
        
        if completedPrompts == 0 {
            return "Please complete at least one reflection prompt to generate insights."
        }
        
        // Add completion insight
        if completedPrompts == totalPrompts {
            insights += "• Great job completing all the reflection prompts! This shows your dedication to self-reflection.\n\n"
        } else {
            insights += "• You've completed \(completedPrompts) out of \(totalPrompts) prompts. Each reflection helps you grow!\n\n"
        }
        
        // Add emotion-based insight
        if let emotion = selectedEmotion {
            switch emotion.category.lowercased() {
            case "joy", "happiness", "excited":
                insights += "• Your positive emotions show you're engaged and enjoying your learning journey.\n\n"
            case "sadness", "disappointed":
                insights += "• It's okay to feel down sometimes. Recognizing these feelings is an important step in emotional growth.\n\n"
            case "anger", "frustrated":
                insights += "• Frustration often signals that you're pushing against the boundaries of your current understanding. Taking a break might help.\n\n"
            case "fear", "anxious", "nervous":
                insights += "• Feeling nervous about learning is normal. Breaking tasks into smaller steps can help manage these feelings.\n\n"
            case "surprise", "curious":
                insights += "• Your curiosity is a powerful tool for learning. Keep asking questions!\n\n"
            default:
                insights += "• Recognizing your emotions helps you understand yourself better.\n\n"
            }
        }
        
        // Add media-based insights
        let mediaTypes = entry.mediaItems.map { $0.type }
        if mediaTypes.contains(.drawing) {
            insights += "• Your drawings express ideas in ways words sometimes can't. Visual thinking is a valuable skill!\n\n"
        }
        if mediaTypes.contains(.photo) {
            insights += "• Using photos helps you connect your learning to the real world around you.\n\n"
        }
        if mediaTypes.contains(.audio) {
            insights += "• Speaking your thoughts helps develop verbal expression and can reveal new perspectives.\n\n"
        }
        
        // Add age-appropriate insight based on journal mode
        switch journalMode {
        case .earlyChildhood:
            insights += "• You're learning to share your thoughts and feelings, which is an important skill!\n\n"
        case .middleChildhood:
            insights += "• Your reflections show you're developing critical thinking skills and understanding your own learning process.\n\n"
        case .adolescent:
            insights += "• Your ability to analyze your experiences demonstrates growing metacognitive skills that will help you throughout life.\n\n"
        }
        
        return insights
    }
    
    // MARK: - Age-Appropriate Content
    func getPromptsForJournalMode(_ mode: ChildJournalMode) -> [JournalPrompt] {
        switch mode {
        case .earlyChildhood:
            return [
                JournalPrompt(text: "What made you smile today?", hint: "Think about happy moments", mediaTypeHint: .drawing),
                JournalPrompt(text: "What was hard today?", hint: "It's okay if some things are difficult", mediaTypeHint: .drawing),
                JournalPrompt(text: "What do you want to learn tomorrow?", hint: "Think about what makes you curious", mediaTypeHint: nil),
                JournalPrompt(text: "Draw how you feel right now", hint: "Colors can show feelings too!", mediaTypeHint: .drawing)
            ]
            
        case .middleChildhood:
            return [
                JournalPrompt(text: "What's something new you learned today?", hint: "Think about something that surprised you", mediaTypeHint: nil),
                JournalPrompt(text: "What was challenging and how did you handle it?", hint: "Challenges help us grow", mediaTypeHint: nil),
                JournalPrompt(text: "How could you use what you learned in real life?", hint: "Think about connections to your daily activities", mediaTypeHint: .photo),
                JournalPrompt(text: "If you could teach someone one thing from today, what would it be?", hint: "Teaching others helps us learn better", mediaTypeHint: .audio)
            ]
            
        case .adolescent:
            return [
                JournalPrompt(text: "What concepts did you understand well, and which ones need more work?", hint: "Being honest about your understanding helps you improve", mediaTypeHint: nil),
                JournalPrompt(text: "How did your emotions affect your learning today?", hint: "Our feelings can influence how we learn", mediaTypeHint: nil),
                JournalPrompt(text: "What strategies worked well for you, and which ones didn't?", hint: "Reflecting on your approach helps you develop better methods", mediaTypeHint: nil),
                JournalPrompt(text: "How does what you learned connect to your personal goals or interests?", hint: "Finding personal meaning enhances motivation", mediaTypeHint: .photo),
                JournalPrompt(text: "What questions do you still have about this topic?", hint: "Curiosity drives deeper learning", mediaTypeHint: .audio)
            ]
        }
    }
    
    func getIntroductionText() -> String {
        switch journalMode {
        case .earlyChildhood:
            return "Hi there! Let's write in your journal today! We'll think about your day, draw pictures, and have fun sharing your thoughts."
            
        case .middleChildhood:
            return "Welcome to your journal! Today we'll reflect on what you've learned, how you felt, and capture your thoughts with words, pictures, or recordings."
            
        case .adolescent:
            return "Welcome to your reflective journal. This space is designed to help you process your learning experiences, analyze your thinking patterns, and document your growth."
        }
    }
    
    func getEmotionPrompt() -> String {
        switch journalMode {
        case .earlyChildhood:
            return "How are you feeling right now? Tap on the face that matches your feelings."
            
        case .middleChildhood:
            return "What emotions are you experiencing today? Select the one that best describes how you feel."
            
        case .adolescent:
            return "Identify your current emotional state. Being aware of our emotions helps us understand how they influence our thinking and learning."
        }
    }
    
    func getMediaPrompt() -> String {
        switch journalMode {
        case .earlyChildhood:
            return "Now let's add pictures or sounds! You can draw, take a photo, or record your voice."
            
        case .middleChildhood:
            return "Express yourself! You can add drawings, photos, or voice recordings to your journal entry."
            
        case .adolescent:
            return "Enhance your reflection with multimedia. Visual and audio elements can capture aspects of your experience that words alone might miss."
        }
    }
    
    func getReviewPrompt() -> String {
        switch journalMode {
        case .earlyChildhood:
            return "Great job! Let's look at everything you added to your journal today."
            
        case .middleChildhood:
            return "You've completed your journal entry! Review what you've written and added before saving."
            
        case .adolescent:
            return "Take a moment to review your complete reflection. Consider how the different elements work together to capture your learning experience."
        }
    }
    
    // MARK: - Reading Level Adaptations
    func adaptTextForReadingLevel(_ text: String) -> String {
        switch readingLevel {
        case .preReader, .earlyReader:
            // Simplify text for very early readers
            return simplifyText(text, maxWordsPerSentence: 5, useSimpleWords: true)
            
        case .grade1to2:
            // Slightly more complex but still simple
            return simplifyText(text, maxWordsPerSentence: 7, useSimpleWords: true)
            
        case .grade3to4:
            // Moderate complexity
            return simplifyText(text, maxWordsPerSentence: 10, useSimpleWords: false)
            
        case .grade5to6:
            // More advanced
            return simplifyText(text, maxWordsPerSentence: 15, useSimpleWords: false)
            
        case .grade7to8, .grade9Plus:
            // No simplification needed
            return text
        }
    }
    
    private func simplifyText(_ text: String, maxWordsPerSentence: Int, useSimpleWords: Bool) -> String {
        // This is a simplified implementation
        // In a production app, you would use more sophisticated NLP techniques
        
        // Split into sentences
        let sentences = text.components(separatedBy: [".","!","?"])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var simplifiedSentences = [String]()
        
        for sentence in sentences {
            let words = sentence.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            if words.count <= maxWordsPerSentence {
                // Sentence is already short enough
                simplifiedSentences.append(sentence + ".")
            } else {
                // Break into smaller chunks
                var currentChunk = [String]()
                
                for word in words {
                    currentChunk.append(word)
                    
                    if currentChunk.count >= maxWordsPerSentence {
                        simplifiedSentences.append(currentChunk.joined(separator: " ") + ".")
                        currentChunk = []
                    }
                }
                
                // Add any remaining words
                if !currentChunk.isEmpty {
                    simplifiedSentences.append(currentChunk.joined(separator: " ") + ".")
                }
            }
        }
        
        return simplifiedSentences.joined(separator: " ")
    }
    
    // MARK: - UI Helper Methods
    func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood:
            // Larger, more playful font for young children
            return .system(size: size + 2, weight: weight, design: .rounded)
            
        case .middleChildhood:
            // Still rounded but more standard size
            return .system(size: size, weight: weight, design: .rounded)
            
        case .adolescent:
            // More mature font for older users
            return .system(size: size, weight: weight, design: .default)
        }
    }
}
