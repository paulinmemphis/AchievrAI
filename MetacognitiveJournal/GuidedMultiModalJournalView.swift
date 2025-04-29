import SwiftUI
import Combine
import PencilKit
import AVFoundation

/// A guided journal entry view that combines multimodal expression with age-appropriate prompts
struct GuidedMultiModalJournalView: View {
    // MARK: - Environment
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var analyzer: MetacognitiveAnalyzer
    
    // MARK: - View Model
    @StateObject var viewModel: GuidedMultiModalJournalViewModel
    
    // MARK: - State
    @State var showingMediaPickerSheet = false
    @State var showingEmotionPickerSheet = false
    @State var showingConfirmationDialog = false
    
    // MARK: - Initialization
    init(childId: String, readingLevel: ReadingLevel, journalMode: ChildJournalMode, 
         onSave: @escaping (MultiModal.JournalEntry) -> Void, 
         onCancel: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: GuidedMultiModalJournalViewModel(
            childId: childId,
            readingLevel: readingLevel,
            journalMode: journalMode,
            onSave: onSave,
            onCancel: onCancel
        ))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            StepProgressView(currentStep: viewModel.currentStep)
                .padding(.top)
            
            // Main content area
            ScrollView {
                VStack(spacing: 20) {
                    // Title field
                    titleSection
                    
                    // Current step content
                    currentStepContent
                }
                .padding()
            }
            
            // Navigation buttons
            navigationButtons
        }
        .background(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
        .sheet(isPresented: $showingEmotionPickerSheet) {
            EmotionPickerView(currentMode: viewModel.journalMode, selectedMood: $viewModel.selectedEmotion)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingMediaPickerSheet) {
            mediaPickerView
        }
        .confirmationDialog(
            "Are you sure you want to cancel?",
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Yes, Cancel", role: .destructive) {
                viewModel.cancelEntry()
            }
            Button("Continue Editing", role: .cancel) {
                showingConfirmationDialog = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    showingConfirmationDialog = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.saveEntryAndDismiss()
                }
            }
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Content Views
    
    /// The title input section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(viewModel.fontForMode(size: 16, weight: .bold))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
            
            TextField("Give your entry a title", text: $viewModel.entryTitle)
                .font(viewModel.fontForMode(size: 18))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    /// The content for the current step
    @ViewBuilder
    private var currentStepContent: some View {
        switch viewModel.currentStep {
        case .introduction:
            introductionView
        case .emotion:
            emotionView
        case .prompts:
            promptsView
        case .media:
            mediaSelectionView
        case .insights:
            insightsView
        case .review:
            reviewView
        }
    }
    
    /// The navigation buttons for moving between steps
    private var navigationButtons: some View {
        HStack {
            // Back button
            if viewModel.currentStep != .introduction {
                Button(action: {
                    viewModel.moveToPreviousStep()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next/Finish button
            Button(action: {
                if viewModel.currentStep == .review {
                    viewModel.saveEntryAndDismiss()
                } else {
                    viewModel.moveToNextStep()
                }
            }) {
                HStack {
                    Text(viewModel.currentStep == .review ? "Finish" : "Next")
                    Image(systemName: "chevron.right")
                }
                .padding()
                .foregroundColor(.white)
                .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
