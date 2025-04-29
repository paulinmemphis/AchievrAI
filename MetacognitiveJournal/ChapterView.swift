// ChapterView.swift
import SwiftUI
import Combine
import Foundation
import SwiftUI

/// Displays a generated chapter with appropriate styling and sharing capabilities
struct ChapterView: View, JournalEntrySavable {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager // Access theme
    
    // Flag to show the story map view
    @State private var showStoryMap = false
    @State private var showShareSheet = false
    @State private var viewStartTime = Date()
    @State private var showSaveConfirmation = false
    
    // Analytics manager for tracking engagement
    private let analyticsManager = AnalyticsManager.shared
    
    // Journal store for saving entries
    @EnvironmentObject var journalStore: JournalStore

    // Change to accept StoryNodeViewModel
    let nodeViewModel: StoryNodeViewModel 

    var body: some View {
        NavigationView { // Wrap in NavigationView for title and potentially toolbar items
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Display the main chapter text
                    // We assume the cliffhanger is the last sentence(s) and is included in chapter.text
                    // For highlighting, we can try to separate it or just style the last part if needed.
                    // Simple approach: Display preview text, then repeat cliffhanger preview highlighted.
                    Text(nodeViewModel.chapterPreview) // Use chapterPreview from VM
                        .font(.body)
                        .lineSpacing(5)

                    Divider()

                    // Highlight the cliffhanger
                    VStack(alignment: .leading) {
                         Text("Cliffhanger Preview:") // Label change
                             .font(.headline)
                             .foregroundColor(themeManager.selectedTheme.accentColor) // Use theme color
                         Text(nodeViewModel.chapterPreview) // Use chapterPreview (as cliffhanger isn't directly available)
                            .font(.body.italic().weight(.medium)) // Style the cliffhanger
                            .padding(.top, 2)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground)) // Use system's secondary background
                    .cornerRadius(8)
                    
                    // Personalized feedback for the student
                    VStack(alignment: .leading) {
                        Text("Detected Themes:") // Changed Label
                            .font(.headline)
                        if nodeViewModel.themes.isEmpty { // Use themes from VM
                            Text("No specific themes detected.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            FlowLayout(data: nodeViewModel.themes) { theme in // Use themes from VM
                                Text(theme)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text("Sentiment:")
                            .font(.headline)
                        HStack {
                            nodeViewModel.sentimentColor // Use sentimentColor from VM
                                .frame(width: 15, height: 15)
                                .cornerRadius(7.5)
                            Text(sentimentDescription(nodeViewModel.sentiment)) // Use sentiment from VM
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                    Spacer(minLength: 20) // Push content up
                    
                    // Action buttons row
                    HStack(spacing: 12) {
                        // Button to view the complete story map
                        Button(action: {
                            showStoryMap = true
                        }) {
                            HStack {
                                Image(systemName: "map")
                                    .font(.body)
                                Text("View Story Map")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Button to share the story
                        Button(action: {
                            showShareSheet = true
                            analyticsManager.logEvent(.userInteraction, properties: ["action": "share_button_tapped"])
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body)
                                Text("Share Story")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(themeManager.selectedTheme.accentColor.opacity(0.1))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .cornerRadius(8)
                        }
                        
                        // Button to save as journal entry
                        Button(action: {
                            saveAsJournalEntry()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.body)
                                Text("Save Entry")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(themeManager.selectedTheme.accentColor.opacity(0.1))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .background(themeManager.selectedTheme.backgroundColor) // Use theme background
            .navigationTitle("\(nodeViewModel.title)'s Story Continues...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { // Use primaryAction for the main dismiss button
                    Button("Done") { // Changed from "Continue Writing" to "Done" as it feels more final for a modal
                        // Track view duration before dismissing
                        let viewDuration = Date().timeIntervalSince(viewStartTime)
                        analyticsManager.trackChapterViewed(chapterId: nodeViewModel.chapterId, viewDuration: viewDuration)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let shareText = "Check out my story from Metacognitive Journal!\n\n\(nodeViewModel.chapterPreview)\n\nCliffhanger Preview: \(nodeViewModel.chapterPreview)"
                CustomShareSheet(activityItems: [shareText])
                    .onDisappear {
                        analyticsManager.trackStoryShared(method: "system_share", chapterCount: 1)
                    }
            }
            .alert("Journal Entry Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The story has been saved to your journal entries.")
            }
        }
        .fullScreenCover(isPresented: $showStoryMap) {
            NavigationView {
                StoryMapView()
                    .environmentObject(themeManager)
                    .navigationBarItems(trailing: Button("Done") {
                        showStoryMap = false
                        analyticsManager.logEvent(.userInteraction, properties: ["action": "viewed_story_map"])
                    })
            }
        }
        .onAppear {
            // Track that chapter was viewed
            viewStartTime = Date() // Reset timer when view appears
            analyticsManager.logEvent(.chapterViewed, properties: [
                "chapter_id": nodeViewModel.chapterId,
                // ChapterResponse doesn't have metadata, so we just track the chapter ID
                "student_name": nodeViewModel.title
            ])
        }
    }
    
    /// Provides a textual description of the sentiment score
    private func sentimentDescription(_ score: Double) -> String {
        if score > 0.5 {
            return "Very Positive"
        } else if score > 0.1 {
            return "Positive"
        } else if score < -0.5 {
            return "Very Negative"
        } else if score < -0.1 {
            return "Negative"
        } else {
            return "Neutral"
        }
    }
    
    /// Saves the current chapter as a journal entry
    private func saveAsJournalEntry() {
        // Create metadata from the chapter content
        let metadata = EntryMetadata(
            sentiment: sentimentDescription(nodeViewModel.sentiment),
            themes: nodeViewModel.themes,
            entities: [],
            keyPhrases: []
        )
        
        // Create and save the journal entry using the protocol
        let entry = createJournalEntry(
            content: nodeViewModel.chapterPreview,
            title: "\(nodeViewModel.title)'s Story",
            subject: .english,
            emotionalState: .satisfied,
            summary: "Generated story chapter",
            metadata: metadata
        )
        
        // Save the entry to the journal store
        journalStore.saveEntry(entry)
        analyticsManager.logEvent(.userInteraction, properties: ["action": "save_chapter_as_entry"])
        
        // Show confirmation
        showSaveConfirmation(for: entry.assignmentName)
    }
    
    // Show save confirmation alert
    func showSaveConfirmation(for entryTitle: String) {
        self.showSaveConfirmation = true
    }
}

// MARK: - Preview
struct ChapterView_Previews: PreviewProvider {
    static var sampleNodeVM = StoryNodeViewModel(
        id: "node-1", 
        chapterId: "ch-1",
        title: "Sample Node 1", 
        entryPreview: "Started the day feeling hopeful...", 
        chapterPreview: "Elara felt a surge of excitement as she stepped into the Whispering Woods. The ancient trees seemed to hum with untold secrets.", 
        sentiment: 0.6, 
        themes: ["Exploration", "Mystery"], 
        creationDate: Date(), 
        genre: "Fantasy",
    )

    static var previews: some View {
        ChapterView(nodeViewModel: sampleNodeVM) // Use sample Node VM
            .environmentObject(ThemeManager())
    }
}
