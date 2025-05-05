import SwiftUI
import UIKit

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
    
    // Multi-select functionality
    @State private var isSelectionMode = false
    @State private var selectedEntries = Set<UUID>()
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Selection mode indicator - more visible at the top
                if isSelectionMode {
                    HStack {
                        Text("Select entries to delete")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isSelectionMode = false
                                selectedEntries.removeAll()
                            }
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
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
                        ForEach(filteredEntries, id: \.id) { entry in
                            if isSelectionMode {
                                Button(action: {
                                    toggleSelection(entry.id)
                                }) {
                                    HStack {
                                        // Break down complex expressions
                                        let isSelected = selectedEntries.contains(entry.id)
                                        let imageName = isSelected ? "checkmark.circle.fill" : "circle"
                                        let imageColor = isSelected ? themeManager.selectedTheme.accentColor : Color.gray
                                        
                                        Image(systemName: imageName)
                                            .foregroundColor(imageColor)
                                            .animation(.spring(response: 0.2), value: isSelected)
                                        
                                        JournalRowView(entry: entry)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                NavigationLink(destination: JournalEntryView(entry: entry)) {
                                    JournalRowView(entry: entry)
                                }
                                .contextMenu {
                                    Button(action: {
                                        withAnimation {
                                            isSelectionMode = true
                                            selectedEntries.insert(entry.id)
                                        }
                                    }) {
                                        Label("Select", systemImage: "checkmark.circle")
                                    }
                                }
                                .onLongPressGesture {
                                    withAnimation {
                                        isSelectionMode = true
                                        selectedEntries.insert(entry.id)
                                        hapticFeedback()
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(PlainListStyle())
                    // Add padding at the bottom when in selection mode to make room for the delete button
                    .padding(.bottom, isSelectionMode && !selectedEntries.isEmpty ? 60 : 0)
                }
            }
            
            // Show delete button when in selection mode and entries are selected
            if isSelectionMode && !selectedEntries.isEmpty {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        // Break down the ternary expression
                        let entryText = selectedEntries.count > 1 ? "Entries" : "Entry"
                        Text("Delete Selected \(entryText)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: selectedEntries.isEmpty)
            } else if !isSelectionMode && !filteredEntries.isEmpty {
                // Floating action button to enter selection mode
                Button(action: {
                    withAnimation {
                        isSelectionMode = true
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Select Multiple")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(themeManager.selectedTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: isSelectionMode)
            }
        }
        .navigationTitle("Your Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    toggleSelectionMode()
                } label: {
                    Text(isSelectionMode ? "Cancel" : "Select")
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isSelectionMode {
                    Button {
                        // Show the action sheet to choose entry type
                        showingEntryTypeActionSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
        .alert(isPresented: $showingDeleteConfirmation) { () -> Alert in
            // Break down the complex expression in the alert message
            let count = selectedEntries.count
            let itemText = count > 1 ? "entries" : "entry"
            let message = "Are you sure you want to delete \(count) selected \(itemText)? This cannot be undone."
            
            return Alert(
                title: Text("Delete Selected Entries"),
                message: Text(message),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSelectedEntries()
                },
                secondaryButton: .cancel()
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
    
    // Toggle selection mode
    private func toggleSelectionMode() {
        withAnimation {
            isSelectionMode.toggle()
            if !isSelectionMode {
                // Clear selections when exiting selection mode
                selectedEntries.removeAll()
            }
        }
    }
    
    // Toggle selection for a specific entry
    private func toggleSelection(_ entryId: UUID) {
        withAnimation {
            if selectedEntries.contains(entryId) {
                selectedEntries.remove(entryId)
            } else {
                selectedEntries.insert(entryId)
            }
        }
    }
    
    // Delete all selected entries
    private func deleteSelectedEntries() {
        // Create a local copy of the selected entries to avoid modification during iteration
        let entriesToDelete = Array(selectedEntries)
        
        // Use the batch delete method for better performance and reliability
        journalStore.batchDeleteEntries(entriesToDelete)
        
        // Clear selections and exit selection mode
        selectedEntries.removeAll()
        isSelectionMode = false
    }
    
    // Provide haptic feedback for long press gesture
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
