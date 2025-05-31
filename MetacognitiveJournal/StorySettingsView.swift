import SwiftUI

/// A view for configuring narrative story settings
struct StorySettingsView: View {
    // MARK: - Environment
    @EnvironmentObject private var narrativeEngineManager: NarrativeEngineManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var showGenreSelection = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Story Generation Toggle
                Section(header: Text("Story Generation")) {
                    Toggle("Enable Story Generation", isOn: $narrativeEngineManager.isStoryGenerationEnabled)
                        .tint(themeManager.selectedTheme.accentColor)
                    
                    if narrativeEngineManager.isStoryGenerationEnabled {
                        Toggle("Show Writing Prompts", isOn: $narrativeEngineManager.showWritingPrompts)
                            .tint(themeManager.selectedTheme.accentColor)
                    }
                }
                .listRowBackground(themeManager.selectedTheme.cardBackgroundColor)
                
                // Genre Selection
                if narrativeEngineManager.isStoryGenerationEnabled {
                    Section(header: Text("Story Genre")) {
                        HStack {
                            Text("Current Genre")
                            Spacer()
                            Text(narrativeEngineManager.defaultGenre)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showGenreSelection = true
                        }) {
                            Text("Change Genre")
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                        }
                    }
                    .listRowBackground(themeManager.selectedTheme.cardBackgroundColor)
                    
                    // Story Features
                    Section(header: Text("Story Features")) {
                        HStack {
                            Text("Pending Requests")
                            Spacer()
                            Text("\(narrativeEngineManager.pendingRequestCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        if narrativeEngineManager.pendingRequestCount > 0 {
                            Button(action: {
                                narrativeEngineManager.processOfflineRequests()
                            }) {
                                Text("Process Pending Requests")
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                            }
                        }
                    }
                    .listRowBackground(themeManager.selectedTheme.cardBackgroundColor)
                }
                
                // About Section
                Section(header: Text("About Narrative Engine")) {
                    Text("The narrative engine transforms your journal entries into personalized story chapters in your preferred genre.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .listRowBackground(themeManager.selectedTheme.cardBackgroundColor)
            }
            .navigationTitle("Story Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGenreSelection) {
                GenreSelectionView(
                    selectedGenre: $narrativeEngineManager.defaultGenre,
                    isPresented: $showGenreSelection
                )
            }
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
}

// MARK: - Preview
struct StorySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StorySettingsView()
            .environmentObject(NarrativeEngineManager())
            .environmentObject(ThemeManager())
    }
}
