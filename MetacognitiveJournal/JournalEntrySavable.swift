// File: JournalEntrySavable.swift
import Foundation
import SwiftUI

/// Protocol for components that can save content as journal entries
protocol JournalEntrySavable {
    /// The journal store to save entries to
    var journalStore: JournalStore { get }
    
    /// Creates a journal entry from the provided content and metadata
    /// - Parameters:
    ///   - content: The main text content of the entry
    ///   - title: The title for the journal entry
    ///   - subject: The academic subject (defaults to .english for story content)
    ///   - emotionalState: The emotional state to associate with the entry
    ///   - summary: A brief summary of the entry content
    ///   - metadata: Optional metadata for the entry including sentiment and themes
    /// - Returns: A fully configured JournalEntry ready to be saved
    func createJournalEntry(
        content: String,
        title: String,
        subject: K12Subject,
        emotionalState: EmotionalState,
        summary: String,
        metadata: EntryMetadata?
    ) -> JournalEntry
    
    /// Shows a confirmation alert after saving
    /// - Parameter entryTitle: The title of the saved entry
    func showSaveConfirmation(for entryTitle: String)
}

// Default implementation of the protocol
extension JournalEntrySavable {
    func createJournalEntry(
        content: String,
        title: String,
        subject: K12Subject = .english,
        emotionalState: EmotionalState = .satisfied,
        summary: String = "Generated story content",
        metadata: EntryMetadata? = nil
    ) -> JournalEntry {
        // Create a prompt response with the content
        let promptResponse = PromptResponse(
            id: UUID(),
            prompt: "Story Content",
            response: content
        )
        
        // Create and return the journal entry
        return JournalEntry(
            id: UUID(),
            assignmentName: title,
            date: Date(),
            subject: subject,
            emotionalState: emotionalState,
            reflectionPrompts: [promptResponse],
            aiSummary: summary,
            metadata: metadata ?? EntryMetadata(
                sentiment: "Neutral",
                themes: [],
                entities: [],
                keyPhrases: []
            )
        )
    }
}
