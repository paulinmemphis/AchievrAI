import SwiftUI
import Combine

/// A view model for managing AIJournalEntryView state
@MainActor
class AIJournalEntryViewModel: ObservableObject {
    // MARK: - Dependencies
    var analyzer: MetacognitiveAnalyzer?
    // MARK: - Published Properties
    @Published var assignmentName = ""
    @Published var selectedSubject: K12Subject = .other
    @Published var emotionalState: EmotionalState = .neutral
    @Published var reflectionPrompts: [PromptResponse] = []
    @Published var showingPromptSheet = false
    @Published var showingSubjectPicker = false
    @Published var showingEmotionalPicker = false
    @Published var showingGenrePicker = false
    @Published var selectedGenre = "fantasy"
    @Published var isGeneratingChapter = false
    @Published var generationProgress: Double = 0
    @Published var chapterGenerationError: Error? = nil
    @Published var showingStoryMap = false
    @Published var showingSaveConfirmation = false
    @Published var isLoadingAI = false
    @Published var aiTone = "Neutral"
    @Published var aiInsights = "Complete the reflection prompts to generate insights."
    @Published var aiError: Error? = nil
    @Published var showingDeleteAlert = false
    @Published var promptToDelete: PromptResponse? = nil
    @Published var showingAddPromptSheet = false
    @Published var customPromptText = ""
    
    // MARK: - Private Properties
    private let narrativeAPIService = NarrativeAPIService()
    private let journalStore = JournalStore()
    private lazy var insightAnalyzer = InsightAnalyzer(journalStore: journalStore)
    var cancellables = Set<AnyCancellable>()
    
    // Genre options for story generation
    let genreOptions = ["fantasy", "mystery", "adventure", "scifi", "general"]
    
    // MARK: - Initialization
    init(initialText: String? = nil) {
        // Initialize with default prompts if none exist
        if reflectionPrompts.isEmpty {
            reflectionPrompts = [
                PromptResponse(id: UUID(), prompt: "What did you learn today?", response: initialText),
                PromptResponse(id: UUID(), prompt: "What was challenging?", response: nil),
                PromptResponse(id: UUID(), prompt: "How will you apply this knowledge?", response: nil)
            ]
        } else if let initialText = initialText, !initialText.isEmpty {
            // If there's initial text and prompts already exist, set it to the first prompt
            reflectionPrompts[0].response = initialText
        }
    }
    
