// JournalStore+iCloudSync.swift
// Real-time iCloud sync for JournalStore using NSUbiquitousKeyValueStore
import Foundation

extension JournalStore {
    private static let iCloudKey = "journal_entries_icloud"
    private static let lastSyncTimeKey = "last_sync_time"
    
    // Call this to push changes to iCloud Key-Value store
    func syncToiCloud() {
        syncStatus = .syncing
        do {
            let data = try JSONEncoder().encode(entries)
            NSUbiquitousKeyValueStore.default.set(data, forKey: Self.iCloudKey)
            NSUbiquitousKeyValueStore.default.set(Date().timeIntervalSince1970, forKey: Self.lastSyncTimeKey)
            let success = NSUbiquitousKeyValueStore.default.synchronize()
            
            if success {
                DispatchQueue.main.async { [weak self] in
                    self?.syncStatus = .idle
                    NotificationCenter.default.post(name: .journalEntriesSynced, object: nil)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.syncStatus = .error
                    self?.lastError = "Failed to sync with iCloud"
                    NotificationCenter.default.post(name: .journalEntriesSyncError, object: nil)
                }
            }
        } catch {
            print("[iCloudSync] Failed to encode entries for iCloud: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.syncStatus = .error
                self?.lastError = "Failed to encode data for iCloud: \(error.localizedDescription)"
                NotificationCenter.default.post(name: .journalEntriesSyncError, object: error)
            }
        }
    }
    
    // Call this to pull changes from iCloud Key-Value store
    func loadFromiCloud() {
        syncStatus = .loading
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: Self.iCloudKey) {
            do {
                let loaded = try JSONDecoder().decode([JournalEntry].self, from: data)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Update the published property with the new entries
                    self.updateEntries(loaded)
                    
                    // Also save to local storage for backup
                    DispatchQueue.global(qos: .background).async {
                        _ = self.persistEntries()
                    }
                    self.syncStatus = .idle
                    NotificationCenter.default.post(name: .journalEntriesLoaded, object: nil)
                }
            } catch {
                print("[iCloudSync] Failed to decode entries from iCloud: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.syncStatus = .error
                    self?.lastError = "Failed to decode data from iCloud"
                    NotificationCenter.default.post(name: .journalEntriesLoadError, object: error)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.syncStatus = .idle
            }
        }
    }
    
    // Get last sync time as formatted string
    var lastSyncTimeFormatted: String {
        if let timeInterval = NSUbiquitousKeyValueStore.default.double(forKey: Self.lastSyncTimeKey) as Double?, timeInterval > 0 {
            let date = Date(timeIntervalSince1970: timeInterval)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: date))"
        }
        return "Not yet synced"
    }
    
    // Observe iCloud changes
    func startObservingiCloudSync() {
        // Start the iCloud key-value store
        NSUbiquitousKeyValueStore.default.synchronize()
        
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            
            // Check what changed
            guard let userInfo = notification.userInfo,
                  let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
                return
            }
            
            // Handle different change reasons based on the raw value
            switch reasonForChange {
            case 0: // NSUbiquitousKeyValueStoreServerChange
                self.loadFromiCloud()
            case 1: // NSUbiquitousKeyValueStoreInitialSyncChange
                self.loadFromiCloud()
            case 2: // NSUbiquitousKeyValueStoreQuotaViolationChange
                self.loadFromiCloud()
            default:
                break
            }
        }
    }
}

// Additional notification names for iCloud sync
extension Notification.Name {
    static let journalEntriesSynced = Notification.Name("journalEntriesSynced")
    static let journalEntriesSyncError = Notification.Name("journalEntriesSyncError")
}
