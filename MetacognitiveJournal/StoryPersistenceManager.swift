// StoryPersistenceManager.swift
import Foundation
import Combine

/// Structure to represent a story arc for narrative continuity
struct StoryArc: Codable, Identifiable {
    var id = UUID()
    let summary: String
    let chapterId: String
    let timestamp: Date
    let themes: [String]
    
    static func createFrom(chapter: ChapterResponse, themes: [String] = []) -> StoryArc {
        // Create a brief summary from the chapter text (first 100 chars)
        let summary = String(chapter.text.prefix(100)) + "..."
        return StoryArc(
            summary: summary,
            chapterId: chapter.chapterId,
            timestamp: Date(),
            themes: themes
        )
    }
}

/// Manages persistence for story nodes and provides methods to save, load, and manage the story data
class StoryPersistenceManager: ObservableObject {
    // Use lazy initialization to prevent startup issues
    static let shared: StoryPersistenceManager = {
        do {
            return try StoryPersistenceManager()
        } catch {
            print("[StoryPersistenceManager] Error creating shared instance: \(error). Using empty manager.")
            // Use a non-throwing initializer as fallback
            do {
                return try StoryPersistenceManager(skipInitialLoad: true)
            } catch {
                fatalError("Failed to create even a basic StoryPersistenceManager: \(error)")
            }
        }
    }()
    
    /// Published collection of story nodes
    @Published private(set) var storyNodes: [StoryNode] = []
    
    /// Published collection of story arcs for narrative continuity
    @Published private(set) var storyArcs: [StoryArc] = []
    
    /// Get the most recent story arcs
    /// - Parameter count: The number of recent arcs to return
    /// - Returns: An array of summaries from the most recent story arcs
    func getRecentStoryArcs(count: Int = 3) -> [String] {
        // Sort arcs by timestamp, newest first
        let sortedArcs = storyArcs.sorted(by: { $0.timestamp > $1.timestamp })
        
        // Take only the requested number of arcs
        let recentArcs = sortedArcs.prefix(count)
        
        // Return just the summaries
        return recentArcs.map { $0.summary }
    }
    
    /// Status of the last operation
    @Published private(set) var status: PersistenceStatus = .idle
    
    /// Error from the last operation, if any
    @Published private(set) var lastError: Error? = nil
    
    /// Path to the story data file
    private let storyArchiveURL = FileManager.default.urls(for: .documentDirectory, 
                                 in: .userDomainMask)[0].appendingPathComponent("story-nodes.json")
    
    /// Path to the story arcs data file
    private let storyArcsArchiveURL = FileManager.default.urls(for: .documentDirectory, 
                                   in: .userDomainMask)[0].appendingPathComponent("story-arcs.json")
    
    /// Status notifications
    private let saveSubject = PassthroughSubject<Void, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    /// Notification name for when story data changes
    static let storyDataDidChangeNotification = Notification.Name("storyDataDidChangeNotification")
    
    /// Defines the persistence status
    enum PersistenceStatus: Equatable {
        case idle
        case loading
        case saving
        case error(String)
        
        static func == (lhs: PersistenceStatus, rhs: PersistenceStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.saving, .saving):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    private init(skipInitialLoad: Bool = false) throws {
        if !skipInitialLoad {
            loadStoryNodes { _ in }
            loadStoryArcs { _ in }
        }
    }
    
    /// Save story nodes to persistent storage
    func saveNodes(_ nodes: [StoryNode]) {
        self.storyNodes = nodes
        status = .saving
        saveSubject.send()
    }
    
    /// Add a new story node
    func addNode(_ node: StoryNode) {
        storyNodes.append(node)
        status = .saving
        saveSubject.send()
    }
    
    /// Update an existing story node
    func updateNode(_ node: StoryNode) {
        if let index = storyNodes.firstIndex(where: { $0.id == node.id }) {
            storyNodes[index] = node
            status = .saving
            saveSubject.send()
        }
    }
    
    /// Delete a story node
    func deleteNode(with id: UUID) {
        storyNodes.removeAll { $0.id == id }
        status = .saving
        saveSubject.send()
    }
    
    /// Get a story node by its ID
    func node(for id: UUID) -> StoryNode? {
        return storyNodes.first { $0.id == id }
    }
    
    /// Get all story nodes for a specific user ID
    func nodesForUser(_ userId: String) -> [StoryNode] {
        // In a multi-user setting, filter nodes by userId
        // For now, return all nodes since we're using a placeholder userId
        return storyNodes
    }
    
