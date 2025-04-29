// ChapterView.swift
import SwiftUI
import Combine

/// Displays a generated chapter with appropriate styling and sharing capabilities
struct ChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager // Access theme
    
    // Flag to show the story map view
    @State private var showStoryMap = false
    @State private var showShareSheet = false
    @State private var viewStartTime = Date()
    
    // Analytics manager for tracking engagement
    private let analyticsManager = AnalyticsManager.shared

    let chapter: ChapterResponse

    var body: some View {
        NavigationView { // Wrap in NavigationView for title and potentially toolbar items
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Display the main chapter text
                    // We assume the cliffhanger is the last sentence(s) and is included in chapter.text
                    // For highlighting, we can try to separate it or just style the last part if needed.
                    // Simple approach: Display full text, then repeat cliffhanger highlighted.
                    Text(chapter.text)
                        .font(.body)
                        .lineSpacing(5)

                    Divider()

                    // Highlight the cliffhanger
                    VStack(alignment: .leading) {
                         Text("Cliffhanger:")
                             .font(.headline)
                             .foregroundColor(themeManager.selectedTheme.accentColor) // Use theme color
                         Text(chapter.cliffhanger)
                            .font(.body.italic().weight(.medium)) // Style the cliffhanger
                            .padding(.top, 2)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground)) // Use system's secondary background
                    .cornerRadius(8)
                    
                    // Personalized feedback for the student
                    VStack(alignment: .leading) {
                        Text("Feedback:")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                        Text(chapter.feedback)
                            .font(.body.weight(.medium))
                            .padding(.top, 2)
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
                    }
                    .padding(.top)
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .background(themeManager.selectedTheme.backgroundColor) // Use theme background
            .navigationTitle("\(chapter.studentName)'s Story Continues...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { // Use primaryAction for the main dismiss button
                    Button("Done") { // Changed from "Continue Writing" to "Done" as it feels more final for a modal
                        // Track view duration before dismissing
                        let viewDuration = Date().timeIntervalSince(viewStartTime)
                        analyticsManager.trackChapterViewed(chapterId: chapter.chapterId, viewDuration: viewDuration)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let shareText = "Check out my story from Metacognitive Journal!\n\n\(chapter.text)\n\nCliffhanger: \(chapter.cliffhanger)"
                CustomShareSheet(activityItems: [shareText])
                    .onDisappear {
                        analyticsManager.trackStoryShared(method: "system_share", chapterCount: 1)
                    }
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
                "chapter_id": chapter.chapterId,
                // ChapterResponse doesn't have metadata, so we just track the chapter ID
                "student_name": chapter.studentName
            ])
        }
    }
}

// MARK: - Preview
struct ChapterView_Previews: PreviewProvider {
    static var sampleChapter = ChapterResponse(
        chapterId: "preview-ch-1",
        text: "The forest floor crunched underfoot as Elara ventured deeper, the ancient map clutched in her hand. Strange symbols glowed faintly on the parchment, reacting to the proximity of the hidden grove. Suddenly, a twig snapped behind her, sharp and distinct in the unnerving silence. She whirled around, hand instinctively reaching for the dagger she didn't have, heart pounding against her ribs.",
        cliffhanger: "She whirled around, hand instinctively reaching for the dagger she didn't have, heart pounding against her ribs.",
        studentName: "Student",
        feedback: "Student, your journal entry has been transformed into the next chapter of your personal story adventure!"
    )

    static var previews: some View {
        ChapterView(chapter: sampleChapter)
            .environmentObject(ThemeManager()) // Provide theme for preview
    }
}
