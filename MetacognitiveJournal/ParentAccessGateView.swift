// File: ParentAccessGateView.swift
import SwiftUI

struct ParentAccessGateView: View {
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var journalStore: JournalStore // Needed for dashboard
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer // Needed for dashboard

    @State private var showingPINEntrySheet = false
    @State private var showingPINSetupSheet = false

    var body: some View {
        // Use a NavigationView to provide a title bar, even if the dashboard has its own.
        NavigationView {
            Group { // Group allows conditional content within NavigationView
                // Show the dashboard if parent mode is already enabled
                if parentalControlManager.isParentModeEnabled {
                    ParentDashboardView()
                        .environmentObject(journalStore) // Pass necessary environments
                        .environmentObject(analyzer)
                        .environmentObject(parentalControlManager)
                } else {
                    // Placeholder view while deciding/waiting for sheets
                    VStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Parent Zone Locked")
                            .font(.title2)
                        Text("Access requires PIN setup or entry.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Parent Zone") // Set a title for the locked state
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .onAppear(perform: checkAccess) // Check access when the view appears
            .onChange(of: parentalControlManager.isParentModeEnabled) { newValue in
                // If mode becomes enabled (after PIN entry/setup succeeds and ParentPINEntryView dismisses itself),
                // dismiss any lingering sheets just in case.
                // The view will re-render to show ParentDashboardView because the 'if' condition changes.
                if newValue {
                    showingPINEntrySheet = false
                    showingPINSetupSheet = false
                }
            }
            .sheet(isPresented: $showingPINEntrySheet, onDismiss: {
                // Optional: Re-check access if PIN entry is cancelled, though onAppear might handle it.
                // checkAccess()
            }) {
                ParentPINEntryView(parentalControlManager: parentalControlManager)
                    // Pass environments if needed by PIN entry view, though unlikely
            }
            .sheet(isPresented: $showingPINSetupSheet, onDismiss: checkAccess) { // Re-check access after setup attempt
                // Present setup within its own NavigationView for title/buttons if needed
                NavigationView {
                    ParentPINSetupView(parentalControlManager: parentalControlManager)
                }
            }
        }
        .navigationViewStyle(.stack) // Use stack style appropriate for a tab item
     }

     private func checkAccess() {
         // Don't trigger sheets if parent mode is already on
         guard !parentalControlManager.isParentModeEnabled else {
             showingPINEntrySheet = false // Ensure sheets are dismissed if mode is already enabled
             showingPINSetupSheet = false
             return
         }

         // Determine which sheet to show
         if parentalControlManager.isPINSet() {
             // PIN is set, but parent mode isn't enabled yet. Show PIN entry.
             showingPINEntrySheet = true
             showingPINSetupSheet = false // Ensure setup isn't shown
         } else {
             // No PIN set. Show PIN setup.
             showingPINSetupSheet = true
             showingPINEntrySheet = false // Ensure entry isn't shown
         }
     }
}

// MARK: - Preview
struct ParentAccessGateView_Previews: PreviewProvider {
    static var previews: some View {
        // Setup managers outside the ViewBuilder
        let managerWithPIN = ParentalControlManager()
        managerWithPIN.savePIN("1234")
        let lockedManager = MockParentalControlManager(pinSet: true, modeEnabled: false)
        let unlockedManager = MockParentalControlManager(pinSet: true, modeEnabled: true)

        return Group {
            // Preview 1: No PIN Set
            ParentAccessGateView()
                .environmentObject(ParentalControlManager())
                .environmentObject(JournalStore.preview)
                .environmentObject(MetacognitiveAnalyzer())
                .previewDisplayName("No PIN Set")

            // Preview 2: PIN Set, Locked
            ParentAccessGateView()
                .environmentObject(lockedManager)
                .environmentObject(JournalStore.preview)
                .environmentObject(MetacognitiveAnalyzer())
                .previewDisplayName("PIN Set, Locked")

            // Preview 3: PIN Set, Unlocked
            ParentAccessGateView()
                .environmentObject(unlockedManager)
                .environmentObject(JournalStore.preview)
                .environmentObject(MetacognitiveAnalyzer())
                .previewDisplayName("PIN Set, Unlocked")
        }
    }
}

// Mock for previews as Keychain access is tricky in previews
class MockParentalControlManager: ParentalControlManager {
    private var _isPINSet: Bool

    init(pinSet: Bool, modeEnabled: Bool) {
        self._isPINSet = pinSet
        super.init()
        self.isParentModeEnabled = modeEnabled
    }

    override func isPINSet() -> Bool {
        return _isPINSet
    }
    // Override other methods if needed for more complex previews
}
