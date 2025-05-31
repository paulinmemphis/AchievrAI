import SwiftUI
import Combine
import PencilKit
import AVFoundation

/// Namespace for multi-modal expression components to avoid naming conflicts
extension MultiModal {
    /// A view that allows children to create journal entries using multiple forms of expression
    @available(*, deprecated, message: "Use GuidedMultiModalJournalView instead")
    struct JournalEntryView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var journalManager: MultiModal.JournalManager
    
    // MARK: - Properties
    let childId: String
    // Use the correct Enum type
    let readingLevel: ReadingLevel
    // Use the correct Enum type
    let journalMode: ChildJournalMode
    let onSave: (MultiModal.JournalEntry) -> Void
    let onCancel: () -> Void
    
    // MARK: - State
    @State private var entry: MultiModal.JournalEntry
    @State private var selectedMediaType: MultiModal.MediaType? = .text
    @State private var textContent: String = ""
    @State private var showingMediaPicker = false
    @State private var showingEmotionPicker = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var drawingData: MultiModal.DrawingData?
    @State private var isEditingTitle = false
    @State private var entryTitle: String
    @State private var showingMediaItemOptions: MultiModal.MediaItem? = nil
    @State private var showingColorMeaningSheet = false // For drawing/color tools
    @State private var showingMediaPickerSheet = false // Added L76 fix
    @State private var showingEmotionPickerSheet = false // Added L79 fix
    @State private var currentDrawingData: MultiModal.DrawingData? = nil // Added for DrawingToolView binding
    @State private var selectedEmotion: MultiModal.Emotion? // Added for L87 fix
    
