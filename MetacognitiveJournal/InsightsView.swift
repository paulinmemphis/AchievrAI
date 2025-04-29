//
//  InsightsView 2.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.

// File: InsightsView.swift
import SwiftUI

/// A view displaying AI-generated coach questions and student feedback insights.
struct InsightsView: View {
    @EnvironmentObject private var journalStore: JournalStore
    @StateObject private var coach = AICoach.shared
    @StateObject private var feedbackGen = StudentFeedbackGenerator()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Coach Question")) {
                    if let question = coach.suggestedPrompt {
                        Text(question)
                    } else {
                        Button("Generate Coach Prompt") {
                            coach.generatePrompt(from: journalStore.entries)
                        }
                    }
                }

                Section(header: Text("Feedback")) {
                    if !feedbackGen.feedback.isEmpty {
                        Text(feedbackGen.feedback)
                    } else {
                        Button("Generate Feedback for Latest Entry") {
                            guard let entry = journalStore.entries.first else { return }
                            feedbackGen.generateFeedback(for: entry)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Insights")
        }
    }
}