    /// Load story nodes from persistent storage
    func loadStoryNodes(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.status = .loading
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                if FileManager.default.fileExists(atPath: self.storyArchiveURL.path) {
                    let data = try Data(contentsOf: self.storyArchiveURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let loadedNodes = try decoder.decode([StoryNode].self, from: data)
                    
                    DispatchQueue.main.async {
                        self.storyNodes = loadedNodes
                        self.status = .idle
                        self.lastError = nil
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.storyNodes = []
                        self.status = .idle
                        completion(.success(()))
                    }
                }
            } catch {
                // Log the error but don't let it crash the app
                print("[StoryPersistenceManager] Error loading story nodes: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.storyNodes = [] // Use empty array on error
                    self.handleError(error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Save a new story arc
    func saveStoryArc(_ arc: StoryArc, completion: @escaping (Result<Void, Error>) -> Void) {
        // Add the arc to the collection
        storyArcs.append(arc)
        status = .saving
        
        // Save the updated arcs collection
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(self.storyArcs)
                try data.write(to: self.storyArcsArchiveURL, options: .atomic)
                
                DispatchQueue.main.async {
                    self.status = .idle
                    self.lastError = nil
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Load story arcs from persistent storage
    func loadStoryArcs(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.status = .loading
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                if FileManager.default.fileExists(atPath: self.storyArcsArchiveURL.path) {
                    let data = try Data(contentsOf: self.storyArcsArchiveURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let loadedArcs = try decoder.decode([StoryArc].self, from: data)
                    
                    DispatchQueue.main.async {
                        self.storyArcs = loadedArcs
                        self.status = .idle
                        self.lastError = nil
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.storyArcs = []
                        self.status = .idle
                        completion(.success(()))
                    }
                }
            } catch {
                // Log the error but don't let it crash the app
                print("[StoryPersistenceManager] Error loading story arcs: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.storyArcs = [] // Use empty array on error
                    self.handleError(error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Create a backup of the story data
    func createBackup() -> URL? {
        let backupFileName = "story-backup-\(Date().timeIntervalSince1970).json"
        let backupURL = FileManager.default.urls(for: .documentDirectory, 
                                              in: .userDomainMask)[0].appendingPathComponent(backupFileName)
        
        do {
            if FileManager.default.fileExists(atPath: storyArchiveURL.path) {
                try FileManager.default.copyItem(at: storyArchiveURL, to: backupURL)
                return backupURL
            }
            return nil
        } catch {
            handleError(error)
            return nil
        }
    }
    
    /// Restore from a backup file
    func restoreFromBackup(at url: URL) {
        status = .loading
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let loadedNodes = try decoder.decode([StoryNode].self, from: data)
                
                // Replace current nodes and save
                DispatchQueue.main.async {
                    self.storyNodes = loadedNodes
                    self.saveSubject.send() // Save to the main storage file
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// Get a list of available backup files
    func availableBackups() -> [URL] {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, 
                                                                    includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.lastPathComponent.starts(with: "story-backup-") }
        } catch {
            handleError(error)
            return []
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Perform the actual save operation
    private func performSave() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(self.storyNodes)
                try data.write(to: self.storyArchiveURL)
                
                DispatchQueue.main.async {
                    self.status = .idle
                    self.lastError = nil
                    
                    // Post notification that story data has changed
                    NotificationCenter.default.post(
                        name: Self.storyDataDidChangeNotification,
                        object: nil
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// Handle and log errors
    private func handleError(_ error: Error) {
        lastError = error
        status = .error(error.localizedDescription)
        print("StoryPersistenceManager error: \(error.localizedDescription)")
    }
    
    // MARK: - Additional Utility Methods
    
    /// Clear all story data (for testing or user requested data deletion)
    func clearAllData() {
        storyNodes = []
        status = .saving
        saveSubject.send()
    }
    
    /// Automatically merge a new node into the story
    func mergeNode(_ node: StoryNode) {
        // Check if we already have this node
        if storyNodes.contains(where: { $0.id == node.id }) {
            updateNode(node)
        } else {
            addNode(node)
        }
    }
    
    /// Get the latest chapter
    func latestChapter() -> StoryNode? {
        return storyNodes.sorted { $0.timestamp > $1.timestamp }.first
    }
}

// MARK: - Helpers for SwiftUI Integration

extension StoryPersistenceManager {
    /// Returns story nodes arranged in a chronological order
    func chronologicalNodes() -> [StoryNode] {
        return storyNodes.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Returns story nodes arranged in a tree structure
    func nodesAsTree() -> [[StoryNode]] {
        var result: [[StoryNode]] = []
        var currentLevel: [StoryNode] = storyNodes.filter { $0.parentId == nil } // Root nodes
        
        while !currentLevel.isEmpty {
            result.append(currentLevel)
            
            // Find all nodes that have parents in the current level
            let currentIds = Set(currentLevel.map { $0.entryId })
            currentLevel = storyNodes.filter { node in
                guard let parentId = node.parentId else { return false }
                return currentIds.contains(parentId)
            }
        }
        
        return result
    }
    
    /// Get nodes filtered by sentiment or search text
    func filteredNodes(sentimentFilter: String? = nil, searchText: String = "") -> [StoryNode] {
        return storyNodes.filter { node in
            var matches = true
            
            // Apply sentiment filter if provided
            if let sentimentFilter = sentimentFilter {
                matches = matches && node.metadata.sentiment.lowercased().contains(sentimentFilter.lowercased())
            }
            
            // Apply search filter if provided
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let themeMatch = node.metadata.themes.contains { $0.lowercased().contains(searchLower) }
                let entityMatch = node.metadata.entities.contains { $0.lowercased().contains(searchLower) }
                let keyPhraseMatch = node.metadata.keyPhrases.contains { $0.lowercased().contains(searchLower) }
                let textMatch = node.chapter.text.lowercased().contains(searchLower)
                
                matches = matches && (themeMatch || entityMatch || keyPhraseMatch || textMatch)
            }
            
            return matches
        }
    }
}