    /// Begins the chapter generation process with the selected genre
    func beginChapterGeneration(genre: String, journalStore: JournalStore) {
        isGeneratingChapter = true
        generationProgress = 0.1
        chapterGenerationError = nil
        selectedGenre = genre
        
        // Create metadata from reflection prompts
        let journalText = reflectionPrompts.compactMap { $0.response }.joined(separator: "\n\n")
        
        // Get previous arcs for continuity
        let previousArcs = journalStore.entries
            .prefix(3)
            .compactMap { entry -> PreviousArc? in
                guard let metadata = entry.metadata else { return nil }
                return PreviousArc(
                    summary: entry.aiSummary ?? "Journal entry",
                    themes: metadata.themes,
                    chapterId: entry.id.uuidString
                )
            }
        
        // First, get metadata from the API
        generationProgress = 0.2
        
        narrativeAPIService.getMetadata(text: journalText)
            .catch { error -> AnyPublisher<MetadataResponse, APIServiceError> in
                print("Metadata generation failed: \(error.localizedDescription), using fallback")
                return Just(self.createFallbackMetadata(from: journalText))
                    .setFailureType(to: APIServiceError.self)
                    .eraseToAnyPublisher()
            }
            // Use receive(on:) to ensure we're on the main thread before updating UI properties
            .receive(on: DispatchQueue.main)
            .map { [weak self] metadataResponse -> AnyPublisher<ChapterResponse, APIServiceError> in
                // Now we're on the main thread
                self?.generationProgress = 0.5
                
                // Convert MetadataResponse to EntryMetadata
                let entryMetadata = EntryMetadata(
                    sentiment: metadataResponse.sentiment,
                    themes: metadataResponse.themes,
                    entities: metadataResponse.entities,
                    keyPhrases: metadataResponse.keyPhrases
                )
                
                // Create the chapter request
                let chapterRequest = ChapterGenerationRequest(
                    metadata: entryMetadata,
                    userId: UUID().uuidString, // Use a placeholder user ID
                    genre: genre,
                    previousArcs: previousArcs
                )
                
                let publisher = self!.narrativeAPIService.generateChapter(requestData: chapterRequest)
                    .timeout(60, scheduler: DispatchQueue.main) // Add timeout to prevent indefinite waiting
                    .catch { error -> AnyPublisher<ChapterResponse, APIServiceError> in
                        // If chapter generation fails, create a fallback chapter
                        print("Chapter generation failed: \(error.localizedDescription), using fallback")
                        return Just(self!.createFallbackChapter(from: metadataResponse, genre: genre))
                            .setFailureType(to: APIServiceError.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
                
                return publisher
            }
            .switchToLatest()
            .receive(on: RunLoop.main) // Ensure updates happen on main thread
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.generationProgress = 1.0
                    self.isGeneratingChapter = false
                case .failure(let error):
                    self.generationProgress = 0
                    self.isGeneratingChapter = false
                    self.chapterGenerationError = error
                }
            }, receiveValue: { chapterResponse in
                self.saveGeneratedChapter(chapterResponse, journalStore: journalStore)
            })
            .store(in: &self.cancellables)
    }
    
    /// Creates a fallback metadata response when the API call fails
    func createFallbackMetadata(from text: String) -> MetadataResponse {
        // Extract some basic themes and entities from the text
        var themes: [String] = []
        var entities: [String] = []
        var keyPhrases: [String] = []
        
        // Simple theme extraction based on subject
        switch selectedSubject {
        case .math:
            themes = ["Mathematics", "Problem Solving", "Logic"]
        case .science:
            themes = ["Science", "Discovery", "Exploration"]
        case .english:
            themes = ["Literature", "Expression", "Creativity"]
        case .history:
            themes = ["History", "Time", "Culture"]
        case .art:
            themes = ["Art", "Creativity", "Expression"]
        case .music:
            themes = ["Music", "Harmony", "Rhythm"]
        case .socialStudies:
            themes = ["Society", "Culture", "Civics"]
        case .computerScience:
            themes = ["Technology", "Programming", "Logic"]
        case .physicalEducation:
            themes = ["Fitness", "Health", "Teamwork"]
        case .foreignLanguage:
            themes = ["Language", "Communication", "Culture"]
        case .biology:
            themes = ["Life", "Organisms", "Ecosystems"]
        case .chemistry:
            themes = ["Elements", "Reactions", "Compounds"]
        case .physics:
            themes = ["Forces", "Energy", "Motion"]
        case .geography:
            themes = ["Places", "Maps", "Environments"]
        case .economics:
            themes = ["Money", "Markets", "Resources"]
        case .writing:
            themes = ["Composition", "Expression", "Communication"]
        case .reading:
            themes = ["Books", "Comprehension", "Stories"]
        case .other:
            themes = ["Learning", "Growth", "Knowledge"]
        @unknown default:
            themes = ["Education", "Development", "Skills"]
        }
        
        // Extract potential entities from assignment name
        if !assignmentName.isEmpty {
            entities = [assignmentName]
            keyPhrases = [assignmentName]
        }
        
        // Determine sentiment from emotional state
        let sentiment = fallbackSentimentForEmotionalState(emotionalState)
        
        return MetadataResponse(
            sentiment: String(sentiment),
            themes: themes,
            entities: entities,
            keyPhrases: keyPhrases
        )
    }
    
    /// Creates a fallback chapter when the API call fails
    func createFallbackChapter(from metadata: MetadataResponse, genre: String) -> ChapterResponse {
        let chapterId = UUID().uuidString
        let title = "The Adventure of \(assignmentName)"
        
        // Generate different chapter text based on genre
        var chapterText = ""
        var cliffhanger = ""
        
        switch genre {
        case "fantasy":
            chapterText = createFantasyChapter(title: title, metadata: metadata)
            cliffhanger = "What magical challenges await in the next chapter of this fantastical journey?"
        case "mystery":
            chapterText = createMysteryChapter(title: title, metadata: metadata)
            cliffhanger = "What secrets will be uncovered as the investigation continues?"
        case "adventure":
            chapterText = createAdventureChapter(title: title, metadata: metadata)
            cliffhanger = "What exciting discoveries await on the next leg of this incredible journey?"
        case "scifi":
            chapterText = createSciFiChapter(title: title, metadata: metadata)
            cliffhanger = "What technological wonders and cosmic mysteries will be revealed in the next chapter?"
        default:
            chapterText = createGeneralChapter(title: title, metadata: metadata)
            cliffhanger = "What new insights and growth will the next chapter bring?"
        }
        
        return ChapterResponse(
            chapterId: chapterId,
            text: chapterText,
            cliffhanger: cliffhanger,
            studentName: nil,
            feedback: nil
        )
    }
    
    /// Creates a fantasy-themed chapter
    func createFantasyChapter(title: String, metadata: MetadataResponse) -> String {
        let themes = metadata.themes.joined(separator: ", ")
        return """
        # \(title)
        
        In a realm of magic and wonder, a young student named Alex embarked on a quest to master the arts of \(themes). 
        The journey was filled with challenges, but Alex's determination never wavered.
        
        As the sun set over the enchanted forest, Alex reflected on the day's lessons. The ancient tomes had revealed 
        secrets that few had discovered before. With each new spell mastered, Alex's confidence grew stronger.
        
        The wise mentor nodded approvingly. "You have learned much today, but remember that true wisdom comes 
        from applying knowledge, not merely possessing it."
        
        Alex nodded, knowing that tomorrow would bring new challenges and opportunities for growth in this 
        magical journey of learning.
        """
    }
    
    /// Creates a mystery-themed chapter
    func createMysteryChapter(title: String, metadata: MetadataResponse) -> String {
        let themes = metadata.themes.joined(separator: ", ")
        return """
        # \(title)
        
        The classroom was quiet when Detective Alex noticed something unusual about today's lesson on \(themes). 
        There was a pattern emerging, a puzzle hidden within the seemingly ordinary assignments.
        
        "What if," Alex thought, carefully noting down observations in a journal, "these concepts are connected 
        in ways we haven't considered before?"
        
        The teacher smiled mysteriously, as if aware of Alex's internal investigation. "Sometimes," the teacher 
        said, "the most important discoveries come from questioning what everyone else takes for granted."
        
        As the bell rang, Alex gathered the notes, determined to continue piecing together this academic mystery. 
        The truth was out there, hidden in plain sight among formulas and theories.
        """
    }
    
    /// Creates an adventure-themed chapter
    func createAdventureChapter(title: String, metadata: MetadataResponse) -> String {
        let themes = metadata.themes.joined(separator: ", ")
        return """
        # \(title)
        
        Alex stood at the edge of the classroom, facing the greatest academic challenge yet: mastering \(themes). 
        Like an explorer preparing to chart unknown territories, Alex packed a backpack with textbooks, notes, and determination.
        
        "This won't be easy," warned the teacher, "but the most rewarding journeys rarely are."
        
        Throughout the day, Alex navigated through difficult concepts, scaled mountains of information, and 
        occasionally stumbled into valleys of confusion. But with each obstacle overcome, the path forward became clearer.
        
        By the end of the day, though tired, Alex felt the exhilaration that only comes from pushing beyond perceived limits. 
        This adventure in learning was just beginning, and tomorrow promised new horizons to discover.
        """
    }
    
    /// Creates a sci-fi themed chapter
    func createSciFiChapter(title: String, metadata: MetadataResponse) -> String {
        let themes = metadata.themes.joined(separator: ", ")
        return """
        # \(title)
        
        In the learning lab of Education Station Alpha, Student AX-7 (known to friends as Alex) initialized the day's 
        neural upload sequence. Today's data packet contained advanced concepts in \(themes).
        
        "Neural pathways optimizing," announced the AI tutor. "Prepare for knowledge integration."
        
        As information flowed through Alex's mind, connections formed between new concepts and previously stored data. 
        Occasionally, the system would pause to allow for manual processing—what ancient educators had called "reflection."
        
        "Fascinating," Alex thought, manually documenting observations in an old-fashioned digital journal. "These concepts 
        could revolutionize our understanding of the subject."
        
        As the learning cycle completed, Alex prepared for tomorrow's sequence, knowing that each day brought humanity 
        one step closer to unlocking the universe's greatest mysteries.
        """
    }
    
    /// Creates a general themed chapter
    func createGeneralChapter(title: String, metadata: MetadataResponse) -> String {
        let themes = metadata.themes.joined(separator: ", ")
        return """
        # \(title)
        
        Alex began the day with a sense of purpose, ready to engage with new ideas about \(themes). 
        The classroom buzzed with energy as students settled in for another day of learning.
        
        "Today," announced the teacher, "we'll be exploring concepts that might challenge your existing understanding."
        
        As the lesson progressed, Alex took careful notes, occasionally pausing to consider how these new ideas 
        connected to previous knowledge. Questions arose, some answered through discussion, others noted down for 
        further exploration.
        
        By the end of the day, Alex reviewed the notes with satisfaction. Learning wasn't always easy, but the 
        journey of discovery made every challenge worthwhile. Tomorrow would bring new questions, new insights, 
        and new opportunities for growth.
        """
    }
    
    /// Saves a generated chapter to the story persistence manager
    func saveGeneratedChapter(_ chapterResponse: ChapterResponse, journalStore: JournalStore) {
        // Implementation details...
        print("Saving chapter: \(chapterResponse.chapterId)")
    }
    
    /// Generates AI insights for the journal entry
    // List of common words to filter out when extracting key concepts
    @MainActor private let commonWords = ["about", "above", "after", "again", "against", "also", "because", "been", "before", "being", "below", "between", "both", "cannot", "could", "during", "each", "from", "further", "have", "having", "here", "itself", "more", "most", "other", "over", "same", "should", "some", "such", "than", "that", "their", "them", "then", "there", "these", "they", "this", "those", "through", "under", "until", "very", "what", "when", "where", "which", "while", "with", "would", "your"]
    
    func generateAIInsights(analyzer: MetacognitiveAnalyzer?) async {
        await MainActor.run {
            isLoadingAI = true
            aiError = nil
        }
        
        // Create a minimal journal entry for tone analysis
        let entryText = reflectionPrompts.compactMap { $0.response }.joined(separator: "\n\n")
        
        if entryText.isEmpty {
            await MainActor.run {
                aiInsights = "Please complete at least one reflection prompt to generate insights."
                isLoadingAI = false
            }
            return
        }
        
        // Create a temporary journal entry for analysis
        let tempEntry = JournalEntry(
            id: UUID(),
            assignmentName: assignmentName,
            date: Date(),
            subject: selectedSubject,
            emotionalState: emotionalState,
            reflectionPrompts: reflectionPrompts,
            aiSummary: nil,
            aiTone: nil,
            metadata: nil
        )
        
        // First, try to get the tone from the analyzer service
        if let analyzer = analyzer {
            do {
                // Use the analyzer to get the tone
                let sentiment = try await analyzer.analyzeTone(entry: tempEntry)
                let toneString = convertSentimentToTone(sentiment)
                
                // Generate current insights based on the entry content
                let currentInsights = generateSimpleInsights(from: reflectionPrompts)
                
                // Generate cumulative insights that build on previous entries
                let cumulativeInsights = await generateCumulativeInsights(for: tempEntry)
                
                // Combine current and cumulative insights
                let combinedInsights = combineInsights(current: currentInsights, cumulative: cumulativeInsights)
                
                // Since we're already in a @MainActor class, we can update directly
                aiTone = toneString
                aiInsights = combinedInsights
            } catch {
                print("Error analyzing sentiment: \(error.localizedDescription)")
                // Fall back to emotional state for tone
                let fallbackSentiment = fallbackSentimentForEmotionalState(emotionalState)
                let toneString = convertSentimentToTone(fallbackSentiment)
                let fallbackInsights = generateFallbackInsights()
                
                // Update UI on main thread
                await MainActor.run {
                    aiTone = toneString
                    aiInsights = fallbackInsights
                }
            }
        } else {
            // No analyzer available, use fallbacks
            let fallbackSentiment = fallbackSentimentForEmotionalState(emotionalState)
            let toneString = convertSentimentToTone(fallbackSentiment)
            let fallbackInsights = generateFallbackInsights()
            
            // Update UI on main thread
            await MainActor.run {
                aiTone = toneString
                aiInsights = fallbackInsights
            }
        }
        
        // Update loading state on main thread
        await MainActor.run {
            isLoadingAI = false
        }
    }
    
    /// Determines a fallback sentiment value based on emotional state
    func fallbackSentimentForEmotionalState(_ state: EmotionalState) -> Double {
        switch state {
        case .confident, .satisfied:
            return 0.7 // Positive
        case .curious:
            return 0.6 // Slightly positive
        case .neutral:
            return 0.5 // Neutral
        case .confused, .frustrated:
            return 0.3 // Slightly negative
        case .overwhelmed:
            return 0.1 // Very negative
        @unknown default:
            return 0.5 // Default to neutral
        }
    }
    
    /// Converts a sentiment score to a descriptive tone string
    func convertSentimentToTone(_ score: Double) -> String {
        switch score {
        case 0.7...1.0: return "Very Positive"
        case 0.3..<0.7: return "Positive"
        case 0.2..<0.3: return "Neutral"
        case 0.1..<0.2: return "Negative"
        case 0.0..<0.1: return "Very Negative"
        default: return "Neutral"
        }
    }
    
    /// Generates fallback insights when API-based insights are unavailable
    func generateFallbackInsights() -> String {
        var insights = "Based on your journal entry:\n\n"
        var insightPool = [String]() // Store potential insights
        
        // Subject-specific insights
        switch selectedSubject {
        case .math:
            insightPool.append("• You're engaging with mathematical concepts in a thoughtful way.")
            insightPool.append("• Consider how these mathematical principles apply to real-world situations.")
            insightPool.append("• Try creating visual representations of these concepts to enhance understanding.")
        case .science:
            insightPool.append("• Your scientific inquiry shows curiosity about how the world works.")
            insightPool.append("• Consider designing an experiment to test one of the concepts you've learned.")
            insightPool.append("• Connecting these scientific principles to everyday phenomena could deepen your understanding.")
        case .english:
            insightPool.append("• Your writing shows thoughtful engagement with language and ideas.")
            insightPool.append("• Consider how different perspectives might interpret the same text differently.")
            insightPool.append("• Exploring the historical context of this material might provide additional insights.")
        case .history:
            insightPool.append("• You're making connections between historical events and their significance.")
            insightPool.append("• Consider how different historical perspectives might view these same events.")
            insightPool.append("• Exploring primary sources could provide deeper context for this historical period.")
        case .art:
            insightPool.append("• Your creative expression shows thoughtful engagement with artistic concepts.")
            insightPool.append("• Consider how different artistic techniques might convey different emotions or ideas.")
            insightPool.append("• Exploring the historical or cultural context of this art form could provide additional insights.")
        case .music:
            insightPool.append("• Your musical exploration shows engagement with both technical and expressive elements.")
            insightPool.append("• Consider how different musical traditions approach similar concepts differently.")
            insightPool.append("• Connecting theory to practice through regular playing/singing will reinforce your learning.")
        case .computerScience:
            insightPool.append("• Your computational thinking shows a systematic approach to problem-solving.")
            insightPool.append("• Consider how these programming concepts could be applied to solve real-world problems.")
            insightPool.append("• Building small projects that use these concepts will reinforce your understanding.")
        case .physicalEducation:
            insightPool.append("• Your approach to physical activity shows awareness of both technique and personal growth.")
            insightPool.append("• Consider how consistent practice of these skills contributes to overall well-being.")
            insightPool.append("• Setting specific, measurable goals could help track your progress in this area.")
        case .foreignLanguage:
            insightPool.append("• Your language learning shows engagement with both vocabulary and cultural context.")
            insightPool.append("• Regular practice through conversation will help solidify these language concepts.")
            insightPool.append("• Exploring media in this language could provide authentic context for your learning.")
        case .biology:
            insightPool.append("• Your exploration of biological concepts shows curiosity about living systems.")
            insightPool.append("• Consider how these biological principles connect to environmental and health topics.")
            insightPool.append("• Observing these concepts in nature could provide deeper understanding.")
        case .chemistry:
            insightPool.append("• Your engagement with chemical concepts shows attention to molecular interactions.")
            insightPool.append("• Consider how these chemical principles appear in everyday substances and reactions.")
            insightPool.append("• Connecting theoretical concepts to laboratory observations will deepen your understanding.")
        case .physics:
            insightPool.append("• Your exploration of physics concepts shows attention to fundamental forces and energy.")
            insightPool.append("• Consider how these physical principles explain everyday phenomena.")
            insightPool.append("• Designing simple experiments could help visualize these abstract concepts.")
        case .geography:
            insightPool.append("• Your geographic exploration shows awareness of spatial relationships and environments.")
            insightPool.append("• Consider how geographic features influence human activities and settlements.")
            insightPool.append("• Connecting map studies to real locations enhances spatial understanding.")
        case .economics:
            insightPool.append("• Your economic analysis shows attention to resource allocation and decision-making.")
            insightPool.append("• Consider how economic principles influence both personal and societal choices.")
            insightPool.append("• Applying these concepts to current events can provide practical context.")
        case .writing:
            insightPool.append("• Your writing shows thoughtful development of ideas and expression.")
            insightPool.append("• Consider how different writing techniques can enhance clarity and impact.")
            insightPool.append("• Regular practice with different writing styles will strengthen your skills.")
        case .reading:
            insightPool.append("• Your reading engagement shows attention to both content and context.")
            insightPool.append("• Consider how different perspectives might interpret the same text.")
            insightPool.append("• Connecting texts to their historical or cultural background enhances understanding.")
        case .socialStudies:
            insightPool.append("• Your exploration of social studies shows awareness of human societies and interactions.")
            insightPool.append("• Consider how cultural and historical factors shape social structures.")
            insightPool.append("• Examining multiple perspectives on social issues deepens critical thinking.")
        case .other:
            insightPool.append("• Your reflections show thoughtful engagement with the subject matter.")
            insightPool.append("• Consider how these concepts connect to other areas of knowledge you're familiar with.")
            insightPool.append("• Applying these ideas in practical situations could deepen your understanding.")
        @unknown default:
            insightPool.append("• Your learning journey shows dedication to understanding new concepts.")
            insightPool.append("• Reflecting on your learning process helps reinforce new knowledge.")
            insightPool.append("• Consider how these ideas might connect to your existing knowledge base.")
        }
        
        // Emotional state insights
        switch emotionalState {
        case .confident:
            insightPool.append("• Your confidence suggests you've mastered key concepts in this assignment.")
            insightPool.append("• Consider challenging yourself with more advanced material to maintain engagement.")
            insightPool.append("• Sharing your understanding with peers could reinforce your learning.")
        case .satisfied:
            insightPool.append("• Your satisfaction indicates a positive learning experience with this material.")
            insightPool.append("• Reflect on what aspects of this assignment were most fulfilling for you.")
            insightPool.append("• Consider how to bring similar satisfaction to future learning experiences.")
        case .curious:
            insightPool.append("• Your curiosity indicates an active engagement with the learning material.")
            insightPool.append("• Consider exploring related topics that might deepen your understanding.")
            insightPool.append("• Asking questions and seeking connections can lead to more meaningful learning.")
        case .neutral:
            insightPool.append("• Your neutral approach allows for objective analysis of the material.")
            insightPool.append("• Consider what aspects of this topic might inspire more engagement or curiosity.")
            insightPool.append("• Finding personal connections to the material could increase your investment in learning.")
        case .confused:
            insightPool.append("• Confusion is a natural part of the learning process when encountering new concepts.")
            insightPool.append("• Breaking down complex ideas into smaller components might help clarify understanding.")
            insightPool.append("• Consider different approaches or resources that might present the material in a more accessible way.")
        case .frustrated:
            insightPool.append("• Frustration often signals that you're pushing against the boundaries of your current understanding.")
            insightPool.append("• Taking a step back to review foundational concepts might help overcome current obstacles.")
            insightPool.append("• Consider discussing specific challenges with your teacher for targeted guidance.")
        case .overwhelmed:
            insightPool.append("• Feeling overwhelmed suggests you might benefit from breaking this material into smaller sections.")
            insightPool.append("• Prioritizing key concepts first can help build a foundation for more complex ideas later.")
            insightPool.append("• Consider reaching out for additional support or resources to navigate this challenging material.")
        @unknown default:
            insightPool.append("• Reflecting on your emotional response to learning can provide valuable insights.")
            insightPool.append("• Consider how your emotional state might influence your approach to this material.")
            insightPool.append("• Being aware of your learning preferences can help you adapt strategies for better understanding.")
        }
        
        // Add general insights
        insightPool.append("• Regular review of this material will help transfer it to long-term memory.")
        insightPool.append("• Connecting these concepts to your personal interests could increase engagement.")
        insightPool.append("• Teaching these concepts to someone else would reinforce your own understanding.")
        insightPool.append("• Creating visual summaries or mind maps might help organize these ideas.")
        insightPool.append("• Setting specific learning goals related to this material could focus your efforts.")
        
        // Shuffle and select a random subset of insights to avoid repetition
        insightPool.shuffle()
        let selectedInsights = Array(insightPool.prefix(3))
        
        insights += selectedInsights.joined(separator: "\n\n")
        
        return insights
    }
    
    /// Generates simple insights from prompt responses
    func generateSimpleInsights(from responses: [PromptResponse]) -> String {
        // Extract non-empty responses
        let validResponses = responses.filter { !($0.response?.isEmpty ?? true) }
        
        if validResponses.isEmpty {
            return "Please complete at least one reflection prompt to generate insights."
        }
        
        var insights = "Based on your reflections:\n\n"
        var insightCount = 0
        let maxInsights = 3
        
        // Process what was learned
        if let learnedResponse = validResponses.first(where: { $0.prompt.contains("learn") }),
           let responseText = learnedResponse.response, !responseText.isEmpty {
            
            let sentences = responseText.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if !sentences.isEmpty {
                // Extract key concepts - find nouns and important terms
                let words = responseText.components(separatedBy: .whitespacesAndNewlines)
                    .filter { $0.count > 4 } // Only consider longer words as potential key concepts
                    .map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
                    .filter { !commonWords.contains($0) } // Filter out common words
                
                if !words.isEmpty {
                    // Use the first significant word instead of a random one for consistency
                    let keyTopic = words.first ?? "this topic"
                    insights += "• You've gained knowledge about \(keyTopic), which you can build upon in future assignments.\n\n"
                    insightCount += 1
                } else {
                    // Fallback if no significant words found
                    insights += "• You've gained new knowledge that you can build upon in future assignments.\n\n"
                    insightCount += 1
                }
            }
        }
        
        // Process challenges
        if let challengeResponse = validResponses.first(where: { $0.prompt.contains("challenging") || $0.prompt.contains("difficult") }),
           let responseText = challengeResponse.response, !responseText.isEmpty {
            
            // Extract a meaningful snippet from the response
            let cleanedText = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = cleanedText.count > 30 ? String(cleanedText.prefix(30)) + "..." : cleanedText
            
            insights += "• Recognizing that \(snippet) was challenging shows good metacognitive awareness. Consider strategies to overcome similar challenges in the future.\n\n"
            insightCount += 1
        }
        
        // Process application
        if let applyResponse = validResponses.first(where: { $0.prompt.contains("apply") || $0.prompt.contains("use") }),
           let responseText = applyResponse.response, !responseText.isEmpty {
            
            // Extract a meaningful snippet from the response
            let cleanedText = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = cleanedText.count > 30 ? String(cleanedText.prefix(30)) + "..." : cleanedText
            
            insights += "• Your plan to apply this knowledge by \(snippet) demonstrates forward thinking. This connection between theory and practice will deepen your understanding.\n\n"
            insightCount += 1
        }
        
        // Add subject-specific insights if we need more
        if insightCount < maxInsights {
            switch selectedSubject {
            case .math:
                insights += "• Mathematical concepts often build upon each other. Make sure you have a solid understanding of these fundamentals before moving on.\n\n"
                insightCount += 1
            case .science:
                insights += "• Scientific inquiry involves both understanding concepts and applying the scientific method. Consider how you might test some of these ideas.\n\n"
                insightCount += 1
            case .english:
                insights += "• Literary analysis skills transfer across different texts. The critical thinking you're developing will serve you in many contexts.\n\n"
                insightCount += 1
            case .history:
                insights += "• Historical understanding involves recognizing patterns and connections between events. Consider how this period connects to others you've studied.\n\n"
                insightCount += 1
            default:
                insights += "• Deep learning happens when you connect new knowledge to existing understanding. Try to find links between this material and other subjects.\n\n"
                insightCount += 1
            }
        }
        
        // Add emotional state insights if we still need more
        if insightCount < maxInsights {
            switch emotionalState {
            case .confident:
                insights += "• Your confidence suggests you've mastered key concepts in this assignment.\n"
                insightCount += 1
            case .satisfied:
                insights += "• Your satisfaction indicates a positive learning experience with this material.\n"
                insightCount += 1
            case .curious:
                insights += "• Your curiosity indicates an active engagement with the learning material.\n"
                insightCount += 1
            case .confused:
                insights += "• Confusion often indicates you're grappling with complex ideas. Breaking concepts into smaller parts might help.\n"
                insightCount += 1
            case .frustrated:
                insights += "• Frustration can signal you're pushing against the boundaries of your understanding. Perseverance here often leads to breakthroughs.\n"
                insightCount += 1
            case .overwhelmed:
                insights += "• When feeling overwhelmed, try breaking the material into smaller, manageable sections to build understanding incrementally.\n"
                insightCount += 1
            default:
                insights += "• Awareness of your emotional state while learning can help you develop strategies that work best for your learning style.\n"
                insightCount += 1
            }
        }
        
        return insights
    }
    
    /// Generates cumulative insights based on historical journal entries
    /// - Parameter entry: The current journal entry
    /// - Returns: A string containing cumulative insights
    func generateCumulativeInsights(for entry: JournalEntry) async -> String {
        do {
            return try await generateCumulativeInsightsHelper(for: entry)
        } catch {
            print("Error generating cumulative insights: \(error.localizedDescription)")
            return "Unable to generate historical insights at this time."
        }
    }
    
    private func generateCumulativeInsightsHelper(for entry: JournalEntry) async throws -> String {
        // Get historical insights from the analyzer
        let historicalInsights = await insightAnalyzer.generateCumulativeInsights(for: entry)
        
        // If no historical insights, return an empty string
        if historicalInsights.isEmpty {
            return ""
        }
        
        // Format the historical insights
        var formattedInsights = "\n\nBased on your learning journey:\n\n"
        
        // Sort insights by relevance (if available) or default to sorting by category
        let sortedInsights = historicalInsights
            .sorted { ($0.relevance ?? 0.5) > ($1.relevance ?? 0.5) }
            .prefix(3) // Limit to top 3 insights
        
        for insight in sortedInsights {
            formattedInsights += "• \(insight.content)\n\n"
        }
        
        return formattedInsights
    }
    
    /// Combines current insights with cumulative insights
    /// - Parameters:
    ///   - current: Current insights based on the current entry
    ///   - cumulative: Cumulative insights based on historical entries
    /// - Returns: Combined insights string
    func combineInsights(current: String, cumulative: String) -> String {
        if cumulative.isEmpty {
            return current
        }
        
        return current + cumulative
    }
}
