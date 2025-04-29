import Foundation
import Combine

/// Structure representing an offline request to be processed later
struct OfflineRequest: Codable, Identifiable {
    /// Unique identifier for the request
    let id: String
    
    /// Type of request
    let type: RequestType
    
    /// Associated data for the request (keys and values)
    let data: [String: String]
    
    /// When the request was created
    let creationDate: Date
    
    /// Number of times the request has been attempted
    var attemptCount: Int
    
    /// Status of the request
    var status: RequestStatus
    
    /// Error message if any
    var errorMessage: String?
    
    /// Request types supported for offline processing
    enum RequestType: String, Codable {
        case generateStory
        case syncJournalEntry
        case exportData
    }
    
    /// Status of an offline request
    enum RequestStatus: String, Codable {
        case pending
        case inProgress
        case completed
        case failed
    }
    
    init(
        id: String = UUID().uuidString,
        type: RequestType,
        data: [String: String],
        creationDate: Date = Date(),
        attemptCount: Int = 0,
        status: RequestStatus = .pending,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.creationDate = creationDate
        self.attemptCount = attemptCount
        self.status = status
        self.errorMessage = errorMessage
    }
}

public class OfflineRequestQueue: ObservableObject {
    public static let shared = OfflineRequestQueue()
    /// Maximum number of requests to keep in the queue
    private let maxQueueSize = 50
    
    /// Maximum number of retry attempts
    private let maxRetryAttempts = 3
    
