// NarrativeAPIService.swift
import Foundation
import Combine // Import Combine framework
import SwiftUI

// MARK: - Request Models
struct MetadataRequest: Codable {
    let text: String
}

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
    
    // MARK: - Helper Methods
    /// Creates a URLRequest configured for a POST request with a JSON body.
    fileprivate func createPostRequest<T: Encodable>(url: URL, body: T) throws -> URLRequest {
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
    
    // MARK: - API Methods
    
    /// Performs a network request and decodes the response.
    fileprivate func performRequest<T: Decodable>(_ request: URLRequest, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, APIServiceError> {
        // Log the request for debugging
        print("[NarrativeAPIService] Making request to: \(request.url?.absoluteString ?? "unknown URL")")
        
        return session.dataTaskPublisher(for: request)
            .mapError { error -> APIServiceError in
                print("[NarrativeAPIService] Network error: \(error.localizedDescription)")
                return APIServiceError.requestFailed(error)
            }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIServiceError.invalidResponse(statusCode: -1)
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw APIServiceError.invalidResponse(statusCode: httpResponse.statusCode)
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                } else if let decodingError = error as? DecodingError {
                    return APIServiceError.decodingError(decodingError)
                } else {
                    return APIServiceError.underlying(error)
                }
            }
            .eraseToAnyPublisher()
    }
    /// Fetches metadata for the provided journal entry text with caching and retry logic.
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - retryCount: Number of times to retry on failure (default: 3)
    /// - Returns: A publisher that emits metadata or an error
    func getMetadata(text: String, retryCount: Int = 3) -> AnyPublisher<MetadataResponse, APIServiceError> {
        // Check cache first
        let cacheKey = NSString(string: "metadata_\(text.hashValue)")
        if let cachedEntry = metadataCache.object(forKey: cacheKey), !cachedEntry.isExpired {
            return Just(cachedEntry.value)
                .setFailureType(to: APIServiceError.self)
                .eraseToAnyPublisher()
        }
        
        // Construct the full URL properly
        let urlString = "\(serverConfig.serverURL.absoluteString)/api/metadata"
        guard let url = URL(string: urlString) else {
            print("[NarrativeAPIService] Invalid URL: \(urlString)")
            return Fail(error: APIServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        print("[NarrativeAPIService] Getting metadata with URL: \(url.absoluteString)")
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
        
        return performRequest(request, decoder: decoder)
            .handleEvents(receiveOutput: { [weak self] metadata in
                self?.metadataCache.setObject(CacheEntry(value: metadata, ttl: self?.cacheTTL ?? 86400), forKey: cacheKey)
            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            })
            .eraseToAnyPublisher()
            .retry(3) // Retry failed requests
            .eraseToAnyPublisher()
    }
    
    /// Generates a story chapter based on metadata with caching and retry logic.
    func generateChapter(requestData: ChapterGenerationRequest, retryCount: Int = 3) -> AnyPublisher<ChapterResponse, APIServiceError> {
        // Construct the full URL properly
        let urlString = "\(serverConfig.serverURL.absoluteString)/api/generate-chapter"
        guard let url = URL(string: urlString) else {
            print("[NarrativeAPIService] Invalid URL: \(urlString)")
            return Fail(error: APIServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        print("[NarrativeAPIService] Generating chapter with URL: \(url.absoluteString)")
        
        // Generate a cache key based on the request data
        let cacheKey = NSString(string: "\(requestData.metadata.hashValue)_\(requestData.genre)")
        
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
        
        return performRequest(request, decoder: decoder)
            .handleEvents(receiveOutput: { [weak self] chapter in
                self?.chapterCache.setObject(CacheEntry(value: chapter, ttl: self?.cacheTTL ?? 86400), forKey: cacheKey)
            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            })
            .eraseToAnyPublisher()
            .retry(3) // Retry failed requests
            .eraseToAnyPublisher()
    }
    
    /// Fetches all story nodes for a specific user
    /// - Parameter userId: The ID of the user to fetch story nodes for
    /// - Returns: A publisher that emits an array of StoryNodes or an error
    func fetchStoryNodes(for userId: String) -> AnyPublisher<[StoryNode], APIServiceError> {
        // Future implementation: Replace with real endpoint
        // For now, use the local persistence manager to fetch saved nodes
        return Future<[StoryNode], APIServiceError> { promise in
            // Attempt to load from StoryPersistenceManager
            let persistenceManager = StoryPersistenceManager.shared
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
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates mock story nodes for development and testing
    /// - Parameter userId: The user ID to create mock nodes for
    func createMockStoryNodes(for userId: String) -> [StoryNode] {
        // TO DO: Implement mock data creation
        return []
    }
}
