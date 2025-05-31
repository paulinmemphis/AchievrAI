import SwiftUI
import Combine

/// Main view that ties together all narrative engine components with a premium UX
struct NarrativeJourneyView: View {
    // MARK: - Properties
    @State private var selectedTab = 0
    @State private var showNewJournalEntry = false
    @State private var showSettings = false
    @State private var animateButton = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $selectedTab) {
                // Journal Entries Tab
                NavigationStack {
                    JournalEntriesView(showSettings: $showSettings)
                }
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(0)
                
                // Story Map Tab
                NavigationStack {
                    EnhancedStoryMapView()
                        .navigationTitle("Story Map")
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Label("Story Map", systemImage: "map.fill")
                }
                .tag(1)
                
                // Analytics Tab
                NavigationStack {
                    AnalyticsView(currentTabIndex: selectedTab)
                        .navigationTitle("Insights")
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
            }
            .accentColor(themeManager.selectedTheme.accentColor)
            
            // Floating action button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    floatingActionButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 70)
                }
            }
            
            // Modals
            if showNewJournalEntry {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showNewJournalEntry = false
                        }
                    }
                
                NarrativeJournalView()
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
            
            if showSettings {
                settingsView
            }
        }
        .onAppear {
            // Check for onboarding
            checkForOnboarding()
            
            // Check for pending offline requests
            checkForOfflineRequests()
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animateButton = true
                showNewJournalEntry = true
            }
            
            // Reset animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateButton = false
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.selectedTheme.accentColor)
                        .shadow(color: themeManager.selectedTheme.accentColor.opacity(0.3), radius: 10, y: 5)
                )
                .scaleEffect(animateButton ? 0.9 : 1.0)
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showSettings = false
                    }
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showSettings = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                    }
                }
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Theme Settings
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            // Theme Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(ThemeManager.Theme.allCases) { theme in
                                        Button {
                                            themeManager.setTheme(theme)
                                        } label: {
                                            VStack {
                                                Circle()
                                                    .fill(theme.backgroundColor)
                                                    .frame(width: 50, height: 50)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(theme == themeManager.selectedTheme ? 
                                                                    themeManager.selectedTheme.accentColor : Color.clear, 
                                                                    lineWidth: 3)
                                                    )
                                                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                                                
                                                Text(theme.rawValue)
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.selectedTheme.textColor)
                                            }
                                            .frame(width: 70)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 5)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Notifications Settings
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Toggle("Daily Writing Reminder", isOn: .constant(true))
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Toggle("Story Generation Updates", isOn: .constant(true))
                                .foregroundColor(themeManager.selectedTheme.textColor)
                        }
                        .padding(.horizontal)
                        
                        // AI Settings
                        VStack(alignment: .leading, spacing: 15) {
                            Text("AI Preferences")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Picker("Default Genre", selection: .constant("fantasy")) {
                                ForEach(Array(NarrativeEngineConstants.genres.keys), id: \.self) { key in
                                    Text(NarrativeEngineConstants.genres[key] ?? "")
                                        .tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Toggle("Show AI Writing Prompts", isOn: .constant(true))
                                .foregroundColor(themeManager.selectedTheme.textColor)
                        }
                        .padding(.horizontal)
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Data Management")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Button {
                                // Export data
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Your Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            }
                            
                            Button {
                                // Reset data
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.red)
                                    Text("Reset All Data")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // About & Legal
                        VStack(alignment: .leading, spacing: 15) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Button {
                                // Show about
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("About AchievrAI")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            }
                            
                            Button {
                                // Show privacy policy
                            } label: {
                                HStack {
                                    Image(systemName: "lock.shield")
                                    Text("Privacy Policy")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            }
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                                .padding(.top, 5)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .frame(maxWidth: 500)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.selectedTheme.backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 20)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if onboarding should be shown
    private func checkForOnboarding() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if !hasCompletedOnboarding {
            // Show onboarding
        }
    }
    
    /// Checks for pending offline requests
    private func checkForOfflineRequests() {
        let queue = OfflineRequestQueue.shared
        let pendingCount = queue.pendingRequestCount
        
        if pendingCount > 0 {
            // Show notification about pending requests
        }
    }
}

// MARK: - Preview
struct NarrativeJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        NarrativeJourneyView()
            .environmentObject(ThemeManager())
    }
}
