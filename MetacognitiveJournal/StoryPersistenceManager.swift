import Foundation
import Combine

/// Manages persistence for story nodes and provides methods to save, load, and manage the story data
class StoryPersistenceManager: ObservableObject {
    // MARK: - Properties
    
    /// Published collection of story nodes
    @Published private(set) var storyNodes: [StoryNode] = []
    
    /// Published collection of story arcs for narrative continuity
    @Published private(set) var storyArcs: [StoryArc] = []
    
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
    
    // MARK: - Singleton
    
    /// Use lazy initialization to prevent startup issues
    static let shared = StoryPersistenceManager()
    
    /// Static instance specifically for SwiftUI previews
    static var preview: StoryPersistenceManager = {
        let manager = StoryPersistenceManager()
        // Configure for preview (e.g., load mock data or use in-memory store)
        // For now, just return an empty instance to avoid file I/O
        manager.storyNodes = [] // Ensure it starts empty for previews
        manager.storyArcs = []  // Ensure it starts empty for previews
        return manager
    }()
    
    // MARK: - Initialization
    
    init() {
        loadStoryNodes { _ in }
        loadStoryArcs { _ in }
    }
    
    // MARK: - Public Methods
    
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
    
    /// Get the previous story arcs for narrative continuity
    /// - Parameter limit: Maximum number of previous arcs to return
    /// - Returns: Array of previous story arcs as [PreviousArc]
    func getPreviousStoryArcs(limit: Int = 3) -> [PreviousArc] {
        // Sort by timestamp, newest first
        let sortedArcs = storyArcs.sorted(by: { $0.timestamp > $1.timestamp })
        // Take only the requested number of arcs
        let recentArcs = sortedArcs.prefix(limit)
        // Map StoryArc to PreviousArc
        return recentArcs.map { arc in
            PreviousArc(summary: arc.summary, themes: arc.themes, chapterId: arc.chapterId)
        }
    }
    
    /// Get a chapter by its ID
    /// - Parameter id: The ID of the chapter to retrieve
    /// - Returns: The chapter if found, nil otherwise
    func getChapter(id: String) -> Chapter? {
        // Try to load from cache or persistent storage
        if let data = UserDefaults.standard.data(forKey: "chapter_\(id)") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Chapter.self, from: data)
            } catch {
                print("[StoryPersistenceManager] Error decoding chapter: \(error)")
                return nil
            }
        }
        return nil
    }
    
    /// Get a journal entry by its ID
    /// - Parameter id: The ID of the journal entry to retrieve
    /// - Returns: The journal entry if found, nil otherwise
    func getJournalEntry(id: String) -> JournalEntry? {
        // Try to load from cache or persistent storage
        if let data = UserDefaults.standard.data(forKey: "entry_\(id)") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(JournalEntry.self, from: data)
            } catch {
                print("[StoryPersistenceManager] Error decoding journal entry: \(error)")
                return nil
            }
        }
        return nil
    }
    

    
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
        storyNodes.removeAll { $0.id == id.uuidString }
        status = .saving
        saveSubject.send()
    }
    
    /// Get a story node by its ID
    func node(for id: UUID) -> StoryNode? {
        return storyNodes.first { $0.id == id.uuidString }
    }
    
    /// Get all story nodes for a specific user ID
    func nodesForUser(_ userId: String) -> [StoryNode] {
        // In a multi-user setting, filter nodes by userId
        // For now, return all nodes since we're using a placeholder userId
        return storyNodes
    }
    
    /// Get a story arc by its string UUID
    func arc(forUUID id: String) -> StoryArc? {
        return storyArcs.first { $0.id.uuidString == id }
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

// MARK: - Chapter and StoryNode Persistence

extension StoryPersistenceManager {
    /// Save a chapter
    /// - Parameter chapter: The chapter to save
    /// - Returns: Publisher that emits success or error
    func saveChapter(_ chapter: Chapter) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(chapter)
                
                // Save to UserDefaults for now (would use CoreData in production)
                UserDefaults.standard.set(data, forKey: "chapter_\(chapter.id)")
                promise(.success(()))
            } catch {
                print("[StoryPersistenceManager] Error saving chapter: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Save a journal entry
    /// - Parameter entry: The journal entry to save
    /// - Returns: Publisher that emits the saved entry or error
    func saveJournalEntry(_ entry: JournalEntry) -> AnyPublisher<JournalEntry, Error> {
        return Future<JournalEntry, Error> { promise in
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(entry)
                
                // Save to UserDefaults for now (would use CoreData in production)
                UserDefaults.standard.set(data, forKey: "entry_\(entry.id)")
                promise(.success(entry))
            } catch {
                print("[StoryPersistenceManager] Error saving journal entry: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Save a story node
    /// - Parameter node: The story node to save
    /// - Returns: Publisher that emits success or error
    func saveStoryNode(_ node: StoryNode) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            // Add node to the collection
            self.storyNodes.append(node)
            
            // Save to persistent storage
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(self.storyNodes)
                try data.write(to: self.storyArchiveURL, options: .atomic)
                
                // Notify of changes
                NotificationCenter.default.post(name: Self.storyDataDidChangeNotification, object: self)
                promise(.success(()))
            } catch {
                print("[StoryPersistenceManager] Error saving story node: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Gets all story nodes
    /// - Returns: Publisher that emits all story nodes or error
    func getAllStoryNodes() -> AnyPublisher<[StoryNode], Error> {
        return Future<[StoryNode], Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    if FileManager.default.fileExists(atPath: self.storyArchiveURL.path) {
                        let data = try Data(contentsOf: self.storyArchiveURL)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let loadedNodes = try decoder.decode([StoryNode].self, from: data)
                        DispatchQueue.main.async {
                            self.storyNodes = loadedNodes
                            promise(.success(loadedNodes))
                        }
                    } else {
                        DispatchQueue.main.async {
                            promise(.success([]))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("[StoryPersistenceManager] Error loading story nodes: \(error)")
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
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
                // StoryNode doesn't have a direct chapter property, so we'll just check other metadata
                let sentimentMatch = node.metadata.sentiment.lowercased().contains(searchLower)
                
                matches = matches && (themeMatch || entityMatch || keyPhraseMatch || sentimentMatch)
            }
            
            return matches
        }
    }
}
