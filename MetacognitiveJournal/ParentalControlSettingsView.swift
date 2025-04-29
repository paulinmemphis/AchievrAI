// File: ParentalControlSettingsView.swift
import SwiftUI

/// Settings view for enabling/disabling parent mode and resetting the PIN.
struct ParentalControlSettingsView: View {
    @ObservedObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parental Controls")) {
                    Toggle("Enable Parent Mode", isOn: $parentalControlManager.isParentModeEnabled)

                    if parentalControlManager.isParentModeEnabled {
                        NavigationLink("Enter or Reset PIN") {
                            ParentPINEntryView(
                                parentalControlManager: parentalControlManager
                            )
                        }
                    }
                }
            }
            .navigationTitle("Parental Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
