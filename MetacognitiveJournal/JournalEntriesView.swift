import SwiftUI

/// View for displaying journal entries with proper toolbar implementation
struct JournalEntriesView: View {
    // MARK: - Properties
    @Binding var showSettings: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var guardianManager: GuardianManager // Inject GuardianManager
    // Access the ViewModel that can save multi-modal entries
    // Note: This assumes JournalEntryViewModel is available as an EnvironmentObject or initialized here.
    //       If not, the save logic needs adjustment.
    @StateObject private var journalEntryViewModel = JournalEntryViewModel() // Or get from environment

    @State private var searchText = ""
    @State private var showingNewEntrySheet = false // For Standard/AI Entry
    @State private var showingMultiModalSheet = false // For Multi-Modal Entry
    @State private var showingEntryTypeActionSheet = false // To show the choice
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search entries...", text: $searchText)
                    .font(.system(size: 16))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Journal entries list
            if filteredEntries.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "No journal entries yet" : "No matching entries")
                        .font(.headline)
                    Text(searchText.isEmpty ? "Tap + to create your first entry" : "Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: JournalEntryView(entry: entry)) {
                            JournalRowView(entry: entry)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Your Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Show the action sheet to choose entry type
                    showingEntryTypeActionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Sheet for Standard/AI Entry
        .sheet(isPresented: $showingNewEntrySheet) {
            NavigationView {
                // Assuming AIJournalEntryView is the correct standard view
                AIJournalEntryView()
                    .environmentObject(journalStore)
                    .environmentObject(themeManager)
                    .environmentObject(PsychologicalEnhancementsCoordinator()) // Ensure this is correct context
            }
        }
        // Sheet for Multi-Modal Entry
        .sheet(isPresented: $showingMultiModalSheet) {
            // Safely get active child profile, ID, and journal mode
            if let activeChildProfile = guardianManager.associatedChildren.first,
               let childId = guardianManager.currentGuardian?.childIds.first, // Get the first child ID
               let journalModeRaw = UserDefaults.standard.string(forKey: "childJournalMode"),
               let journalMode = ChildJournalMode(rawValue: journalModeRaw) {
                
                NavigationView {
                    // Instantiate MultiModal.JournalEntryView with actual data
                    MultiModal.JournalEntryView(
                        childId: childId, // Use the fetched ID string
                        readingLevel: activeChildProfile.readingLevel, // Use reading level from profile
                        journalMode: journalMode, // Use journal mode from UserDefaults
                        onSave: { multiModalEntry in
                            // Call the ViewModel to save and process
                            journalEntryViewModel.saveMultiModalEntryAndGenerateStory(multiModalEntry: multiModalEntry)
                            showingMultiModalSheet = false // Dismiss sheet
                        },
                        onCancel: {
                            showingMultiModalSheet = false // Dismiss sheet
                        }
                    )
                    .environmentObject(themeManager) // Pass theme manager
                    // Pass other necessary environment objects
                    // .environmentObject(journalStore) // If needed by the view
                }
            } else {
                // Fallback or error view if data is missing
                // This shouldn't happen in a normal flow after onboarding
                Text("Error: Could not load child profile data.")
            }
        }
        // Action Sheet to choose entry type
        .actionSheet(isPresented: $showingEntryTypeActionSheet) {
            ActionSheet(
                title: Text("Choose Entry Type"),
                message: Text("How would you like to express yourself?"),
                buttons: [
                    .default(Text("Standard Entry")) {
                        showingNewEntrySheet = true // Show the standard/AI sheet
                    },
                    .default(Text("Multi-Modal Entry")) {
                        showingMultiModalSheet = true // Show the multi-modal sheet
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Helper Methods
extension JournalEntriesView {
    // Filter entries based on search text
    private var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return journalStore.entries.sorted(by: { $0.date > $1.date })
        } else {
            return journalStore.entries.filter { entry in
                entry.assignmentName.localizedCaseInsensitiveContains(searchText) ||
                entry.reflectionPrompts.contains(where: { $0.response?.localizedCaseInsensitiveContains(searchText) ?? false })
            }.sorted(by: { $0.date > $1.date })
        }
    }
    
    // Delete entries at specified offsets
    private func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        for entry in entriesToDelete {
            journalStore.deleteEntry(entry.id)
        }
    }
}

#Preview {
    NavigationStack {
        JournalEntriesView(showSettings: .constant(false))
            .environmentObject(ThemeManager())
            .environmentObject(JournalStore())
            .environmentObject(GuardianManager()) // Add GuardianManager for preview
    }
}
