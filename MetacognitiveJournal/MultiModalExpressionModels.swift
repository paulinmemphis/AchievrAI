import SwiftUI
import AVFoundation
import Combine

// MARK: - MultiModal Namespace

/// Namespace for multi-modal expression components to avoid naming conflicts
enum MultiModal {
    // MARK: - Emotion Types
    
    /// Categories of emotions
    enum EmotionCategory: String, Codable, CaseIterable {
        case joy
        case sadness
        case anger
        case fear
        case surprise
        case disgust
        case neutral
    }
    
    /// Intensity levels for emotions
    enum EmotionIntensity: Int, Codable, CaseIterable {
        case veryLow = 1
        case low = 2
        case medium = 3
        case high = 4
        case veryHigh = 5
    }
    
    /// Represents an emotion with name, category, and intensity
    struct Emotion: Identifiable, Codable, Equatable {
        let id: UUID
        let name: String
        let category: String
        let intensity: Int
        
        init(id: UUID = UUID(), name: String, intensity: Int, category: String) {
            self.id = id
            self.name = name
            self.intensity = intensity
            self.category = category
        }
        
        static func == (lhs: Emotion, rhs: Emotion) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name && lhs.category == rhs.category && lhs.intensity == rhs.intensity
        }
    }
    
    // MARK: - Core Multi-Modal Types
    
    /// Represents the different types of media that can be included in a journal entry
    enum MediaType: String, CaseIterable, Codable, Identifiable {
        case text
        case drawing
        case photo
        case audio
        case video
        case emotionColor
        case emotionMusic
        case emotionMovement
        case visualMetaphor
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .text: return "text.justifyleft"
            case .drawing: return "scribble"
            case .photo: return "photo"
            case .audio: return "mic"
            case .video: return "video"
            case .emotionColor: return "paintpalette"
            case .emotionMusic: return "music.note"
            case .emotionMovement: return "figure.walk"
            case .visualMetaphor: return "brain"
            }
        }
        
        var displayName: String {
            switch self {
            case .text: return "Writing"
            case .drawing: return "Drawing"
            case .photo: return "Photo"
            case .audio: return "Voice"
            case .video: return "Video"
            case .emotionColor: return "Color Feelings"
            case .emotionMusic: return "Music Feelings"
            case .emotionMovement: return "Movement"
            case .visualMetaphor: return "Thinking Picture"
            }
        }
        
        var childFriendlyDescription: String {
            switch self {
            case .text: return "Write your thoughts"
            case .drawing: return "Draw how you feel"
            case .photo: return "Take or add a picture"
            case .audio: return "Record your voice"
            case .video: return "Record a video"
            case .emotionColor: return "Show feelings with colors"
            case .emotionMusic: return "Express with music"
            case .emotionMovement: return "Show with movement"
            case .visualMetaphor: return "Draw how your mind works"
            }
        }
    }
    
    /// Represents a single media item in a multi-modal journal entry
    struct MediaItem: Identifiable, Codable {
        let id: UUID
        let type: MediaType
        let createdAt: Date
        let title: String?
        let description: String?
        let fileURL: URL?
        let textContent: String?
        let colorData: ColorData?
        let drawingData: DrawingData?
        let emotionMusicData: EmotionMusicData?
        let emotionMovementData: EmotionMovementData?
        let visualMetaphorData: VisualMetaphorData?
        let associatedEmotion: Emotion?
        let associatedThought: String?
        let learningAreaTag: String?
        let metacognitiveProcess: MetacognitiveProcess? // Renamed from MetacognitiveSkill
        
        init(
            id: UUID = UUID(),
            type: MediaType,
            createdAt: Date = Date(),
            title: String? = nil,
            description: String? = nil,
            fileURL: URL? = nil,
            textContent: String? = nil,
            colorData: ColorData? = nil,
            drawingData: DrawingData? = nil,
            emotionMusicData: EmotionMusicData? = nil,
            emotionMovementData: EmotionMovementData? = nil,
            visualMetaphorData: VisualMetaphorData? = nil,
            associatedEmotion: Emotion? = nil,
            associatedThought: String? = nil,
            learningAreaTag: String? = nil,
            metacognitiveProcess: MetacognitiveProcess? = nil // Renamed from MetacognitiveSkill
        ) {
            self.id = id
            self.type = type
            self.createdAt = createdAt
            self.title = title
            self.description = description
            self.fileURL = fileURL
            self.textContent = textContent
            self.colorData = colorData
            self.drawingData = drawingData
            self.emotionMusicData = emotionMusicData
            self.emotionMovementData = emotionMovementData
            self.visualMetaphorData = visualMetaphorData
            self.associatedEmotion = associatedEmotion
            self.associatedThought = associatedThought
            self.learningAreaTag = learningAreaTag
            self.metacognitiveProcess = metacognitiveProcess
        }
    }
    
    /// Represents color data for emotional expression
    struct ColorData: Codable {
        let colors: [ColorInfo]
        let pattern: ColorPattern
        let intensity: Int // 1-10
        let description: String?
        
        struct ColorInfo: Codable, Equatable {
            let red: Double
            let green: Double
            let blue: Double
            let opacity: Double
            let meaning: String?
            
            var color: Color {
                Color(red: red, green: green, blue: blue, opacity: opacity)
            }
            
            static func == (lhs: ColorInfo, rhs: ColorInfo) -> Bool {
                return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue && lhs.opacity == rhs.opacity && lhs.meaning == rhs.meaning
            }
        }
        
        enum ColorPattern: String, Codable {
            case solid
            case gradient
            case radial
            case scattered
            case layered
            case swirled
        }
    }
    
    /// Represents drawing data for visual expression
    struct DrawingData: Codable {
        let strokes: [Stroke]
        let background: ColorData.ColorInfo?
        // Store CGSize components for Codable conformance
        let sizeWidth: CGFloat
        let sizeHeight: CGFloat
        var size: CGSize { // Computed property to access CGSize
            CGSize(width: sizeWidth, height: sizeHeight)
        }
        
        struct Stroke: Codable, Equatable {
            let points: [CGPoint]
            let color: ColorData.ColorInfo
            let width: CGFloat
            
            enum CodingKeys: String, CodingKey {
                case points, color, width
            }
            
            init(points: [CGPoint], color: ColorData.ColorInfo, width: CGFloat) {
                self.points = points
                self.color = color
                self.width = width
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // Decode points as array of CGPoint
                let pointsData = try container.decode([CGPointData].self, forKey: .points)
                self.points = pointsData.map { CGPoint(x: $0.x, y: $0.y) }
                
                self.color = try container.decode(ColorData.ColorInfo.self, forKey: .color)
                self.width = try container.decode(CGFloat.self, forKey: .width)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                // Encode points as array of CGPointData
                let pointsData = points.map { CGPointData(x: $0.x, y: $0.y) }
                try container.encode(pointsData, forKey: .points)
                
                try container.encode(color, forKey: .color)
                try container.encode(width, forKey: .width)
            }
            
            // MARK: Equatable Conformance
            static func == (lhs: Stroke, rhs: Stroke) -> Bool {
                // Compare points array, color info, and width
                // Note: Comparing CGPoints arrays requires element-wise comparison
                guard lhs.points.count == rhs.points.count else { return false }
                for (lp, rp) in zip(lhs.points, rhs.points) {
                    if lp != rp { return false }
                }
                return lhs.color == rhs.color && lhs.width == rhs.width
            }
        }
        
        struct CGPointData: Codable {
            let x: CGFloat
            let y: CGFloat
            
            init(x: CGFloat, y: CGFloat) {
                self.x = x
                self.y = y
            }
        }
        
        // MARK: - Codable Conformance for DrawingData
        
        enum CodingKeys: String, CodingKey {
            case strokes, background
            // Map size components
            case sizeWidth, sizeHeight
        }

        init(strokes: [Stroke], background: ColorData.ColorInfo?, size: CGSize) {
            self.strokes = strokes
            self.background = background
            self.sizeWidth = size.width
            self.sizeHeight = size.height
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            strokes = try container.decode([Stroke].self, forKey: .strokes)
            background = try container.decodeIfPresent(ColorData.ColorInfo.self, forKey: .background)
            sizeWidth = try container.decode(CGFloat.self, forKey: .sizeWidth)
            sizeHeight = try container.decode(CGFloat.self, forKey: .sizeHeight)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(strokes, forKey: .strokes)
            try container.encodeIfPresent(background, forKey: .background)
            try container.encode(sizeWidth, forKey: .sizeWidth)
            try container.encode(sizeHeight, forKey: .sizeHeight)
        }
    }
    
    /// Represents music data for emotional expression
    struct EmotionMusicData: Codable {
        let tempo: Int // beats per minute
        let instrument: Instrument
        let melody: [Note]
        let volume: Int // 1-10
        let duration: TimeInterval
        
        enum Instrument: String, Codable, CaseIterable {
            case piano
            case guitar
            case drums
            case violin
            case flute
            case bells
            case electronic
            
            var displayName: String { rawValue.capitalized }
            var iconName: String {
                switch self {
                case .piano: return "pianokeys"
                case .guitar: return "guitars"
                case .drums: return "music.quarternote.3"
                case .violin: return "music.note"
                case .flute: return "music.note.list"
                case .bells: return "bell"
                case .electronic: return "waveform"
                }
            }
        }
        
        struct Note: Codable {
            let pitch: Int // MIDI note number (0-127)
            let duration: TimeInterval // in seconds
            let velocity: Int // 0-127, how hard the note is played
        }
    }
    
    /// Represents movement data for emotional expression
    struct EmotionMovementData: Codable {
        let movements: [Movement]
        let duration: TimeInterval
        let intensity: Int // 1-10
        let tempo: Int // beats per minute
        
        struct Movement: Codable {
            let type: MovementType
            let duration: TimeInterval
            let intensity: Int // 1-10
            
            enum MovementType: String, Codable, CaseIterable {
                case jumping
                case spinning
                case swaying
                case stomping
                case reaching
                case curling
                case stretching
                case bouncing
                case floating
                case shaking
                
                var displayName: String { rawValue.capitalized }
            }
        }
    }
    
    /// Represents visual metaphor data for metacognitive expression
    struct VisualMetaphorData: Codable {
        let metaphorType: MetaphorType
        let elements: [MetaphorElement]
        let background: ColorData.ColorInfo?
        
        enum MetaphorType: String, Codable, CaseIterable {
            case journey
            case container
            case machine
            case nature
            case weather
            case building
            case puzzle
            case character
            case custom
            
            var displayName: String { rawValue.capitalized }
            var description: String {
                switch self {
                case .journey: return "A path showing your thinking process"
                case .container: return "Boxes or containers for different thoughts"
                case .machine: return "A machine showing how your thoughts work together"
                case .nature: return "Natural elements like trees or rivers for your thoughts"
                case .weather: return "Weather patterns showing your thinking climate"
                case .building: return "A structure built from your thoughts"
                case .puzzle: return "Puzzle pieces showing how thoughts connect"
                case .character: return "Characters representing different parts of your thinking"
                case .custom: return "Your own unique way of showing your thinking"
                }
            }
        }
        
        struct MetaphorElement: Identifiable, Codable {
            let id: UUID
            let elementType: String // What kind of element (e.g., 'box', 'path', 'cloud')
            let text: String // Text label for the element
            let position: CGPoint
            
            enum CodingKeys: String, CodingKey {
                // Map elementType to 'type' for encoding/decoding if needed, or keep as elementType
                case id, elementType = "type", text, position
            }
            
            // Custom init for convenience if needed
             init(id: UUID = UUID(), elementType: String, text: String, position: CGPoint) {
                 self.id = id
                 self.elementType = elementType
                 self.text = text
                 self.position = position
             }

            // Manual encode to handle CGPoint
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(elementType, forKey: .elementType) // Encode as 'type'
                try container.encode(text, forKey: .text)
                // Encode position as an array [x, y]
                try container.encode([position.x, position.y], forKey: .position)
            }

            // Manual decode to handle CGPoint
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(UUID.self, forKey: .id)
                elementType = try container.decode(String.self, forKey: .elementType) // Decode from 'type'
                text = try container.decode(String.self, forKey: .text)
                // Decode position from array [x, y]
                let positionArray = try container.decode([CGFloat].self, forKey: .position)
                guard positionArray.count == 2 else {
                    throw DecodingError.dataCorruptedError(forKey: .position,
                                                       in: container,
                                                       debugDescription: "Position array must contain exactly two elements (x, y).")
                }
                position = CGPoint(x: positionArray[0], y: positionArray[1])
            }
        }
    }
    
    /// Represents a multi-modal journal entry with multiple media items
    struct JournalEntry: Identifiable, Codable {
        let id: UUID
        let childId: String
        let title: String
        let createdAt: Date
        let modifiedAt: Date
        let mediaItems: [MediaItem]
        var mood: Emotion? // Changed let to var
        let tags: [String]?
        let isPrivate: Bool
        let learningAreaTags: [String]?
        let metacognitiveProcesses: [MetacognitiveProcess]? // Renamed from MetacognitiveSkill
        
        init(
            id: UUID = UUID(),
            childId: String,
            title: String,
            createdAt: Date = Date(),
            modifiedAt: Date = Date(),
            mediaItems: [MediaItem] = [],
            mood: Emotion? = nil,
            tags: [String]? = nil,
            isPrivate: Bool = false,
            learningAreaTags: [String]? = nil,
            metacognitiveProcesses: [MetacognitiveProcess]? = nil // Renamed from MetacognitiveSkill
        ) {
            self.id = id
            self.childId = childId
            self.title = title
            self.createdAt = createdAt
            self.modifiedAt = modifiedAt
            self.mediaItems = mediaItems
            self.mood = mood
            self.tags = tags
            self.isPrivate = isPrivate
            self.learningAreaTags = learningAreaTags
            self.metacognitiveProcesses = metacognitiveProcesses
        }
        
        /// Returns the primary text content if available
        var primaryTextContent: String? {
            mediaItems.first(where: { $0.type == .text })?.textContent
        }
        
        /// Returns all text content combined
        var allTextContent: String {
            mediaItems.compactMap { $0.textContent }.joined(separator: "\n\n")
        }
        
        /// Returns all media items of a specific type
        func mediaItems(ofType type: MediaType) -> [MediaItem] {
            mediaItems.filter { $0.type == type }
        }
    }
    
    /// Represents metadata extracted from a journal entry
    struct EntryMetadata: Codable {
        let sentiment: String
        let themes: [String]
        let entities: [String]
        let keyPhrases: [String]
        
        var dictionary: [String: Any] {
            return [
                "sentiment": sentiment,
                "themes": themes,
                "entities": entities,
                "keyPhrases": keyPhrases
            ]
        }
    }
    
    /// A node in the story map representing the relationship between journal entries and story chapters
    struct StoryNode: Identifiable, Codable {
        let entryId: UUID
        let chapterId: String
        let parentId: String?
        let metadata: EntryMetadata?
        
        var id: String { chapterId }
    }
    
    /// Manages the creation, storage, and retrieval of multi-modal journal entries
    class JournalManager: ObservableObject {
        // MARK: - Singleton
        static let shared = JournalManager()
        
        // MARK: - Published Properties
        @Published var entries: [JournalEntry] = []
        @Published var currentEntry: JournalEntry?
        @Published var isRecording = false
        @Published var isProcessing = false
        @Published var errorMessage: String?
        @Published var storyNodes: [StoryNode] = []
        
        // MARK: - Private Properties
        private var audioRecorder: AVAudioRecorder?
        private var videoRecordingSession: Any?
        private var cancellables = Set<AnyCancellable>()
        
        // MARK: - Initialization
        init() {
            loadEntries()
        }
        
        // MARK: - Public Methods
        
        /// Creates a new multi-modal journal entry
        func createEntry(childId: String, title: String) -> JournalEntry {
            let entry = JournalEntry(
                childId: childId,
                title: title
            )
            entries.append(entry)
            saveEntries()
            return entry
        }
        
        /// Adds a media item to an entry
        func addMediaItem(_ item: MediaItem, to entryId: UUID) {
            guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }
            
            var updatedEntry = entries[index]
            var updatedMediaItems = updatedEntry.mediaItems
            updatedMediaItems.append(item)
            
            updatedEntry = JournalEntry(
                id: updatedEntry.id,
                childId: updatedEntry.childId,
                title: updatedEntry.title,
                createdAt: updatedEntry.createdAt,
                modifiedAt: Date(),
                mediaItems: updatedMediaItems,
                mood: updatedEntry.mood,
                tags: updatedEntry.tags,
                isPrivate: updatedEntry.isPrivate,
                learningAreaTags: updatedEntry.learningAreaTags,
                metacognitiveProcesses: updatedEntry.metacognitiveProcesses // Renamed from MetacognitiveSkill
            )
            
            entries[index] = updatedEntry
            if currentEntry?.id == entryId {
                currentEntry = updatedEntry
            }
            saveEntries() // Add this line to persist the changes
        }
        
        /// Updates an existing media item
        func updateMediaItem(_ item: MediaItem, in entryId: UUID) {
            guard let entryIndex = entries.firstIndex(where: { $0.id == entryId }) else { return }
            guard let itemIndex = entries[entryIndex].mediaItems.firstIndex(where: { $0.id == item.id }) else { return }
            
            var updatedEntry = entries[entryIndex]
            var updatedMediaItems = updatedEntry.mediaItems
            updatedMediaItems[itemIndex] = item
            
            updatedEntry = JournalEntry(
                id: updatedEntry.id,
                childId: updatedEntry.childId,
                title: updatedEntry.title,
                createdAt: updatedEntry.createdAt,
                modifiedAt: Date(),
                mediaItems: updatedMediaItems,
                mood: updatedEntry.mood,
                tags: updatedEntry.tags,
                isPrivate: updatedEntry.isPrivate,
                learningAreaTags: updatedEntry.learningAreaTags,
                metacognitiveProcesses: updatedEntry.metacognitiveProcesses // Renamed from MetacognitiveSkill
            )
            
            entries[entryIndex] = updatedEntry
            if currentEntry?.id == entryId {
                currentEntry = updatedEntry
            }
            
            saveEntries()
        }
        
        /// Removes a media item from an entry
        func removeMediaItem(withId itemId: UUID, from entryId: UUID) {
            guard let entryIndex = entries.firstIndex(where: { $0.id == entryId }) else { return }
            
            var updatedEntry = entries[entryIndex]
            let updatedMediaItems = updatedEntry.mediaItems.filter { $0.id != itemId }
            
            updatedEntry = JournalEntry(
                id: updatedEntry.id,
                childId: updatedEntry.childId,
                title: updatedEntry.title,
                createdAt: updatedEntry.createdAt,
                modifiedAt: Date(),
                mediaItems: updatedMediaItems,
                mood: updatedEntry.mood,
                tags: updatedEntry.tags,
                isPrivate: updatedEntry.isPrivate,
                learningAreaTags: updatedEntry.learningAreaTags,
                metacognitiveProcesses: updatedEntry.metacognitiveProcesses // Renamed from MetacognitiveSkill
            )
            
            entries[entryIndex] = updatedEntry
            if currentEntry?.id == entryId {
                currentEntry = updatedEntry
            }
            
            saveEntries()
        }
        
        /// Deletes a journal entry by its ID.
        /// - Parameter id: The UUID of the entry to delete.
        func deleteEntry(withId id: UUID) {
            if let index = entries.firstIndex(where: { $0.id == id }) {
                entries.remove(at: index)
                saveEntries() // Persist the deletion
            }
        }
        
        /// Updates the metadata of an entry
        func updateEntry(
            id: UUID,
            title: String? = nil,
            mood: Emotion? = nil,
            tags: [String]? = nil,
            isPrivate: Bool? = nil,
            learningAreaTags: [String]? = nil,
            metacognitiveProcesses: [MetacognitiveProcess]? = nil // Renamed from MetacognitiveSkill
        ) {
            guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
            
            var updatedEntry = entries[index]
            
            if let title = title {
                updatedEntry = JournalEntry(
                    id: updatedEntry.id,
                    childId: updatedEntry.childId,
                    title: title,
                    createdAt: updatedEntry.createdAt,
                    modifiedAt: Date(),
                    mediaItems: updatedEntry.mediaItems,
                    mood: mood ?? updatedEntry.mood,
                    tags: tags ?? updatedEntry.tags,
                    isPrivate: isPrivate ?? updatedEntry.isPrivate,
                    learningAreaTags: learningAreaTags ?? updatedEntry.learningAreaTags,
                    metacognitiveProcesses: metacognitiveProcesses ?? updatedEntry.metacognitiveProcesses // Renamed from MetacognitiveSkill
                )
                
                entries[index] = updatedEntry
                if currentEntry?.id == id {
                    currentEntry = updatedEntry
                }
                
                saveEntries()
            }
        }
        
        /// Retrieves all journal entries for a specific child.
        /// - Parameter childId: The ID of the child.
        func entries(forChild childId: String) -> [JournalEntry] {
            entries.filter { $0.childId == childId }
        }
        
        /// Starts recording audio
        func startAudioRecording() -> URL? {
            let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder?.record()
                isRecording = true
                return audioFilename
            } catch {
                errorMessage = "Could not start recording: \(error.localizedDescription)"
                return nil
            }
        }
        
        /// Stops recording audio
        func stopAudioRecording() -> URL? {
            guard let recorder = audioRecorder, recorder.isRecording else {
                return nil
            }
            
            recorder.stop()
            isRecording = false
            let url = recorder.url
            audioRecorder = nil
            return url
        }
        
        // MARK: - Private Methods
        
        private func loadEntries() {
            // In a real app, this would load from persistent storage
            // For now, we'll use sample data
            entries = sampleEntries
        }
        
        private func saveEntries() {
            // In a real app, this would save to persistent storage
        }
        
        private func getDocumentsDirectory() -> URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        
        // MARK: - Sample Data
        
        private var sampleEntries: [JournalEntry] {
            [
                JournalEntry(
                    id: UUID(),
                    childId: "child1",
                    title: "My Science Project",
                    createdAt: Date().addingTimeInterval(-86400), // Yesterday
                    modifiedAt: Date().addingTimeInterval(-86400),
                    mediaItems: [
                        MediaItem(
                            type: .text,
                            textContent: "Today I worked on my science project about plants. I'm measuring how different types of water affect plant growth."
                        ),
                        MediaItem(
                            type: .drawing,
                            drawingData: DrawingData(
                                strokes: [],
                                background: nil,
                                size: CGSize(width: 300, height: 200)
                            )
                        )
                    ],
                    mood: Emotion(name: "Excited", intensity: EmotionIntensity.medium.rawValue, category: EmotionCategory.joy.rawValue),
                    tags: ["Science", "Plants", "Experiment"],
                    learningAreaTags: ["Science"],
                    metacognitiveProcesses: [.planning, .monitoring] // Renamed from MetacognitiveSkill
                )
            ]
        }
    }
}

