// JournalStore+Persistence.swift
// Local and iCloud persistence for JournalStore
import Foundation
import Combine

extension JournalStore {
    private static let localFileName = "journal_entries.json"
    private static let iCloudContainerID = "iCloud.com.metacognitivejournal.app"
    
    // MARK: - Local File URL
    private static var localFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(localFileName)
    }
    
    // MARK: - iCloud File URL
    private static var iCloudFileURL: URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerID) else { 
            print("[Persistence] iCloud container not available")
            return nil 
        }
        return container.appendingPathComponent(localFileName)
    }
    
    // MARK: - Save (local & iCloud)
    func persistEntries() -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            
            // Save locally with atomic write for data integrity
            try data.write(to: Self.localFileURL, options: .atomic)
            print("[Persistence] Successfully saved entries to local storage: \(Self.localFileURL)")
            
            // Save to iCloud (if available)
            if let iCloudURL = Self.iCloudFileURL {
                try? FileManager.default.createDirectory(at: iCloudURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: iCloudURL, options: .atomic)
                print("[Persistence] Successfully saved entries to iCloud: \(iCloudURL)")
            } else {
                print("[Persistence] iCloud URL not available, skipping iCloud save")
            }
            
            // Notify success
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .journalEntriesSaved, object: nil)
            }
            return true
        } catch {
            print("[Persistence] Failed to save entries: \(error)")
            
            // Notify error on main thread
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .journalEntriesSaveError, object: error)
                ErrorHandler.shared.handle(error, type: { _ in AppError.persistence })
            }
            return false
        }
    }
    
    // MARK: - Load (local, fallback to iCloud)
    func loadEntries() -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // First try loading from local storage
        if FileManager.default.fileExists(atPath: Self.localFileURL.path) {
            do {
                let data = try Data(contentsOf: Self.localFileURL)
                let loaded = try decoder.decode([JournalEntry].self, from: data)
                print("[Persistence] Successfully loaded \(loaded.count) entries from local storage")
                
                DispatchQueue.main.async { [weak self] in
                    self?.updateEntries(loaded)
                    NotificationCenter.default.post(name: .journalEntriesLoaded, object: nil)
                }
                return true
            } catch {
                print("[Persistence] Error loading from local storage: \(error)")
                // Continue to try iCloud as fallback
            }
        } else {
            print("[Persistence] Local file does not exist at: \(Self.localFileURL.path)")
        }
        
        // Try loading from iCloud as fallback
        if let iCloudURL = Self.iCloudFileURL {
            do {
                let data = try Data(contentsOf: iCloudURL)
                let loaded = try decoder.decode([JournalEntry].self, from: data)
                print("[Persistence] Successfully loaded \(loaded.count) entries from iCloud")
                
                DispatchQueue.main.async { [weak self] in
                    self?.updateEntries(loaded)
                    NotificationCenter.default.post(name: .journalEntriesLoaded, object: nil)
                }
                
                // Save to local storage for future use
                try data.write(to: Self.localFileURL, options: .atomic)
                print("[Persistence] Saved iCloud data to local storage for future use")
                return true
            } catch {
                print("[Persistence] Error loading from iCloud: \(error)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .journalEntriesLoadError, object: error)
                    ErrorHandler.shared.handle(error, type: { _ in AppError.persistence })
                }
                return false
            }
        } else {
            print("[Persistence] iCloud URL not available")
        }
        
        // If we get here, both local and iCloud loading failed
        print("[Persistence] Failed to load entries from both local storage and iCloud")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .journalEntriesLoadError, object: nil)
        }
        return false
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let journalEntriesSaved = Notification.Name("journalEntriesSaved")
    static let journalEntriesSaveError = Notification.Name("journalEntriesSaveError")
    static let journalEntriesLoaded = Notification.Name("journalEntriesLoaded")
    static let journalEntriesLoadError = Notification.Name("journalEntriesLoadError")
}
