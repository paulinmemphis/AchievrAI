import Foundation
import Combine

// Make sure we're using the AppError from EnvironmentConfig for network operations

/// Client for interacting with the Narrative Engine API
class NarrativeEngineClient {
    // MARK: - Properties
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    // MARK: - Constants
    private enum Constants {
        static let metadataEndpoint = "api/metadata"
        static let generateChapterEndpoint = "api/generate-chapter"
        static let defaultTimeout: TimeInterval = 60.0
    }
    
    // MARK: - Initialization
    
    init(baseURL: URL = URL(string: AppConstants.apiBaseURL)!, 
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - API Methods
    
    /// Extract metadata from journal entry text
    /// - Parameter text: Journal entry text
    /// - Returns: Publisher that emits metadata or error
    func extractMetadata(from text: String) -> AnyPublisher<MetadataResponse, Error> {
        guard let url = URL(string: Constants.metadataEndpoint, relativeTo: baseURL) else {
            return Fail(error: AppError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.defaultTimeout
        
        // Add API key if available
        if let apiKey = AppConstants.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        
        let payload = ["text": text]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return Fail(error: AppError.serializationFailed).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .retry(3) // Retry up to 3 times
            .mapError { AppError.networkError($0) }
            .map(\.data)
            .decode(type: MetadataResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Generate a story chapter from metadata and context
    /// - Parameters:
    ///   - metadata: The metadata extracted from the journal entry
    ///   - userId: The user identifier
    ///   - genre: The storytelling genre
    ///   - previousArcs: Optional array of previous story arcs
    /// - Returns: Publisher that emits the generated chapter response or error
    func generateChapter(
        metadata: EntryMetadata,
        userId: String,
        genre: String,
        previousArcs: [PreviousArc] = []
    ) -> AnyPublisher<ChapterResponse, Error> {
        guard let url = URL(string: Constants.generateChapterEndpoint, relativeTo: baseURL) else {
            return Fail(error: AppError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.defaultTimeout * 2 // Longer timeout for generation
        
        // Add API key if available
        if let apiKey = AppConstants.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        
        // Convert the metadata to dictionary for the API
        let metadataDict: [String: Any] = [
            "sentiment": metadata.sentiment,
            "themes": metadata.themes,
            "entities": metadata.entities,
            "keyPhrases": metadata.keyPhrases
        ]
        
        var payload: [String: Any] = [
            "metadata": metadataDict,
            "userId": userId,
            "genre": genre
        ]
        
        if !previousArcs.isEmpty {
            let arcsArray = previousArcs.map { arc in
                [
                    "summary": arc.summary,
                    "themes": arc.themes,
                    "chapterId": arc.chapterId
                ] as [String: Any]
            }
            payload["previousArcs"] = arcsArray
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return Fail(error: AppError.serializationFailed).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .retry(2) // Retry up to 2 times
            .mapError { AppError.networkError($0) }
            .map(\.data)
            .decode(type: ChapterResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// Note: We're now using the ChapterResponse from NarrativeDataModels.swift
