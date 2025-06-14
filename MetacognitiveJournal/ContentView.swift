/// The main container view for the application, setting up the tab-based navigation.
import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("hasSeenTutorialOverlay") private var hasSeenTutorialOverlay: Bool = false
    @State private var showTutorialOverlay: Bool = false

    @EnvironmentObject var journalStore: JournalStore
    @ObservedObject private var errorHandler = ErrorHandler.shared
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var appLockManager: AppLockManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var metacognitiveAnalyzer: MetacognitiveAnalyzer
    @EnvironmentObject var psychologicalEnhancementsCoordinator: PsychologicalEnhancementsCoordinator
    @EnvironmentObject var aiNudgeManager: AINudgeManager
    
    @EnvironmentObject var storyManager: StoryManager
    
    // MARK: - State
    @State private var selectedTab: Int = 0
    @State private var showingNewEntrySheet = false
    @State private var showingSettingsSheet = false
    @State private var showingOnboarding = false
    
    // MARK: - Notifications
    private let tabChangeNotification = NotificationCenter.default.publisher(for: Notification.Name("TabChangeNotification"))
    
    // Helper functions for MultiModal entry conversion
    func convertEmotionToEmotionalState(_ emotion: MultiModal.Emotion?) -> EmotionalState {
        guard let emotion = emotion else { return .neutral }
        
        let category = emotion.category.lowercased()
        if category == "joy" || category == "happiness" || category == "excited" {
            return .confident
        } else if category == "sadness" || category == "disappointed" {
            return .frustrated
        } else if category == "anger" || category == "frustrated" {
            return .frustrated
        } else if category == "fear" || category == "anxious" || category == "nervous" {
            return .overwhelmed
        } else if category == "surprise" || category == "curious" {
            return .curious
        } else {
            return .neutral
        }
    }
    
    func extractPromptResponses(from entry: MultiModal.JournalEntry) -> [PromptResponse] {
        var responses: [PromptResponse] = []
        
        // Extract text content from media items as prompt responses
        for mediaItem in entry.mediaItems {
            if let textContent = mediaItem.textContent, !textContent.isEmpty {
                let promptResponse = PromptResponse(
                    id: UUID(),
                    prompt: "Journal Entry",
                    response: textContent
                )
                responses.append(promptResponse)
            }
        }
        
        // If no text content was found, create a default prompt response
        if responses.isEmpty {
            let promptResponse = PromptResponse(
                id: UUID(),
                prompt: "Journal Entry",
                response: entry.title
            )
            responses.append(promptResponse)
        }
        
        return responses
    }
    
    // MARK: - Computed Properties
    private var journalTab: some View {
        NavigationView {
            Group {
                if journalStore.entries.isEmpty {
                    Text("No entries yet. Tap + to add one.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(themeManager.selectedTheme.backgroundColor)
                } else {
                    List {
                        ForEach(journalStore.entries.sorted(by: { $0.date > $1.date })) { entry in
                            NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                                JournalRowView(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntry)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .background(themeManager.selectedTheme.backgroundColor)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewEntrySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private var moreTab: some View {
        NavigationView {
            MoreView()
                .environmentObject(appLockManager)
                .environmentObject(parentalControlManager)
                .navigationTitle("More")
        }
    }
    
    // MARK: - Body
    var body: some View {
        // Break up the complex expression into simpler parts
        let isLockScreenActive = appLockManager.showLockScreen
        let isLoginRequired = parentalControlManager.isLoginRequired()
        let shouldShowLockScreen = isLockScreenActive && isLoginRequired
        
        ZStack {
            if shouldShowLockScreen {
                AppLockView(appLock: appLockManager)
            } else {
                // Main TabView structure with explicit tabs (no swipe)
                TabView(selection: $selectedTab) {
                    // Progress tab (Analytics & Rewards) - First tab
                    NavigationView {
                        AnalyticsView(currentTabIndex: selectedTab) 
                            .environmentObject(journalStore)
                            // Removed navigationTitle to eliminate the "Progress" heading
                    }
                    .tabItem { 
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                    
                    // Journal tab - Second tab
                    journalTab
                    .tabItem { 
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(1)
                    
                    // Story tab - Third tab
                    // Replaced StoryGenerationView with MyStoryView to display generated chapters
                    MyStoryView()
                        // MyStoryView uses storyManager and themeManager from the environment
                    .tabItem { 
                        Label("Story", systemImage: "book.pages.fill")
                    }
                    .tag(2)
                    
                    // More tab - Fourth tab
                    moreTab
                    .tabItem { 
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(3)
                }
                // Use standard tab style instead of page style to disable swipe navigation
                .tabViewStyle(DefaultTabViewStyle())
                // Disable swipe gestures between tabs
                .gesture(DragGesture().onChanged { _ in })
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // No need to handle parent tab navigation here anymore as it's now in the More tab
            // We'll handle that in the MoreView instead
        }
        .onReceive(tabChangeNotification) { notification in
            // Handle tab change notification from PageTabNavigation
            if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
                selectedTab = tabIndex
            }
        }
        .accentColor(themeManager.selectedTheme.accentColor)
        .overlay(alignment: .top) { // Use overlay for error banner
            // Error banner if needed
            if let error = errorHandler.currentError {
                createErrorBannerView(error.localizedDescription) { errorHandler.currentError = nil }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: errorHandler.currentError)
                    .zIndex(100)
                    .padding(.top, 4) // Adjust padding as needed
            }
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            // Present the guided multi-modal journal entry view
            GuidedMultiModalJournalView(
                childId: UUID().uuidString, // Use a new UUID as the child ID
                readingLevel: .grade3to4, // Default reading level for grades 3-4
                journalMode: .middleChildhood, // Default journal mode for ages 9-12
                onSave: { multiModalEntry in
                    // Convert MultiModal entry to standard entry
                    let standardEntry = multiModalEntry.adaptToStandardEntry()
                    // Ensure the standardEntry has an ID before saving and generating chapter
                    // If adaptToStandardEntry() doesn't assign one, ensure it's assigned here or in JournalStore.saveEntry
                    // For now, assuming standardEntry.id is valid after adaptation.
                    
                    // Generate and add story chapter
                    // We need to ensure standardEntry.text is the correct field for main content.
                    // If 'standardEntry.text' is not the primary content, adjust accordingly.
                    // Example: let mainText = standardEntry.promptResponses.first?.response ?? standardEntry.title
                    storyManager.generateAndAddChapter(forJournalEntryText: standardEntry.content, entryId: standardEntry.id.uuidString, genre: .sliceOfLife)
                    journalStore.saveEntry(standardEntry)
                    showingNewEntrySheet = false
                },
                onCancel: {
                    showingNewEntrySheet = false
                }
            )
            .environmentObject(themeManager)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates an error banner view.
    private func createErrorBannerView(_ message: String, onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            let sortedEntries = journalStore.entries.sorted(by: { $0.date > $1.date })
            let entry = sortedEntries[index]
            journalStore.deleteEntry(entry.id)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(JournalStore())
            .environmentObject(ThemeManager())
            .environmentObject(MetacognitiveAnalyzer())
            .environmentObject(ParentalControlManager())
            .environmentObject(UserProfile())
            .environmentObject(AppLockManager())
            .environmentObject(PsychologicalEnhancementsCoordinator())
            .environmentObject(AINudgeManager())
    }
}
