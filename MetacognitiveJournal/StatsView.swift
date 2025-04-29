//
//  StatsView.swift
//  MetacognitiveJournal
//
//  Updated to ensure ranges use constant literals

import SwiftUI
import Foundation

struct StatsView: View {
    @EnvironmentObject var journalStore: JournalStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(journalStore.entries.prefix(10)) { entry in
                    StatCardView(title: entry.assignmentName) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📚 Subject: \(entry.subject.rawValue)")
                            Text("🙂 Emotion: \(entry.emotionalState.rawValue.capitalized)")
                            Text("🗓️ Date: \(formatDate(entry.date))")
                            if let summary = entry.aiSummary {
                                Text("🧠 AI Insight: \(summary)")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Your Progress")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
