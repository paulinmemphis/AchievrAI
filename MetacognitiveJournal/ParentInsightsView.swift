// File: ParentInsightsView.swift
import SwiftUI

/// View displaying aggregated insights for parents.
struct ParentInsightsView: View {
    @ObservedObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    Text("Total Entries: \(journalStore.entries.count)")
                    Text("Parent Mode Enabled: \(parentalControlManager.isParentModeEnabled ? "Yes" : "No")")
                }

                Section(header: Text("Entries")) {
                    ForEach(journalStore.entries) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.assignmentName)
                                .font(.headline)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Parent Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

