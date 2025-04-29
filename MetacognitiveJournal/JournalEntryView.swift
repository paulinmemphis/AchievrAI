//
//  JournalEntryView 2.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

// File: JournalEntryView.swift
import SwiftUI
import Speech

/// View for displaying a single journal entry with reflections and AI insights.
struct JournalEntryView: View {
    @ObservedObject var journalStore: JournalStore
    @EnvironmentObject private var themeManager: ThemeManager
    let entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Subject Header
                Text("Subject: \(entry.subject.rawValue.capitalized)")
                    .font(.headline)

                // Reflection Prompts
                ForEach(entry.reflectionPrompts, id: \ .id) { prompt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Show selected option or response if present
                        if let selected = prompt.selectedOption, !selected.isEmpty {
                            Text(selected)
                                .font(.body)
                        } else if let resp = prompt.response, !resp.isEmpty {
                            Text(resp)
                                .font(.body)
                        } else {
                            Text("No response provided.")
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 10)
                }

                // AI-Generated Summary
                if let aiSummary = entry.aiSummary, !aiSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-Generated Summary")
                            .font(.headline)
                            .padding(.top, 10)
                        Text(aiSummary)
                            .font(.body)
                    }
                }

                // AI Tone Nudge
                if let aiTone = entry.aiTone, !aiTone.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tone-Based Nudge")
                            .font(.headline)
                            .padding(.top, 10)
                        Text(aiTone)
                            .font(.body)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                }
            }
            .padding()
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .navigationTitle(Text("Journal Entry"))
    }
}

// MARK: - Preview
struct JournalEntryView_Previews: PreviewProvider {
    static var sampleEntry: JournalEntry = {
        let prompts = [
            PromptResponse(id: UUID(), prompt: "What was challenging?", options: nil, selectedOption: nil, response: "It was hard", isFavorited: nil, rating: nil),
            PromptResponse(id: UUID(), prompt: "What did you learn?", options: nil, selectedOption: nil, response: nil, isFavorited: nil, rating: nil)
        ]
        return JournalEntry(
            id: UUID(),
            assignmentName: "Sample Assignment",
            date: Date(),
            subject: .math,
            emotionalState: .neutral,
            reflectionPrompts: prompts,
            aiSummary: "You did well on your reflection.",
            aiTone: "Neutral",
            transcription: nil,
            audioURL: nil
        )
    }()

    static var previews: some View {
        NavigationView {
            JournalEntryView(journalStore: JournalStore(entries: [sampleEntry]), entry: sampleEntry)
                .environmentObject(ThemeManager())
        }
    }
}
