// NarrativeAPIService.swift
import Foundation
import Combine // Import Combine framework

// Custom Error for API Service
enum APIServiceError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API endpoint URL is invalid."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Received an invalid response from the server (Status Code: \(statusCode))."
        case .decodingError(let error):
            return "Failed to decode the server response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode the request body: \(error.localizedDescription)"
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}


/// Generic cache entry with expiration
class CacheEntry<T> {
    let value: T
    let timestamp: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > ttl
    }
    
    init(value: T, timestamp: Date = Date(), ttl: TimeInterval = 86400) {
        self.value = value
        self.timestamp = timestamp
        self.ttl = ttl
    }
}

/// Service for interacting with the narrative engine API
class NarrativeAPIService: ObservableObject {
    // Published properties for UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Use ServerConfig for dynamic configuration of the server URL
    private let serverConfig = ServerConfig.shared
    
    // Cache for metadata responses to reduce API calls
    private var metadataCache = NSCache<NSString, CacheEntry<MetadataResponse>>()
    
    // Cache for chapter responses to reduce API calls
    private var chapterCache = NSCache<NSString, CacheEntry<ChapterResponse>>()
    
    // Cache TTL in seconds (24 hours)
    private let cacheTTL: TimeInterval = 86400

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    // MARK: - API Methods

