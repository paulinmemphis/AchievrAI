//
//  MoreView.swift
//  MetacognitiveJournal
//
//  Created by Cascade on [Date - please fill in]
//

import SwiftUI

/// A view containing settings, about, and other miscellaneous links.
struct MoreView: View {
    // Access parental controls if needed
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    // Access AppLockManager for SettingsView
    @EnvironmentObject var appLockManager: AppLockManager
    // Access ThemeManager for UI styling
    @EnvironmentObject var themeManager: ThemeManager
    
    // State for presenting settings
    @State private var showingSettings = false
    
    var body: some View {
        // Needs NavigationView for the toolbar item moved from ContentView
        NavigationView {
            List {
                Section("General") {
                    // Link to Settings View (assuming SettingsView exists)
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    // Example: Link to an About page
                    NavigationLink {
                        Text("About Metacognitive Journal\nVersion 1.0") // Replace with an actual AboutView if you have one
                            .navigationTitle("About")
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
                
                Section("Narrative") {
                    // Link to Story Map View
                    NavigationLink {
                        StoryMapView()
                            .environmentObject(themeManager)
                    } label: {
                        Label("Your Story", systemImage: "book.pages")
                    }
                    
                    // Link to Enhanced Story Map View
                    NavigationLink {
                        EnhancedStoryMapView()
                            .environmentObject(themeManager)
                    } label: {
                        Label("Enhanced Story Map", systemImage: "map")
                    }
                    
                    #if DEBUG
                    // Developer testing tool - only visible in DEBUG builds
                    NavigationLink {
                        StoryMapVisualTester()
                    } label: {
                        Label("Story Map Testing", systemImage: "hammer")
                    }
                    #endif
                }
                
                // Add other sections like Help, Feedback, etc. as needed
            }
            .navigationTitle("More") // Title for this tab's NavigationView
            .toolbar {
                 // The toolbar defined in ContentView will attach here 
                 // because this is the root view inside the TabView's NavigationView.
                 // No need to redefine the gear icon here.
             }
            .sheet(isPresented: $showingSettings) {
                // Present SettingsView modally
                // Ensure SettingsView exists and has its own NavigationView if needed
                 NavigationView {
                      SettingsView(appLock: appLockManager)
                         .environmentObject(parentalControlManager) // Pass environment objects if SettingsView needs them
                 }
             }
        }
    }
}

struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
            .environmentObject(ParentalControlManager()) // Provide dummy manager
            .environmentObject(AppLockManager()) // Provide dummy AppLockManager
    }
}
