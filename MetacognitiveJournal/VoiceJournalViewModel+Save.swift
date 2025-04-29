//
//  VoiceJournalViewModel+Save.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/21/25.
//


// File: VoiceJournalViewModel+Save.swift
import Foundation
import SwiftUI

// MARK: - JournalEntrySavable Implementation
extension VoiceJournalViewModel: JournalEntrySavable {
    // Access to the journal store - this will be passed directly to methods
    var journalStore: JournalStore {
        // This is a computed property that will be overridden when used
        fatalError("This property should not be accessed directly. Use the journalStore parameter in methods instead.")
    }
    
    // Show confirmation after saving
    func showSaveConfirmation(for entryTitle: String) {
        // Post notification to show alert in the view
        NotificationCenter.default.post(name: Notification.Name("JournalEntrySaved"), object: entryTitle)
    }
    
    // Enhance the existing saveCurrentEntry method with JournalEntrySavable functionality
    // This is called from the original saveCurrentEntry method
    func createJournalEntryWithMetadata() -> JournalEntry {
        // Create metadata from the transcribed text
        let metadata = EntryMetadata(
            sentiment: "Neutral", // This could be enhanced with sentiment analysis
            themes: [], // Could extract themes from content
            entities: [],
            keyPhrases: []
        )
        
        // Create the journal entry using the protocol method
        return createJournalEntry(
            content: transcribedText,
            title: "Voice Journal Entry",
            subject: .english,
            emotionalState: .neutral,
            summary: "Voice recorded journal entry",
            metadata: metadata
        )
    }
    

}