    /// Archive URL for persistent storage
    private let queueArchiveURL = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask)[0].appendingPathComponent("offline-requests.json")
    
    /// Queue of pending requests
    @Published private var queue: [OfflineRequest] = []
    
    /// Status of queue processing
    @Published private(set) var isProcessing = false
    
    /// Network monitor to detect connectivity changes
    private let networkMonitor = NetworkMonitor.shared
    
    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    /// Private initializer for singleton
    private init() {
        loadQueue()
        
        // Subscribe to network status changes
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Adds a new request to the queue
    /// - Parameter request: The request to add
    func addRequest(_ request: OfflineRequest) {
        // Check if we're at capacity
        if queue.count >= maxQueueSize {
            // Remove oldest pending request if needed
            if let oldestIndex = queue.firstIndex(where: { $0.status == .pending }) {
                queue.remove(at: oldestIndex)
            } else {
                // Remove oldest failed request if no pending ones
                if let oldestIndex = queue.firstIndex(where: { $0.status == .failed }) {
                    queue.remove(at: oldestIndex)
                } else {
                    // Can't add new request, queue is full with in-progress and completed
                    print("[OfflineRequestQueue] Queue is full, cannot add request")
                    return
                }
            }
        }
        
        // Add the new request
        queue.append(request)
        saveQueue()
        
        // If we're online, process immediately
        if networkMonitor.isConnected {
            processQueue()
        }
    }
    
    /// Gets the number of pending requests
    public var pendingRequestCount: Int {
        queue.filter { $0.status == .pending }.count
    }
    
    /// Returns the IDs of all requests in the queue
    public var requestIds: [String] {
        queue.map { $0.id }
    }
    
    /// Returns the status of a request
    /// - Parameter id: The ID of the request
    /// - Returns: Status as a string, or nil if not found
    public func requestStatus(id: String) -> String? {
        guard let request = queue.first(where: { $0.id == id }) else {
            return nil
        }
        return request.status.rawValue
    }
    
    /// Returns the creation date of a request
    /// - Parameter id: The ID of the request
    /// - Returns: Creation date, or nil if not found
    public func requestCreationDate(id: String) -> Date? {
        guard let request = queue.first(where: { $0.id == id }) else {
            return nil
        }
        return request.creationDate
    }
    
    /// Public method to process all pending requests in the queue
    public func processAllPendingRequests() {
        processQueue()
    }
    
    /// Clears completed requests
    public func clearCompletedRequests() {
        queue.removeAll { $0.status == .completed }
        saveQueue()
    }
    
    /// Retries a failed request
    /// - Parameter id: The ID of the request to retry
    func retryRequest(id: String) {
        if let index = queue.firstIndex(where: { $0.id == id && $0.status == OfflineRequest.RequestStatus.failed }) {
            var request = queue[index]
            request.status = OfflineRequest.RequestStatus.pending
            queue[index] = request
            saveQueue()
            
            if networkMonitor.isConnected {
                processQueue()
            }
        }
    }
    
    /// Removes a request from the queue
    /// - Parameter id: The ID of the request to remove
    public func removeRequest(id: String) {
        queue.removeAll { $0.id == id }
        saveQueue()
    }
    
    /// Processes all pending requests in the queue
    private func processQueue() {
        // Skip if already processing or no connectivity
        guard !isProcessing, networkMonitor.isConnected else {
            return
        }
        
        // Skip if no pending requests
        guard queue.contains(where: { $0.status == .pending }) else {
            return
        }
        
        isProcessing = true
        
        // Process each pending request
        for i in 0..<queue.count {
            guard i < queue.count else { break }
            
            if queue[i].status == .pending {
                processRequest(at: i)
            }
        }
        
        isProcessing = false
    }
    
    /// Processes a specific request in the queue
    /// - Parameter index: The index of the request to process
    private func processRequest(at index: Int) {
        guard index < queue.count else { return }
        
        var request = queue[index]
        
        // Skip if max attempts reached
        if request.attemptCount >= maxRetryAttempts {
            request.status = .failed
            request.errorMessage = "Maximum retry attempts reached"
            queue[index] = request
            saveQueue()
            return
        }
        
        // Mark as in progress
        request.status = .inProgress
        request.attemptCount += 1
        queue[index] = request
        saveQueue()
        
        // Process based on request type
        switch request.type {
        case .generateStory:
            processGenerateStoryRequest(request, at: index)
        case .syncJournalEntry:
            processSyncJournalEntryRequest(request, at: index)
        case .exportData:
            processExportDataRequest(request, at: index)
        }
    }
    
    /// Processes a generate story request
    /// - Parameters:
    ///   - request: The request to process
    ///   - index: The index in the queue
    private func processGenerateStoryRequest(_ request: OfflineRequest, at index: Int) {
        // Implementation would use NarrativeEngineClient to process the request
        // This is a simplified placeholder
        
        guard let entryId = request.data["entryId"],
              let genre = request.data["genre"] else {
            markRequestFailed(at: index, error: "Missing required data")
            return
        }
        
        // Get the persistence manager
        let persistenceManager = StoryPersistenceManager.shared
        
        // Get the entry
        guard let entry = persistenceManager.getJournalEntry(id: entryId) else {
            markRequestFailed(at: index, error: "Journal entry not found")
            return
        }
        
        // Client to process the request
        let client = NarrativeEngineClient()
        
        // Extract metadata then generate chapter
        client.extractMetadata(from: self.getJournalEntryText(entry))
            .flatMap { metadata -> AnyPublisher<ChapterResponse, Error> in
                // Convert MetadataResponse to EntryMetadata
                let entryMetadata = EntryMetadata(
                    sentiment: metadata.sentiment,
                    themes: metadata.themes,
                    entities: metadata.entities,
                    keyPhrases: metadata.keyPhrases
                )
                return client.generateChapter(
                    metadata: entryMetadata,
                    userId: UUID().uuidString, // Should be stored with entry
                    genre: genre,
                    previousArcs: persistenceManager.getPreviousStoryArcs(limit: 3)
                )
            }
            .sink(receiveCompletion: { completion in
                // Handle completion if needed
            }, receiveValue: { [weak self] _ in
                self?.markRequestCompleted(at: index)
            })
            .store(in: &self.cancellables)
    }
    
    private func processSyncJournalEntryRequest(_ request: OfflineRequest, at index: Int) {
        // Placeholder for sync functionality
        // In a real implementation, this would sync with a backend
        
        // For now, just mark as completed
        markRequestCompleted(at: index)
    }
    
    /// Processes an export data request
    /// - Parameters:
    ///   - request: The request to process
    ///   - index: The index in the queue
    private func processExportDataRequest(_ request: OfflineRequest, at index: Int) {
        // Placeholder for export functionality
        // In a real implementation, this would handle exporting data
        
        // For now, just mark as completed
        markRequestCompleted(at: index)
    }
    
    /// Marks a request as completed
    /// - Parameter index: The index of the request in the queue
    private func markRequestCompleted(at index: Int) {
        guard index < queue.count else { return }
        
        var request = queue[index]
        request.status = .completed
        request.errorMessage = nil
        queue[index] = request
        saveQueue()
    }
    
    /// Marks a request as failed
    /// - Parameters:
    ///   - index: The index of the request in the queue
    ///   - error: The error message
    private func markRequestFailed(at index: Int, error: String) {
        guard index < queue.count else { return }
        
        var request = queue[index]
        request.status = OfflineRequest.RequestStatus.failed
        request.errorMessage = error
        queue[index] = request
        saveQueue()
    }
    
    /// Loads the queue from persistent storage
    private func loadQueue() {
        do {
            if FileManager.default.fileExists(atPath: queueArchiveURL.path) {
                let data = try Data(contentsOf: queueArchiveURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                queue = try decoder.decode([OfflineRequest].self, from: data)
            }
        } catch {
            print("[OfflineRequestQueue] Error loading queue: \(error)")
            queue = []
        }
    }
    
    /// Saves the queue to persistent storage
    private func saveQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(queue)
            try data.write(to: queueArchiveURL, options: Data.WritingOptions.atomic)
        } catch {
            print("[OfflineRequestQueue] Error saving queue: \(error)")
        }
    }
    
    private func getJournalEntryText(_ entry: JournalEntry) -> String {
        // Combine all relevant text content from the journal entry
        var textContent = ""
        
        // Add transcription if available
        if let transcription = entry.transcription {
            textContent += transcription + "\n\n"
        }
        
        // Add assignment name and subject
        textContent += "Assignment: \(entry.assignmentName)\n"
        textContent += "Subject: \(entry.subject.rawValue)\n\n"
        
        // Add reflection prompt responses
        for promptResponse in entry.reflectionPrompts {
            textContent += "\(promptResponse.prompt): "
            
            if let selectedOption = promptResponse.selectedOption {
                textContent += selectedOption
            } else if let response = promptResponse.response {
                textContent += response
            } else {
                textContent += "(No response)"
            }
            
            textContent += "\n"
        }
        
        // Add AI summary if available
        if let summary = entry.aiSummary {
            textContent += "\nSummary: \(summary)"
        }
        
        return textContent
    }
}
