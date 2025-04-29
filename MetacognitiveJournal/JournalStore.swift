// File: JournalStore.swift
import Foundation
import Combine
import SwiftUI
// Explicitly import persistence and iCloud sync extensions
// (not needed in Swift, but ensure files are compiled)
// If using a modular structure, use @objc or public for extension methods
// Otherwise, ensure both files are included in the target
// No import needed, but add comments for clarity

/// Manages the collection of journal entries for the application.
///
/// This class handles loading, saving, adding, updating, and deleting journal entries.
/// It uses `UserDefaults` for persistent storage and conforms to `ObservableObject` to publish changes
/// to SwiftUI views.
class JournalStore: ObservableObject {
    /// The array of journal entries managed by the store. Published to update SwiftUI views upon changes.
    @Published private(set) var entries: [JournalEntry] = []
    
    /// The status of the sync operation. Published to update SwiftUI views upon changes.
    @Published var syncStatus: SyncStatus = .idle
    
    /// The last error that occurred during a sync operation. Published to update SwiftUI views upon changes.
    @Published var lastError: String? = nil
    
    /// Enum representing the different sync statuses.
    enum SyncStatus: String {
        case idle = "Idle"
        case saving = "Saving..."
        case loading = "Loading..."
        case syncing = "Syncing..."
        case error = "Error"
    }

    /// Initializes the JournalStore and loads existing entries from storage.
    init(entries: [JournalEntry] = []) {
        self.entries = entries
        setupNotificationObservers()
        _ = loadEntries()
        startObservingiCloudSync()
    }
    
    /// Sets up notification observers for journal entry save and load events.
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .journalEntriesSaved, object: nil, queue: .main) { [weak self] _ in
            self?.syncStatus = .idle
        }
        
        NotificationCenter.default.addObserver(forName: .journalEntriesSaveError, object: nil, queue: .main) { [weak self] notification in
            self?.syncStatus = .error
            if let error = notification.object as? Error {
                self?.lastError = error.localizedDescription
            }
        }
        
        NotificationCenter.default.addObserver(forName: .journalEntriesLoaded, object: nil, queue: .main) { [weak self] _ in
            self?.syncStatus = .idle
        }
        
        NotificationCenter.default.addObserver(forName: .journalEntriesLoadError, object: nil, queue: .main) { [weak self] _ in
            self?.syncStatus = .error
            self?.lastError = "Failed to load entries"
        }
    }

    /// Adds or updates an entry. New entries are inserted at the front.
    ///
    /// - Parameter entry: The `JournalEntry` to add or update.
    func saveEntry(_ entry: JournalEntry) {
        syncStatus = .saving
        // Remove existing entry with same ID if present
        entries.removeAll { $0.id == entry.id }
        // Insert updated/new entry at the top
        entries.insert(entry, at: 0)
        
        // Use async to prevent UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let success = self.persistEntries()
            
            if success {
                DispatchQueue.main.async {
                    self.syncToiCloud()
                }
            }
        }
    }

    /// Convenience for voice entries with audio and transcription.
    ///
    /// - Parameters:
    ///   - entry: The `JournalEntry` to update.
    ///   - audioURL: The URL of the audio file.
    ///   - transcription: The transcription of the audio.
    func saveEntry(_ entry: JournalEntry, audioURL: URL?, transcription: String) {
        var updated = entry
        updated.audioURL = audioURL
        updated.transcription = transcription
        saveEntry(updated)
    }

    /// Updates an existing entry in place.
    ///
    /// - Parameter entry: The `JournalEntry` containing the updated data and the ID of the entry to update.
    func updateEntry(_ entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            syncStatus = .saving
            entries[idx] = entry
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                let success = self.persistEntries()
                
                DispatchQueue.main.async {
                    if success {
                        self.syncToiCloud()
                    } else {
                        self.syncStatus = .error
                        self.lastError = "Failed to update entry."
                        let error = NSError(domain: "JournalStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to update entry."])
                        ErrorHandler.shared.handle(error, type: { _ in AppError.persistence })
                    }
                }
            }
        }
    }

    /// Deletes an entry by ID.
    ///
    /// - Parameter entryID: The ID of the entry to delete.
    public func deleteEntry(_ entryID: UUID) {
        syncStatus = .saving
        entries.removeAll { $0.id == entryID }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let success = self.persistEntries()
            
            DispatchQueue.main.async {
                if success {
                    self.syncToiCloud()
                } else {
                    self.syncStatus = .error
                    self.lastError = "Failed to delete entry."
                    let error = NSError(domain: "JournalStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to delete entry."])
                    ErrorHandler.shared.handle(error, type: { _ in AppError.persistence })
                }
            }
        }
    }
    
    /// Clears any error message.
    func clearError() {
        lastError = nil
    }
    
    /// Updates entries with a new array (used for sync operations).
    ///
    /// - Parameter newEntries: The new array of `JournalEntry` objects.
    func updateEntries(_ newEntries: [JournalEntry]) {
        self.entries = newEntries
    }

    // MARK: - Preview Support

    /// Static preview instance for SwiftUI previews and testing.
    static let preview: JournalStore = {
        let store = JournalStore()
        let sampleEntries = [
            JournalEntry(
                id: UUID(),
                assignmentName: "Math Homework",
                date: Date(),
                subject: K12Subject.math,
                emotionalState: EmotionalState.neutral,
                reflectionPrompts: [],
                aiSummary: "Good understanding of algebra concepts",
                aiTone: "Positive",
                transcription: nil as String?,
                audioURL: nil as URL?
            ),
            JournalEntry(
                id: UUID(),
                assignmentName: "Science Project",
                date: Date().addingTimeInterval(-86400), // Yesterday
                subject: K12Subject.science,
                emotionalState: EmotionalState.frustrated,
                reflectionPrompts: [],
                aiSummary: "Showed interest in biology concepts",
                aiTone: "Inquisitive",
                transcription: nil as String?,
                audioURL: nil as URL?
            )
        ]
        store.updateEntries(sampleEntries)
        return store
    }()
}