// MARK: - Adapter Function
extension MultiModal {
    
    /// Adapts a JournalEntry into a standard JournalEntry for compatibility.
    /// Synthesizes text from various media types.
    static func adaptToStandardEntry(_ multiModalEntry: JournalEntry) -> MetacognitiveJournal.JournalEntry? {
        var combinedContent: [String] = []
        var primaryEmotionalState: EmotionalState = .neutral // Default, maybe refine later
        
        for item in multiModalEntry.mediaItems {
            switch item.type {
            case .text:
                if let textData = item.textContent {
                    combinedContent.append(textData)
                }
            case .audio:
                // Prefer transcription if available
                if let audioData = item.fileURL {
                    let transcription = "Transcription: \(audioData.lastPathComponent)"
                    if !transcription.isEmpty {
                        combinedContent.append(transcription)
                    } else {
                        combinedContent.append("[Empty Audio Transcription]") // Handle case where filename might be empty?
                    }
                } else {
                    combinedContent.append("[Audio Recording Attached - No URL]")
                }
            case .drawing:
                // Basic placeholder for drawings
                combinedContent.append("[User Drawing Attached]")
                // Future enhancement: Could add OCR or a basic description if available
            case .photo:
                // Basic placeholder for photos
                combinedContent.append("[User Photo Attached]")
                // Future enhancement: Could add image captioning results
            case .video:
                combinedContent.append("[User Video Attached]")
            case .emotionColor:
                if let colorData = item.colorData {
                    let emotionDesc = colorData.description ?? "Unspecified Emotion"
                    let colorDesc = colorData.colors.first?.meaning ?? "Selected Color"
                    combinedContent.append("Color Emotion: Expressed \(emotionDesc) using \(colorDesc).")
                    // Potentially map this emotion to the primary emotional state
                    if let mappedState = mapMultiModalEmotionToStandard(colorData) {
                        primaryEmotionalState = mappedState // Or some logic to choose the 'dominant' emotion
                    }
                }
            case .emotionMusic:
                combinedContent.append("[User Music Attached]")
            case .emotionMovement:
                combinedContent.append("[User Movement Data Attached]")
            case .visualMetaphor:
                combinedContent.append("[Visual Metaphor Drawing Attached]")
                // Similar enhancements as drawing possible
            }
        }
        
        // Create the main content string for reflectionPrompts
        let synthesizedText = combinedContent.joined(separator: "\n\n")
        
        // Create the PromptResponse array
        let reflectionPrompts = [
            PromptResponse(id: UUID(), prompt: "Multi-Modal Journal Entry", response: synthesizedText)
        ]
        
        // Create the standard JournalEntry
        // Note: We need to decide how to map/handle fields like 'subject'
        // Using defaults for now.
        let standardEntry: MetacognitiveJournal.JournalEntry = MetacognitiveJournal.JournalEntry(
            id: multiModalEntry.id, // Use the same ID for linkage
            assignmentName: multiModalEntry.title,
            date: multiModalEntry.createdAt,
            subject: K12Subject.writing, // Changed from .creativeWriting to .writing
            emotionalState: primaryEmotionalState, // Use derived state
            reflectionPrompts: reflectionPrompts,
            aiSummary: nil as String?,
            aiTone: nil as String?,
            transcription: nil as String?,
            audioURL: multiModalEntry.mediaItems.first(where: { $0.type == .audio })?.fileURL, // Extract URL if audio exists
            metadata: nil as MetacognitiveJournal.EntryMetadata? // TODO: Adapt metadata if needed
        )
        
        return standardEntry
    }
    
