//
//  SettingsView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/21/25.
//

// File: SettingsView.swift
import SwiftUI

/// Central hub for navigating to various application settings.
struct SettingsView: View {
    // Environment objects needed for the views we navigate to
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var appLock: AppLockManager
    
    // State for presenting sheets if needed within SettingsView (e.g., if a sub-view is better as a sheet)
    // @State private var showingSomeSheet = false 
    
    var body: some View {
        NavigationView { // Essential for NavigationLinks to work
            List {
                NavigationLink(destination: ProfileSettingsView().environmentObject(userProfile)) {
                    Label("Profile & Account", systemImage: "person.crop.circle")
                }
                
                NavigationLink(destination: ThemeSettingsView().environmentObject(themeManager)) {
                    Label("Appearance", systemImage: "paintbrush")
                }
                
                NavigationLink(destination: RemindersSettingsView()) {
                    Label("Reminders", systemImage: "bell.badge")
                }
                
                NavigationLink(destination: AppLockSettingsView(appLock: appLock)) {
                    Label("App Lock", systemImage: "lock.shield")
                }
                
                NavigationLink(destination: SecurityPrivacySummaryView()) {
                    Label("Security & Privacy", systemImage: "hand.raised.slash")
                }
                
                // Add other settings links here if needed
                
            }
            .navigationTitle("Settings")
        }
    }
}