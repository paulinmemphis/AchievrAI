// File: ContentView.swift
import SwiftUI

// MARK: - Helper Row View
struct PromptFeedbackRowView: View {
    let entry: JournalEntry
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.assignmentName)
                .font(.headline)
            HStack {
                Text(entry.subject.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Main Content View
struct PromptFeedbackView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var parentalControlManager: ParentalControlManager

    @State private var selectedTab = 0
    @State private var showingNewEntrySheet = false
    @State private var showingVoiceSheet = false
    @State private var showingParentSettings = false
    @State private var showingPINEntry = false

    var body: some View {
        TabView(selection: $selectedTab) {
            journalTab
                .tabItem { Label("Journal", systemImage: "book") }
                .tag(0)

            InsightsView()
                .environmentObject(journalStore)
                .environmentObject(analyzer)
                .environmentObject(parentalControlManager)
                .tabItem { Label("Insights", systemImage: "brain") }
                .tag(1)

            SubjectsView()
                .environmentObject(journalStore)
                .tabItem { Label("Subjects", systemImage: "books.vertical") }
                .tag(2)

            StatsView()
                .environmentObject(journalStore)
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(3)

            parentsTab
                .tabItem { Label("Parents", systemImage: "person.2") }
                .tag(4)

            voiceTab
                .tabItem { Label("Voice", systemImage: "mic") }
                .tag(5)
        }
        // MARK: - Sheets
        .sheet(isPresented: $showingNewEntrySheet) {
            NavigationView {
                AIJournalEntryView()
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
                    .environmentObject(parentalControlManager)
                    .navigationBarItems(leading: Button("Cancel") { showingNewEntrySheet = false })
            }
        }
        .sheet(isPresented: $showingVoiceSheet) {
            NavigationView {
                VoiceJournalEntryView(
                    prompts: [
                        "What did you learn today?",
                        "How did you feel?",
                        "What will you improve?"
                    ],
                )
                .environmentObject(journalStore)
                .environmentObject(analyzer)
                .environmentObject(parentalControlManager)
                .navigationBarItems(leading: Button("Cancel") { showingVoiceSheet = false })
            }
        }
        .sheet(isPresented: $showingParentSettings) {
            NavigationView {
                ParentalControlSettingsView(parentalControlManager: parentalControlManager)
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
                    .navigationBarItems(leading: Button("Cancel") { showingParentSettings = false })
            }
        }
        .sheet(isPresented: $showingPINEntry) {
            ParentPINEntryView(
                parentalControlManager: parentalControlManager
            )
            .environmentObject(journalStore)
            .environmentObject(analyzer)
        }
    }

    // MARK: - Extracted Tabs

    private var journalTab: some View {
        NavigationView {
            Group {
                if journalStore.entries.isEmpty {
                    Text("No entries yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(journalStore.entries) { entry in
                            NavigationLink(
                                destination: JournalEntryDetailView(entry: entry)
                                    .environmentObject(parentalControlManager)
                            ) {
                                JournalRowView(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarItems(
                leading: Button { showingParentSettings = true } label: { Image(systemName: "gear") },
                trailing: Button { showingNewEntrySheet = true } label: { Image(systemName: "plus") }
            )
        }
    }

    private var parentsTab: some View {
        Button { showingParentSettings = true } label: {
            Label("Parents", systemImage: "person.2")
        }
    }

    private var voiceTab: some View {
        Button { showingVoiceSheet = true } label: {
            Label("Voice", systemImage: "mic")
        }
    }
}
