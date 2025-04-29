//
//  WeeklyInsightsView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// WeeklyInsightsView.swift
// MetacognitiveJournal

import SwiftUI

struct WeeklyInsightsView: View {
    @Binding var isVisible: Bool
    var summary: String = "You reflected most on stress and academic pressure. Your emotional tone was mostly neutral, with a positive shift mid-week. You revisited the theme of growth mindset 3 times."

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🧠 Weekly Insights")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Here’s a summary of your journal reflections from the past 7 days.")
                    .font(.body)
                    .foregroundColor(.secondary)

                ScrollView {
                    InsightCard(title: "Top Themes", content: "Stress, Academic Pressure, Growth Mindset")
                    InsightCard(title: "Emotional Tone", content: "Mostly neutral. Positive shift noted mid-week.")
                    InsightCard(title: "Reflection Frequency", content: "You made 5 entries. Most active on Tuesday.")
                    InsightCard(title: "Suggested Focus", content: "Try calming prompts or revisit entries tagged 'Stress'.")
                }

                Spacer()

                Button(action: {
                    isVisible = false
                }) {
                    Text("Close")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct InsightCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}