    /// Fetches metadata for the provided journal entry text with caching and retry logic.
    func fetchMetadata(for text: String, retryCount: Int = 3) -> AnyPublisher<MetadataResponse, APIServiceError> {
        guard let url = URL(string: "/api/metadata", relativeTo: serverConfig.serverURL) else {
            return Fail(error: APIServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        // Check cache first
        let cacheKey = NSString(string: text.hashValue.description)
        if let cachedResponse = metadataCache.object(forKey: cacheKey), !cachedResponse.isExpired {
            print("📦 Using cached metadata")
            return Just(cachedResponse.value)
                .setFailureType(to: APIServiceError.self)
                .eraseToAnyPublisher()
        }

        let requestBody = MetadataRequest(text: text)
        var request: URLRequest

        do {
            request = try createPostRequest(url: url, body: requestBody)
        } catch let error as APIServiceError {
            return Fail(error: error).eraseToAnyPublisher()
        } catch {
             return Fail(error: APIServiceError.underlying(error)).eraseToAnyPublisher()
        }

        self.isLoading = true
        self.errorMessage = nil
        
        return performRequest(request)
            .handleEvents(
                receiveOutput: { [weak self] metadata in
                    // Cache the successful response
                    let cacheKey = NSString(string: text.hashValue.description)
                    let cacheEntry = CacheEntry(value: metadata)
                    self?.metadataCache.setObject(cacheEntry, forKey: cacheKey)
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            )
            .retry(retryCount) // Retry failed requests
            .eraseToAnyPublisher()
    }

    /// Generates a story chapter based on metadata with caching and retry logic.
    func generateChapter(requestData: ChapterGenerationRequest, retryCount: Int = 3) -> AnyPublisher<ChapterResponse, APIServiceError> {
        guard let url = URL(string: "/api/generate-chapter", relativeTo: serverConfig.serverURL) else {
            return Fail(error: APIServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        // Generate a cache key based on the request data
        let cacheKey = NSString(string: "\(requestData.metadata.hashValue)_\(requestData.userId)_\(requestData.genre)_\(requestData.studentName)")
        
        // Check cache first
        if let cachedResponse = chapterCache.object(forKey: cacheKey), !cachedResponse.isExpired {
            print("📦 Using cached chapter response")
            return Just(cachedResponse.value)
                .setFailureType(to: APIServiceError.self)
                .eraseToAnyPublisher()
        }

        var request: URLRequest
        do {
            request = try createPostRequest(url: url, body: requestData)
        } catch let error as APIServiceError {
            return Fail(error: error).eraseToAnyPublisher()
        } catch {
             return Fail(error: APIServiceError.underlying(error)).eraseToAnyPublisher()
        }

        self.isLoading = true
        self.errorMessage = nil
        
        return performRequest(request)
            .handleEvents(
                receiveOutput: { [weak self] chapter in
                    // Cache the successful response
                    let cacheKey = NSString(string: "\(requestData.metadata.hashValue)_\(requestData.userId)_\(requestData.genre)_\(requestData.studentName)")
                    let cacheEntry = CacheEntry(value: chapter)
                    self?.chapterCache.setObject(cacheEntry, forKey: cacheKey)
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            )
            .retry(retryCount) // Retry failed requests
            .eraseToAnyPublisher()
    }
    
    /// Fetches all story nodes for a specific user
    /// - Parameter userId: The ID of the user to fetch story nodes for
    /// - Returns: A publisher that emits an array of StoryNodes or an error
    func fetchStoryNodes(for userId: String) -> AnyPublisher<[StoryNode], APIServiceError> {
        // Future implementation: Replace with real endpoint
        // For now, use the local persistence manager to fetch saved nodes
        return Future<[StoryNode], APIServiceError> { promise in
            // Attempt to load from StoryPersistenceManager first
            if let persistenceManager = try? StoryPersistenceManager.shared {
                persistenceManager.loadStoryNodes { result in
                    switch result {
                    case .success(_):
                        // Get the nodes from the persistence manager after loading completes
                        let loadedNodes = persistenceManager.nodesForUser(userId)
                        if !loadedNodes.isEmpty {
                            // Return loaded nodes if available
                            promise(.success(loadedNodes))
                        } else {
                            // No nodes found, fall back to mock data
                            promise(.success(self.createMockStoryNodes(for: userId)))
                        }
                    case .failure(_):
                        // Error occurred, fall back to mock data
                        promise(.success(self.createMockStoryNodes(for: userId)))
                    }
                }
            } else {
                // Fallback to mock data if persistence manager unavailable
                promise(.success(self.createMockStoryNodes(for: userId)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates mock story nodes for development and testing
    /// - Parameter userId: The user ID to create mock nodes for
    /// - Returns: An array of mock StoryNodes
    private func createMockStoryNodes(for userId: String) -> [StoryNode] {
        // Create some mock metadata
        let metadata1 = MetadataResponse(
            sentiment: "positive",
            themes: ["adventure", "discovery"],
            entities: ["forest", "mountain", "map"],
            keyPhrases: ["ancient ruins", "hidden treasure"]
        )
        
        let metadata2 = MetadataResponse(
            sentiment: "tense",
            themes: ["danger", "mystery"],
            entities: ["cave", "stranger", "artifact"],
            keyPhrases: ["mysterious glow", "strange sounds"]
        )
        
        let metadata3 = MetadataResponse(
            sentiment: "hopeful",
            themes: ["perseverance", "friendship"],
            entities: ["village", "elder", "bridge"],
            keyPhrases: ["unexpected ally", "ancient wisdom"]
        )
        
        // Create mock chapters
        let chapter1 = ChapterResponse(
            chapterId: "ch-mock-1",
            text: "The forest floor crunched underfoot as Elara ventured deeper, the ancient map clutched in her hand. Strange symbols glowed faintly on the parchment, reacting to the proximity of the hidden grove. Suddenly, a twig snapped behind her, sharp and distinct in the unnerving silence.",
            cliffhanger: "A twig snapped behind her, sharp and distinct in the unnerving silence.",
            studentName: "Student",
            feedback: "Your journal entry has been transformed into an exciting adventure!"
        )
        
        let chapter2 = ChapterResponse(
            chapterId: "ch-mock-2",
            text: "Elara whirled around, hand instinctively reaching for the dagger at her belt. A tall figure stood partially obscured by shadow, watching her from between two ancient oaks. 'I've been expecting you,' the stranger said, voice unsettlingly calm. 'You have something that belongs to me.'",
            cliffhanger: "'You have something that belongs to me.'",
            studentName: "Student",
            feedback: "Great progress on your journal! Your story is taking shape."
        )
        
        let chapter3 = ChapterResponse(
            chapterId: "ch-mock-3",
            text: "The village elder's eyes widened as Elara presented the artifact. 'Where did you find this?' he whispered, hands trembling as he reached for it. 'This has been lost for generations.' He looked up sharply, suddenly suspicious. 'Did anyone follow you here?'",
            cliffhanger: "'Did anyone follow you here?'",
            studentName: "Student",
            feedback: "Your journaling is helping build this fascinating story. Keep it up!"
        )
        
        // Create a chain of story nodes (entry1 -> entry2 -> entry3)
        let entry1Id = UUID()
        let entry2Id = UUID()
        let entry3Id = UUID()
        
        let node1 = StoryNode(
            entryId: entry1Id,
            chapterId: chapter1.chapterId,
            parentId: nil, // First entry in the chain
            metadata: metadata1,
            chapter: chapter1
        )
        
        let node2 = StoryNode(
            entryId: entry2Id,
            chapterId: chapter2.chapterId,
            parentId: entry1Id, // Links to the first entry
            metadata: metadata2,
            chapter: chapter2
        )
        
        let node3 = StoryNode(
            entryId: entry3Id,
            chapterId: chapter3.chapterId,
            parentId: entry2Id, // Links to the second entry
            metadata: metadata3,
            chapter: chapter3
        )
        
        return [node1, node2, node3]
    }


    // MARK: - Helper Methods

    /// Creates a URLRequest configured for a POST request with a JSON body.
    private func createPostRequest<T: Encodable>(url: URL, body: T) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIServiceError.encodingError(error)
        }
        return request
    }

    /// Performs the URLSession data task and handles decoding and errors.
    private func performRequest<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, APIServiceError> {
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIServiceError.invalidResponse(statusCode: 0) // Should not happen with HTTP
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Attempt to decode error message from server if possible
                    // print("Error Response Body: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw APIServiceError.invalidResponse(statusCode: httpResponse.statusCode)
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> APIServiceError in
                // Convert specific errors or wrap others
                if let apiError = error as? APIServiceError {
                    return apiError
                } else if error is DecodingError {
                    return .decodingError(error)
                } else {
                    return .requestFailed(error)
                }
            }
            .eraseToAnyPublisher() // Type erase to AnyPublisher
    }
}