    // Helper function to map emotions (needs implementation)
    static func mapMultiModalEmotionToStandard(_ multiModalEmotion: ColorData?) -> EmotionalState? {
        guard let emotion = multiModalEmotion else { return nil }
        // Simple example mapping - expand as needed
        // Return correct enum cases
        switch emotion.description?.lowercased() { // Use description and make case-insensitive
        case "joy", "happy":
            return .satisfied // Or .confident based on context
        case "sadness", "sad":
            return .frustrated // Or .overwhelmed
        case "anger", "angry":
            return .frustrated
        case "fear", "scared":
            return .overwhelmed
        case "surprise", "surprised":
             return .curious
        // Add other mappings as needed
        default:
            return .neutral // Fallback to neutral
        }
    }
}

extension MultiModal.JournalEntry {
    /// Adapts a multi-modal journal entry to a standard JournalEntry.
    func adaptToStandardEntry() -> MetacognitiveJournal.JournalEntry {
        // Initialize with default or extracted values
        var extractedText: String? = nil
        var mainEmotionalState: EmotionalState = .neutral // Default
        var promptResponses: [PromptResponse] = []
        // TODO: Define logic to extract or infer these from mediaItems

        // Explicitly type the variable to avoid ambiguity
        let standardEntry: MetacognitiveJournal.JournalEntry = MetacognitiveJournal.JournalEntry(
            id: self.id, // Use the same ID
            assignmentName: self.title,
            date: self.createdAt,
            subject: .writing, // Changed from .creativeWriting to .writing
            emotionalState: mainEmotionalState,
            reflectionPrompts: promptResponses,
            aiSummary: nil, // AI features can be run later
            aiTone: nil,
            transcription: extractedText,
            metadata: nil as MetacognitiveJournal.EntryMetadata? // Ensure correct metadata type
        )
        
        return standardEntry
    }
}
