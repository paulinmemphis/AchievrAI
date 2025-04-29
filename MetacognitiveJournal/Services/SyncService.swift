import Foundation
import Combine
import SwiftUI

// MARK: - Sync Status
enum SyncStatus: String {
    case idle = "Idle"
    case saving = "Saving..."
    case loading = "Loading..."
    case syncing = "Syncing..."
    case error = "Error"
    case success = "Synced"
    
    var icon: String {
        switch self {
        case .idle: return "cloud"
        case .saving: return "arrow.up.to.line"
        case .loading: return "arrow.down.to.line"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.icloud"
        case .success: return "checkmark.icloud"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .saving, .loading, .syncing: return .blue
        case .error: return .red
        case .success: return .green
        }
    }
}

// MARK: - Sync Service
class SyncService: ObservableObject {
    @Published var status: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var progress: Double = 0.0
    @Published var syncError: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let journalStore: JournalStore
    
    private static let iCloudKey = "journal_entries_icloud"
    private static let lastSyncTimeKey = "last_sync_time"
    private static let iCloudContainerID = "iCloud.com.metacognitivejournal.app"
    
    init(journalStore: JournalStore) {
        self.journalStore = journalStore
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe iCloud changes
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
            .sink { [weak self] notification in
                self?.handleiCloudChanges(notification)
            }
            .store(in: &cancellables)
        
        // Start the iCloud key-value store
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    // MARK: - Public Methods
    
    /// Manually trigger a sync operation
    func sync() {
        status = .syncing
        progress = 0.1
        
        // First check for remote changes
        pullChanges { [weak self] pullResult in
            guard let self = self else { return }
            
            self.progress = 0.5
            
            // Then push local changes
            self.pushChanges { pushResult in
                self.progress = 1.0
                
                switch (pullResult, pushResult) {
                case (.success, .success):
                    self.status = .success
                    self.lastSyncTime = Date()
                    self.saveLastSyncTime()
                    
                    // Reset after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.status = .idle
                    }
                    
                case (.failure(let pullError), _):
                    self.handleSyncError(pullError)
                    
                case (_, .failure(let pushError)):
                    self.handleSyncError(pushError)
                }
            }
        }
    }
    
    /// Get formatted last sync time
    var lastSyncTimeFormatted: String {
        if let lastSync = lastSyncTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: lastSync))"
        } else if let timeInterval = NSUbiquitousKeyValueStore.default.double(forKey: Self.lastSyncTimeKey) as Double?, timeInterval > 0 {
            let date = Date(timeIntervalSince1970: timeInterval)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: date))"
        }
        return "Not yet synced"
    }
    
    // MARK: - Private Methods
    
    private func pullChanges(completion: @escaping (Result<Void, Error>) -> Void) {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: Self.iCloudKey) {
            do {
                let remoteEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
                
                // Merge with local entries (conflict resolution)
                let mergedEntries = mergeEntries(local: journalStore.entries, remote: remoteEntries)
                
                // Update journal store
                DispatchQueue.main.async { [weak self] in
                    self?.journalStore.updateEntries(mergedEntries)
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            // No remote data, nothing to pull
            completion(.success(()))
        }
    }
    
    private func pushChanges(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(journalStore.entries)
            NSUbiquitousKeyValueStore.default.set(data, forKey: Self.iCloudKey)
            let success = NSUbiquitousKeyValueStore.default.synchronize()
            
            if success {
                completion(.success(()))
            } else {
                let error = NSError(domain: "SyncService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to synchronize with iCloud"])
                completion(.failure(error))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func handleiCloudChanges(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // Handle different change reasons
        switch reasonForChange {
        case NSUbiquitousKeyValueStoreServerChange, NSUbiquitousKeyValueStoreInitialSyncChange:
            status = .loading
            pullChanges { [weak self] result in
                if case .failure(let error) = result {
                    self?.handleSyncError(error)
                } else {
                    self?.status = .success
                    // Reset after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.status = .idle
                    }
                }
            }
        default:
            break
        }
    }
    
    private func mergeEntries(local: [JournalEntry], remote: [JournalEntry]) -> [JournalEntry] {
        var mergedEntries = [JournalEntry]()
        var localDict = [UUID: JournalEntry]()
        var remoteDict = [UUID: JournalEntry]()
        
        // Create dictionaries for easier lookup
        for entry in local {
            localDict[entry.id] = entry
        }
        
        for entry in remote {
            remoteDict[entry.id] = entry
        }
        
        // Process all unique IDs
        let allIDs = Set(localDict.keys).union(Set(remoteDict.keys))
        
        for id in allIDs {
            if let localEntry = localDict[id], let remoteEntry = remoteDict[id] {
                // Both local and remote have this entry - use the newer one
                if localEntry.date > remoteEntry.date {
                    mergedEntries.append(localEntry)
                } else {
                    mergedEntries.append(remoteEntry)
                }
            } else if let localEntry = localDict[id] {
                // Only local has this entry
                mergedEntries.append(localEntry)
            } else if let remoteEntry = remoteDict[id] {
                // Only remote has this entry
                mergedEntries.append(remoteEntry)
            }
        }
        
        // Sort by date (newest first)
        return mergedEntries.sorted { $0.date > $1.date }
    }
    
    private func saveLastSyncTime() {
        NSUbiquitousKeyValueStore.default.set(Date().timeIntervalSince1970, forKey: Self.lastSyncTimeKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func handleSyncError(_ error: Error) {
        status = .error
        syncError = error
        ErrorHandler.shared.handle(error, type: { msg in AppError.internalError(message: "Sync error: \(msg)") })
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @ObservedObject var syncService: SyncService
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: syncService.status.icon)
                .foregroundColor(syncService.status.color)
                .font(.system(size: 14))
            
            if showLabel {
                Text(syncService.status.rawValue)
                    .font(.caption)
                    .foregroundColor(syncService.status.color)
            }
            
            if syncService.status == .syncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: syncService.status.color))
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.1))
        )
        .onTapGesture {
            if syncService.status == .idle || syncService.status == .error {
                syncService.sync()
            }
        }
    }
}
