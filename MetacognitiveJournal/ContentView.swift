/// The main container view for the application, setting up the tab-based navigation.
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var journalStore: JournalStore
    // No custom initializer needed - the environment objects will be injected by SwiftUI
    // ... other properties ...
    @ObservedObject private var errorHandler = ErrorHandler.shared
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var appLockManager: AppLockManager

    /// Controls the presentation of the new entry sheet.
    @State private var showingNewEntrySheet = false
    
    /// Controls the presentation of the voice sheet.
    @State private var showingVoiceSheet = false
    
    /// Controls the presentation of the parental control settings sheet.
    @State private var showingParentSettings = false
    
    /// Controls the presentation of the PIN entry sheet.
    @State private var showingPINEntry = false
    
    /// Controls the presentation of the insights sheet.
    @State private var shouldShowInsightsSheet = false
    
    /// Controls the presentation of the settings sheet.
    @State private var showingSettingsSheet = false
    
    /// Controls the presentation of the confetti view.
    @State private var showConfetti = false
    
    /// Controls the presentation of the story map view.
    @State private var showingStoryMapView = false
    
    /// The selected tab index.
    @State private var selectedTab = 0
    
    /// The AI Nudge Manager for proactive nudges.
    @StateObject private var aiNudgeManager = AINudgeManager.shared
    
    /// The encouragement card view.
    private var encouragementCard: some View {
        let prompt = aiNudgeManager.latestNudge ?? "Keep going! Every step counts."
        return HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Encouragement")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(prompt)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.25), Color.white]), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
        .shadow(color: Color.yellow.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    /// The journal tab view.
    private var journalTab: some View {
        NavigationView {
            ZStack {
                themeManager.selectedTheme.backgroundColor // Apply the selected theme's solid color
                    .ignoresSafeArea()
                if journalStore.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No entries yet. Tap + to add your first entry.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 32) {
                        // Show encouragement card only in journal tab
                        if let _ = aiNudgeManager.latestNudge {
                            encouragementCard
                        }
                        
                        // Story Journey Card - Only show if the journal is ready and accessible
                        // This card will only appear after initialization is complete
                        if journalStore.entries.count > 0 || journalStore.syncStatus != .loading {
                            Button(action: {
                                showingStoryMapView = true
                            }) {
                            HStack(spacing: 12) {
                                Image(systemName: "book.pages.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading) {
                                    Text("Your Story Journey")
                                        .font(.headline)
                                    Text("View chapters created from your journal entries")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Show sync status
                        if journalStore.syncStatus != .idle {
                            syncStatusView
                                .transition(.slide)
                                .animation(.easeInOut, value: journalStore.syncStatus)
                        }
                        
                        if showConfetti {
                            ConfettiView()
                                .transition(.opacity)
                                .zIndex(1)
                        }
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(journalStore.entries) { entry in
                                    NavigationLink(destination: JournalEntryDetailView(entry: entry)
                                        .environmentObject(parentalControlManager)) {
                                        JournalRowView(entry: entry)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding([.top, .horizontal])
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewEntrySheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            NavigationView {
                NewEntryView()
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
            }
            .environmentObject(themeManager)
        }
    }
    
    /// The analytics tab view.
    private var analyticsTab: some View { AnalyticsView() }
    
    /// The search tab view.
    private var searchTab: some View { SearchView() }
    
    /// The gamification tab view.
    private var gamificationTab: some View { GamificationView() }
    
    /// The voice journal tab view.
    private var voiceJournalTab: some View { VoiceJournalView() }
    
    /// The help tab view.
    private var helpTab: some View { HelpView() }
    
    /// The parents tab view.
    private var parentsTab: some View { ParentAccessGateView() }
    
    /// The more tab view.
    private var moreTab: some View {
        NavigationView {
            MoreView()
                .environmentObject(appLockManager) // Inject AppLockManager
                .environmentObject(parentalControlManager)
                .environmentObject(userProfile)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
        }
    }
    
    /// The main body of the ContentView.
    var body: some View {
        ZStack(alignment: .top) {
            if errorHandler.showingError, let appError = errorHandler.currentError {
                createErrorBannerView(appError.message) { errorHandler.currentError = nil }
                    .transition(.move(edge: .top))
                    .zIndex(1)
            }
            TabView(selection: $selectedTab) {
                journalTab.tabItem { Image(systemName: "book.fill").foregroundColor(.primary); Text("Journal").foregroundColor(.primary) }.tag(0)
                AnalyticsView().tabItem { Image(systemName: "chart.bar.xaxis").foregroundColor(.primary); Text("Analytics").foregroundColor(.primary) }.tag(1)
                SearchView().tabItem { Image(systemName: "magnifyingglass").foregroundColor(.primary); Text("Search").foregroundColor(.primary) }.tag(2)
                GamificationView().tabItem { Image(systemName: "star.circle.fill").foregroundColor(.primary); Text("Progress").foregroundColor(.primary) }.tag(3)
                VoiceJournalView().tabItem { Image(systemName: "mic.circle.fill").foregroundColor(.primary); Text("Voice").foregroundColor(.primary) }.tag(4)
                HelpView().tabItem { Image(systemName: "questionmark.circle.fill").foregroundColor(.primary); Text("Help").foregroundColor(.primary) }.tag(5)
                ParentAccessGateView().tabItem { Image(systemName: "person.2.fill").foregroundColor(.primary); Text("Parents").foregroundColor(.primary) }.tag(6)
                moreTab.tabItem { Image(systemName: "ellipsis.circle.fill").foregroundColor(.primary); Text("More").foregroundColor(.primary) }.tag(7)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // If the user was previously on the parent tab (index 6) and navigated away,
                // disable parent mode.
                if oldValue == 6 && newValue != 6 {
                    parentalControlManager.disableParentMode()
                }
            }
            .accentColor(themeManager.selectedTheme.accentColor)
            
            // Only show sync status indicator when not on journal tab (to avoid duplication)
            if selectedTab != 0, journalStore.syncStatus != .idle {
                syncStatusView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: journalStore.syncStatus)
            }
            
            // Error banner if needed
            if let error = journalStore.lastError {
                createErrorBannerView(error) { journalStore.lastError = nil }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: journalStore.lastError)
                    .zIndex(100)
            }
        }
        .onChange(of: journalStore.entries) { newValue in 
            aiNudgeManager.scheduleProactiveNudge(for: journalStore.entries)
        }
        .fullScreenCover(isPresented: $showingStoryMapView) {
            NavigationView {
                EnhancedStoryMapView()
                    .environmentObject(themeManager)
                    .navigationBarItems(trailing: Button("Done") {
                        showingStoryMapView = false
                    })
            }
        }
        .sheet(isPresented: $showingVoiceSheet) {
            VoiceJournalView().environmentObject(journalStore)
        }
        .sheet(isPresented: $showingParentSettings) {
            NavigationView {
                ParentalControlSettingsView(parentalControlManager: parentalControlManager)
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
                    .navigationBarItems(leading: Button("Cancel") { showingParentSettings = false })
            }
        }
        .sheet(isPresented: $showingPINEntry) {
            ParentPINEntryView(parentalControlManager: parentalControlManager)
                .environmentObject(journalStore)
                .environmentObject(analyzer)
        }
        .sheet(isPresented: $shouldShowInsightsSheet, onDismiss: {
        }) {
            ParentInsightsView(parentalControlManager: parentalControlManager)
                .environmentObject(journalStore)
                .environmentObject(analyzer)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(appLock: appLockManager)
                .environmentObject(userProfile)
                .environmentObject(themeManager)
                // appLock is observed, no need to pass typically unless specifically required by SettingsView init
        }
        .onChange(of: parentalControlManager.isParentModeEnabled) { newValue in
            // When parent mode is enabled (PIN entered correctly), trigger the insights sheet
            if newValue {
                shouldShowInsightsSheet = true
            }
        }
    }
    
    /// The sync status view.
    var syncStatusView: some View {
        HStack(spacing: 8) {
            if journalStore.syncStatus == .saving || journalStore.syncStatus == .syncing || journalStore.syncStatus == .loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(0.8)
            } else if journalStore.syncStatus == .error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Text(journalStore.syncStatus.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(journalStore.lastSyncTimeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

/// Creates an error banner view with a given message and a dismiss action.
func createErrorBannerView(_ message: String, onDismiss: @escaping () -> Void) -> some View {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.white)
        
        Text(message)
            .foregroundColor(.white)
            .font(.subheadline)
            .lineLimit(2)
            .padding(.trailing, 8)
        Spacer()
        Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white.opacity(0.7))
        }
    }
    .padding(10)
    .background(Color.red.opacity(0.92))
    .cornerRadius(10)
    .padding([.top, .horizontal], 16)
    .shadow(radius: 4)
}
