import SwiftUI
import PencilKit

// Extension for the prompts and media selection step views
extension GuidedMultiModalJournalView {
    
    // MARK: - Prompts Step
    
    /// The prompts view for guided reflection
    var promptsView: some View {
        VStack(spacing: 20) {
            // Prompts header
            Text("Reflection Prompts")
                .font(viewModel.fontForMode(size: 22, weight: .bold))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
            
            // Prompts explanation
            Text("Answer these questions to help you think about your experiences.")
                .font(viewModel.fontForMode(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                .padding(.bottom)
            
            // Prompts list
            ForEach(viewModel.currentPrompts) { prompt in
                promptCard(for: prompt)
            }
        }
    }
    
    /// Individual prompt card
    private func promptCard(for prompt: GuidedMultiModalJournalViewModel.JournalPrompt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prompt text
            Text(prompt.text)
                .font(viewModel.fontForMode(size: 18, weight: .semibold))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
            
            // Hint text
            if !prompt.hint.isEmpty {
                Text(prompt.hint)
                    .font(viewModel.fontForMode(size: 14, weight: .regular))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                    .italic()
            }
            
            // Response text editor
            TextEditor(text: Binding(
                get: { viewModel.promptResponses[prompt.id] ?? "" },
                set: { viewModel.promptResponses[prompt.id] = $0 }
            ))
            .font(viewModel.fontForMode(size: 16))
            .padding(8)
            .frame(minHeight: 100)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Media hint if applicable
            if let mediaTypeHint = prompt.mediaTypeHint {
                HStack {
                    Image(systemName: mediaIconForType(mediaTypeHint))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                    
                    Text("Tip: You can also express this with \(mediaTypeName(mediaTypeHint)) in the next step!")
                        .font(viewModel.fontForMode(size: 14))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.bottom, 8)
    }
    
    // MARK: - Media Selection Step
    
    /// The media selection view
    var mediaSelectionView: some View {
        VStack(spacing: 20) {
            // Media prompt
            Text(viewModel.adaptTextForReadingLevel(viewModel.getMediaPrompt()))
                .font(viewModel.fontForMode(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                .padding()
            
            // Media type selection
            HStack(spacing: 20) {
                mediaTypeButton(.drawing, "Drawing")
                mediaTypeButton(.photo, "Photo")
                mediaTypeButton(.audio, "Voice")
                mediaTypeButton(.text, "Text")
            }
            .padding()
            
            // Current media items display
            if !viewModel.entry.mediaItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Media Items:")
                        .font(viewModel.fontForMode(size: 18, weight: .bold))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.entry.mediaItems) { item in
                                mediaItemPreview(for: item)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 120)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Media editor (if a type is selected)
            if let mediaType = viewModel.selectedMediaType {
                mediaEditorView(for: mediaType)
                    .padding(.top)
            }
        }
    }
    
    /// Button for selecting a media type
    private func mediaTypeButton(_ type: MultiModal.MediaType, _ label: String) -> some View {
        VStack {
            Button(action: {
                viewModel.selectedMediaType = type
                
                // For photo and audio, show the picker sheet
                if type == .photo || type == .audio {
                    self.showingMediaPickerSheet = true
                }
            }) {
                VStack {
                    Image(systemName: mediaIconForType(type))
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        .cornerRadius(12)
                    
                    Text(label)
                        .font(viewModel.fontForMode(size: 14))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                }
            }
        }
    }
    
    /// Preview for a media item
    func mediaItemPreview(for item: MultiModal.MediaItem) -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                Group {
                    switch item.type {
                    case .drawing:
                        if let _ = item.drawingData {
                            Image(systemName: "scribble.variable")
                                .font(.system(size: 30))
                        }
                    case .photo:
                        // Since MultiModal.MediaItem doesn't have imageData property, we need to use fileURL
                        if let fileURL = item.fileURL, let data = try? Data(contentsOf: fileURL), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                        }
                    case .audio:
                        Image(systemName: "waveform")
                            .font(.system(size: 30))
                    case .text:
                        Text(item.textContent?.prefix(10) ?? "")
                            .font(.system(size: 12))
                    default:
                        // Handle any future media types
                        Image(systemName: "questionmark")
                            .font(.system(size: 30))
                    }
                }
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
            }
            
            Text(item.title ?? "Untitled")
                .font(viewModel.fontForMode(size: 12))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
    
    /// Media editor view based on selected type
    @ViewBuilder
    private func mediaEditorView(for type: MultiModal.MediaType) -> some View {
        switch type {
        case .drawing:
            drawingEditor
        case .text:
            textEditor
        case .photo, .audio:
            // These are handled by the media picker sheet
            EmptyView()
        default:
            // Handle any future media types
            EmptyView()
        }
    }
    
    /// Drawing editor view
    private var drawingEditor: some View {
        VStack(spacing: 12) {
            Text("Express yourself through drawing")
                .font(viewModel.fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
            
            // Drawing canvas
            // Use onAppear to initialize drawing data instead of doing it during view rendering
            Group {
                if viewModel.currentDrawingData == nil {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .onAppear {
                            // Initialize drawing data after the view appears
                            Task { @MainActor in
                                // Using Task with MainActor ensures state updates happen outside view update cycle
                                viewModel.currentDrawingData = MultiModal.DrawingData(
                                    strokes: [],
                                    background: nil,
                                    size: CGSize(width: 300, height: 250)
                                )
                            }
                        }
                }
            }
            
            // Create PKCanvasView and PKToolPicker for drawing
            let canvasView = PKCanvasView()
            let toolPicker = PKToolPicker()
            
            VStack(spacing: 12) {
                // Drawing header
                HStack {
                    Text("Express yourself through drawing")
                        .font(viewModel.fontForMode(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Canvas view
                MultiModal.DrawingCanvasView(
                    canvasView: .constant(canvasView),
                    toolPicker: .constant(toolPicker),
                    drawingData: $viewModel.currentDrawingData,
                    onDrawingChanged: {}
                )
                .frame(height: 250)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                
                // Action buttons
                HStack {
                    Button(action: {
                        viewModel.currentDrawingData = nil
                        viewModel.selectedMediaType = nil
                    }) {
                        Text("Cancel")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let drawingData = viewModel.currentDrawingData {
                            viewModel.saveDrawingEntry(drawingData)
                        }
                    }) {
                        Text("Save Drawing")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    /// Text note editor
    private var textEditor: some View {
        VStack(spacing: 12) {
            Text("Add a text note")
                .font(viewModel.fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
            
            TextEditor(text: $viewModel.textContent)
                .font(viewModel.fontForMode(size: 16))
                .padding(8)
                .frame(minHeight: 150)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            HStack {
                Button(action: {
                    viewModel.selectedMediaType = nil
                    viewModel.textContent = ""
                }) {
                    Text("Cancel")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.saveTextEntry(viewModel.textContent)
                }) {
                    Text("Save Note")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Media picker sheet based on selected type
    @ViewBuilder
    var mediaPickerView: some View {
        if let mediaType = viewModel.selectedMediaType {
            switch mediaType {
            case .photo:
                Text("Photo Picker Placeholder")
                    // In a real implementation, this would be a UIImagePickerController
                    // wrapped in a SwiftUI view
            case .audio:
                Text("Audio Recorder Placeholder")
                    // In a real implementation, this would be an audio recorder UI
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
    
    // Helper methods for media icons and names
    private func mediaIconForType(_ type: MultiModal.MediaType) -> String {
        switch type {
        case .drawing: return "pencil.tip"
        case .photo: return "camera"
        case .audio: return "mic"
        case .text: return "text.bubble"
        default: return "questionmark"
        }
    }
    
    private func mediaTypeName(_ type: MultiModal.MediaType) -> String {
        switch type {
        case .drawing: return "drawing"
        case .photo: return "photos"
        case .audio: return "voice recording"
        case .text: return "text notes"
        default: return "other"
        }
    }
}