    // MARK: - Initialization
    // Update init signature to use correct enum types
    init(childId: String, readingLevel: ReadingLevel, journalMode: ChildJournalMode, onSave: @escaping (MultiModal.JournalEntry) -> Void, onCancel: @escaping () -> Void) {
        self.childId = childId
        self.readingLevel = readingLevel
        self.journalMode = journalMode
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Create a new entry
        let newEntry = MultiModal.JournalEntry(childId: childId, title: "My Journal Entry")
        _entry = State(initialValue: newEntry)
        _entryTitle = State(initialValue: newEntry.title)
        _selectedEmotion = State(initialValue: newEntry.mood) // Initialize selectedEmotion
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and controls
            entryHeader
            
            // Media content area
            ScrollView {
                VStack(spacing: 16) {
                    // Title editing area
                    titleSection
                    
                    // Media items display
                    mediaItemsSection
                    
                    // Current media editing area
                    mediaEditingSection
                }
                .padding()
            }
            
            // Footer with media type selection and save/cancel buttons
            entryFooter
        }
        .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        .sheet(isPresented: $showingMediaPickerSheet) {
            // TODO: Replace with actual media picker view
            Text("Media Picker Sheet Placeholder") 
        }
        .sheet(isPresented: $showingEmotionPickerSheet) {
            EmotionPickerView(currentMode: journalMode, selectedMood: $selectedEmotion)
                .environmentObject(themeManager)
        }
        .onChange(of: selectedEmotion) { newMood in
            entry.mood = newMood
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveEntryAndDismiss()
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var entryHeader: some View {
        HStack {
            Text("Create Journal Entry")
                .font(fontForMode(size: 20, weight: .bold))
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            
            Spacer()
            
            // Emotion button
            Button(action: {
                showingEmotionPicker = true
            }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24))
                    .foregroundColor(entry.mood != nil ? themeManager.themeForChildMode(journalMode).accentColor : themeManager.themeForChildMode(journalMode).secondaryTextColor)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 8)
        }
        .padding()
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditingTitle {
                TextField("Entry Title", text: $entryTitle, onCommit: {
                    isEditingTitle = false
                    updateEntryTitle()
                })
                .font(fontForMode(size: 18, weight: .bold))
                .padding(8)
                .background(themeManager.themeForChildMode(journalMode).inputBackgroundColor)
                .cornerRadius(8)
                .onAppear {
                    // Auto-select the text when editing begins
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            } else {
                HStack {
                    Text(entryTitle)
                        .font(fontForMode(size: 18, weight: .bold))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    
                    Spacer()
                    
                    Button(action: {
                        isEditingTitle = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(8)
                .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .cornerRadius(8)
            }
            
            if let mood = entry.mood {
                HStack {
                    Text(mood.name)
                        .font(fontForMode(size: 14, weight: .medium))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    Spacer()
                    // Emotion intensity indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(i < mood.intensity ? moodColor(for: mood.category) : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private var mediaItemsSection: some View {
        ForEach(entry.mediaItems) { item in
            mediaItemView(for: item)
                .padding(.vertical, 8)
        }
    }
    
    private func mediaItemView(for item: MultiModal.MediaItem) -> some View {
        VStack(alignment: .leading) {
            HStack {
                // Media type icon
                Image(systemName: iconForMediaType(item.type))
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                
                Text(titleForMediaType(item.type))
                    .font(fontForMode(size: 14, weight: .medium))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                
                Spacer()
                
                // Delete button
                Button(action: {
                    deleteMediaItem(item)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.red.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            // Media content
            mediaContentView(for: item)
                .padding(8)
                .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .cornerRadius(8)
        }
    }
    
    // Add @ViewBuilder (L215 fix)
    @ViewBuilder
    private func mediaContentView(for item: MultiModal.MediaItem) -> some View {
        switch item.type {
        case .text:
            // Add explicit else block to handle nil case
            if let text: String = item.textContent {
                Text(text)
                    .font(fontForMode(size: 16))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Provide an explicit view for the nil case
                EmptyView()
            }
        case .drawing:
            if let drawingData = item.drawingData {
                // Use placeholder instead of non-existent .image property
                Image(systemName: "scribble.variable")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    .frame(maxWidth: 100, maxHeight: 100)
                    .cornerRadius(8)
            } else {
                EmptyView()
            }
        case .photo:
            if let photoURL = item.fileURL {
                Image(uiImage: UIImage(contentsOfFile: photoURL.path) ?? UIImage(systemName: "photo")!)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            }
        case .audio:
            if let audioURL = item.fileURL {
                Image(systemName: "waveform") // Placeholder
                    .resizable()
                    .scaledToFit()
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
    
    private var mediaEditingSection: some View {
        VStack {
            switch selectedMediaType {
            case .text:
                textEditor
            case .drawing:
                drawingCanvas
            case .photo:
                photoPlaceholder
            case .audio:
                audioRecorder
            default:
                EmptyView()
            }
        }
        .padding(.top)
    }
    
    private var textEditor: some View {
        TextEditor(text: $textContent)
            .frame(height: 150)
            .border(themeManager.themeForChildMode(journalMode).secondaryTextColor.opacity(0.5), width: 1)
            .font(fontForMode(size: 16))
            .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            .onDisappear { saveTextEntry() }
    }
    
    private var drawingCanvas: some View {
        // Ensure currentDrawingData is initialized before presenting
        DrawingToolView(
            drawingData: $currentDrawingData, 
            onSave: saveDrawingEntry, 
            onCancel: { currentDrawingData = nil; selectedMediaType = nil }, // Also clear type on cancel
            journalMode: journalMode, 
            emotionContext: false,   
            metaphorContext: false  
        )
        .environmentObject(themeManager)
        // Allow the drawing view to expand vertically and horizontally
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Restore flexible frame
    }
    
    private var photoPlaceholder: some View {
        VStack {
            Button(action: {
                openPhotoSelector()
            }) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                    Text("Add Photo")
                        .font(fontForMode(size: 16))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
        .cornerRadius(8)
    }
    
    private var audioRecorder: some View {
        VStack {
            Button(action: {
                openAudioRecorder()
            }) {
                VStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                    Text("Record Audio")
                        .font(fontForMode(size: 16))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
        .cornerRadius(8)
    }
    
    // MARK: - Footer Components
    private var entryFooter: some View {
        VStack {
            // Media type selector
            mediaTypeSelector
            
            Spacer()
            
            // Cancel and Save buttons
            footerButtons
        }
        .padding()
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    private var mediaTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MultiModal.MediaType.allCases, id: \.self) { mediaType in
                    mediaTypeButton(mediaType)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    private func mediaTypeButton(_ type: MultiModal.MediaType) -> some View {
        Button(action: { selectedMediaType = type }) {
            VStack(spacing: 4) {
                Image(systemName: iconForMediaType(type))
                    .font(.system(size: 24))
                    .foregroundColor(selectedMediaType == type ? themeManager.themeForChildMode(journalMode).accentColor : themeManager.themeForChildMode(journalMode).secondaryTextColor)
                Text(titleForMediaType(type))
                    .font(fontForMode(size: 10))
                    .foregroundColor(selectedMediaType == type ? themeManager.themeForChildMode(journalMode).accentColor : themeManager.themeForChildMode(journalMode).secondaryTextColor)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(selectedMediaType == type ? themeManager.themeForChildMode(journalMode).accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var footerButtons: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .font(fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                .padding(.horizontal)
            
            Button("Save", action: saveEntry)
                .font(fontForMode(size: 16, weight: .semibold))
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Views
    
    private func drawingPreview(_ data: MultiModal.DrawingData) -> some View {
        Image(systemName: "scribble.variable") // Use icon placeholder
            .resizable()
            .scaledToFit()
            .padding()
            .background(Color.gray.opacity(0.1))
            .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            .frame(maxWidth: 100, maxHeight: 100)
            .cornerRadius(8)
    }
    
    private func audioPreview(_ url: URL) -> some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            
            Text("Audio Recording")
                .font(fontForMode(size: 14))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
        }
    }
    
    // MARK: - Helper Methods
    
    private func titleForMediaType(_ type: MultiModal.MediaType) -> String {
        switch type {
        case .text: return "Text"
        case .drawing: return "Drawing"
        case .photo: return "Photo"
        case .audio: return "Audio"
        default: return "Media"
        }
    }
    
    private func iconForMediaType(_ type: MultiModal.MediaType) -> String {
        switch type {
        case .text: return "text.bubble.fill"
        case .drawing: return "pencil.and.scribble"
        case .photo: return "photo.fill"
        case .audio: return "mic.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let baseFont: Font
        let characteristics = journalMode.uiCharacteristics
        
        switch journalMode {
        case .earlyChildhood:
            baseFont = .system(size: characteristics.primaryFontSize, weight: weight, design: characteristics.fontDesign)
        case .middleChildhood:
            baseFont = .system(size: characteristics.primaryFontSize, weight: weight, design: characteristics.fontDesign)
        case .adolescent:
            baseFont = .system(size: characteristics.primaryFontSize, weight: weight, design: characteristics.fontDesign)
        default:
            baseFont = .system(size: size, weight: weight)
        }
        
        return baseFont
    }
    
    // MARK: - Action Methods
    
    private func updateEntryTitle() {
        if !entryTitle.isEmpty {
            journalManager.updateEntry(
                id: entry.id,
                title: entryTitle
            )
        }
    }
    
    private func addTextContent() {
        guard !textContent.isEmpty else { return }
        
        let mediaItem = MultiModal.MediaItem(
            type: .text,
            textContent: textContent
        )
        
        journalManager.addMediaItem(mediaItem, to: entry.id)
        textContent = ""
    }
    
    private func deleteMediaItem(_ item: MultiModal.MediaItem) {
        journalManager.removeMediaItem(withId: item.id, from: entry.id)
    }
    
    private func openDrawingTool() {
        // In a real implementation, this would present a drawing tool view
    }
    
    private func openAudioRecorder() {
        // In a real implementation, this would present an audio recording view
    }
    
    private func openPhotoSelector() {
        // In a real implementation, this would present a photo picker
    }
    
    // Modify saveEntry to update mood from selectedEmotion (L87 fix)
    private func saveEntry() {
        // Make a mutable copy of the entry
        var entryToSave = entry
        // Update the mood from the local state
        entryToSave.mood = selectedEmotion
        // Call the original onSave closure with the modified entry
        onSave(entryToSave)
    }

    private func saveEntryAndDismiss() {
        updateEntryTitle() // Ensure latest title is captured
        entry.mood = selectedEmotion // Ensure latest mood is captured
        onSave(entry)
    }
    
    private func saveTextEntry() {
        guard !textContent.isEmpty else { return }
        
        let mediaItem = MultiModal.MediaItem(
            type: .text,
            textContent: textContent
        )
        journalManager.addMediaItem(mediaItem, to: entry.id)
        textContent = ""
    }
    
    private func saveDrawingEntry(_ data: MultiModal.DrawingData) {
        print("Save drawing entry called")
        // Create MediaItem from DrawingData
        let mediaItem = MultiModal.MediaItem(
            type: .drawing,
            drawingData: data
        )
        // Add to journal manager
        journalManager.addMediaItem(mediaItem, to: entry.id)
        // Dismiss sheet or clear state
        currentDrawingData = nil 
        selectedMediaType = nil // Return to main view
        // Potentially need to dismiss a sheet here if DrawingToolView is presented modally
        // showingMediaPickerSheet = false // Or similar depending on presentation
    }
    
    private func moodColor(for category: String) -> Color {
        switch category.lowercased() {
        case "joy":
            return Color.yellow
        case "sadness":
            return Color.blue
        case "anger":
            return Color.red
        case "fear":
            return Color.purple
        case "surprise":
            return Color.orange
        case "disgust":
            return Color.green
        case "neutral":
            return Color.gray
        default: 
            return Color.gray
        }
    }
}

// MARK: - Emotion Picker View
struct EmotionPickerView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Properties
    let currentMode: ChildJournalMode
    @Binding var selectedMood: MultiModal.Emotion? // Use MultiModal.Emotion
    
    // MARK: - State
    @State private var selectedCategory: String = "joy"
    @State private var selectedIntensity: Int = 3 // medium
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Category selection
            categorySelector
            
            // Emotion Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                ForEach(emotionsForCategory(selectedCategory)) { emotion in
                   emotionButton(for: emotion) // Use helper
                }
            }
            .padding()
            
            // Intensity Slider
            intensitySlider
                .padding(.horizontal)
            
            // Buttons
            HStack {
                Button(action: {
                    selectedMood = nil
                }) {
                    Text("Clear Emotion")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .padding()
        .navigationBarTitle("How are you feeling?", displayMode: .inline)
    }
    
    // MARK: - UI Components
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["joy", "sadness", "anger", "fear", "surprise", "disgust", "neutral"], id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedCategory == category ? themeManager.themeForChildMode(currentMode).accentColor : themeManager.themeForChildMode(currentMode).secondaryTextColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? themeManager.themeForChildMode(currentMode).accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var intensitySlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How strong is this feeling?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(currentMode).primaryTextColor)
            
            HStack {
                Text("Gentle")
                Spacer()
                Text("Medium")
                Spacer()
                Text("Strong")
            }
            .font(.caption)
            .foregroundColor(themeManager.themeForChildMode(currentMode).secondaryTextColor)
            
            Slider(value: Binding(get: { Double(selectedIntensity) }, set: { selectedIntensity = Int($0) }), in: 1...5, step: 1)
                .accentColor(themeManager.themeForChildMode(currentMode).accentColor)
        }
    }
    
    // Extracted helper function for emotion button
    private func emotionButton(for emotion: EmotionOption) -> some View {
        Button(action: { 
            // Create the new mood object first
            let newMood = createMood(name: emotion.name, intensity: selectedIntensity, category: selectedCategory)
            // Then assign it to the binding
            selectedMood = newMood
            // Dismiss the sheet after selection
            dismiss()
        }) { 
            VStack {
                Text(emotion.emoji)
                    .font(.system(size: 36))
                
                Text(emotion.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.themeForChildMode(currentMode).primaryTextColor)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .background(selectedMood?.name == emotion.name ? themeManager.themeForChildMode(currentMode).accentColor.opacity(0.2) : themeManager.themeForChildMode(currentMode).cardBackgroundColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }

    private func moodColor(for category: String) -> Color {
        switch category.lowercased() {
        case "joy":
            return Color.yellow
        case "sadness":
            return Color.blue
        case "anger":
            return Color.red
        case "fear":
            return Color.purple
        case "surprise":
            return Color.orange
        case "disgust":
            return Color.green
        case "neutral":
            return Color.gray
        default: 
            return Color.gray
        }
    }

    private struct EmotionOption: Identifiable {
        let id: String // Added for Identifiable
        let name: String
        let emoji: String
        
        init(name: String, emoji: String) {
            self.id = name // Use name as ID
            self.name = name
            self.emoji = emoji
        }
    }
    
    private func createMood(name: String, intensity: Int, category: String) -> MultiModal.Emotion { // Use MultiModal.Emotion
        return MultiModal.Emotion(name: name, intensity: intensity, category: category)
    }
    
    private func emotionsForCategory(_ category: String) -> [EmotionOption] {
        switch category.lowercased() {
        case "joy":
            return [
                EmotionOption(name: "Happy", emoji: "😊"),
                EmotionOption(name: "Excited", emoji: "🤩"),
                EmotionOption(name: "Content", emoji: "😌")
            ]
        case "sadness":
            return [
                EmotionOption(name: "Sad", emoji: "😢"),
                EmotionOption(name: "Disappointed", emoji: "😞"),
                EmotionOption(name: "Lonely", emoji: "🥺")
            ]
        case "anger":
            return [
                EmotionOption(name: "Angry", emoji: "😠"),
                EmotionOption(name: "Frustrated", emoji: "😤"),
                EmotionOption(name: "Irritated", emoji: "😒")
            ]
        case "fear":
            return [
                EmotionOption(name: "Scared", emoji: "😨"),
                EmotionOption(name: "Anxious", emoji: "😟"),
                EmotionOption(name: "Worried", emoji: "😥")
            ]
        case "surprise":
            return [
                EmotionOption(name: "Surprised", emoji: "😮"),
                EmotionOption(name: "Amazed", emoji: "😲")
            ]
        default:
            return []
        }
    }
}

} // Add missing closing brace for extension MultiModal
