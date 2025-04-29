import XCTest
import Combine
@testable import MetacognitiveJournal

class NarrativeAPIServiceTests: XCTestCase {
    
    var service: NarrativeAPIService!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        // Create a test configuration for the service
        ServerConfig.shared.setTestEnvironment()
        service = NarrativeAPIService()
    }
    
    override func tearDown() {
        service = nil
        cancellables = []
        super.tearDown()
    }
    
    func testFetchMetadata() throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch metadata")
        let testText = "Today I felt happy because I completed my homework early."
        
        var resultMetadata: MetadataResponse?
        var resultError: Error?
        
        // Mock expected response data
        let mockResponse = MetadataResponse(
            themes: ["achievement", "responsibility"],
            sentiment: "positive",
            characters: ["I"],
            setting: "home/school",
            keyInsights: ["Completing tasks early leads to positive feelings."]
        )
        
        // Setup mock URL session
        let mockData = try JSONEncoder().encode(mockResponse)
        URLProtocolMock.mockURLs = [
            URL(string: "\(service.baseURL)/api/metadata")!: (mockData, HTTPURLResponse(url: URL(string: "\(service.baseURL)/api/metadata")!, statusCode: 200, httpVersion: nil, headerFields: nil), nil)
        ]
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        service.session = URLSession(configuration: configuration)
        
        // When
        service.fetchMetadata(for: testText)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { response in
                resultMetadata = response
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError, "Error should be nil")
        XCTAssertNotNil(resultMetadata, "Metadata response should not be nil")
        XCTAssertEqual(resultMetadata?.themes, mockResponse.themes)
        XCTAssertEqual(resultMetadata?.sentiment, mockResponse.sentiment)
    }
    
    func testGenerateChapter() throws {
        // Given
        let expectation = XCTestExpectation(description: "Generate chapter")
        
        let metadata = MetadataResponse(
            themes: ["adventure", "friendship"],
            sentiment: "excited",
            characters: ["Alex", "Sam"],
            setting: "forest",
            keyInsights: ["Friends help each other in difficult situations."]
        )
        
        let request = ChapterGenerationRequest(
            metadata: metadata,
            userId: "test-user",
            genre: "fantasy",
            studentName: "Alex",
            previousArcs: []
        )
        
        var resultChapter: ChapterResponse?
        var resultError: Error?
        
        // Mock expected chapter response
        let mockChapter = ChapterResponse(
            chapterId: "ch-12345",
            text: "Alex ventured into the dense forest, the canopy of leaves blocking out the afternoon sun...",
            cliffhanger: "What would Alex find behind the ancient door?",
            metadata: metadata,
            studentName: "Alex",
            feedback: "Great job, Alex! Your story shows creativity and problem-solving skills."
        )
        
        // Setup mock URL session
        let mockData = try JSONEncoder().encode(mockChapter)
        URLProtocolMock.mockURLs = [
            URL(string: "\(service.baseURL)/api/generate-chapter")!: (mockData, HTTPURLResponse(url: URL(string: "\(service.baseURL)/api/generate-chapter")!, statusCode: 200, httpVersion: nil, headerFields: nil), nil)
        ]
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        service.session = URLSession(configuration: configuration)
        
        // When
        service.generateChapter(requestData: request)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { response in
                resultChapter = response
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError, "Error should be nil")
        XCTAssertNotNil(resultChapter, "Chapter response should not be nil")
        XCTAssertEqual(resultChapter?.chapterId, mockChapter.chapterId)
        XCTAssertEqual(resultChapter?.studentName, "Alex")
    }
    
    func testErrorHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Handle API error")
        let testText = "Test text"
        
        var resultError: APIServiceError?
        
        // Setup mock URL session with error
        let mockError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        URLProtocolMock.mockURLs = [
            URL(string: "\(service.baseURL)/api/metadata")!: (nil, nil, mockError)
        ]
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        service.session = URLSession(configuration: configuration)
        
        // When
        service.fetchMetadata(for: testText)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error as? APIServiceError
                }
                expectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("Should not receive a value")
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError, "Error should not be nil")
        if case .networkError = resultError {
            // Success - correct error type
        } else {
            XCTFail("Expected networkError but got \(String(describing: resultError))")
        }
    }
    
    func testRetryMechanism() {
        // Given
        let expectation = XCTestExpectation(description: "Retry on failure")
        expectation.expectedFulfillmentCount = 3 // Initial request + 2 retries
        
        let testText = "Test text"
        
        // Setup mock URL session with error for testing retry
        let mockError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Temporary network error"])
        URLProtocolMock.mockURLs = [
            URL(string: "\(service.baseURL)/api/metadata")!: (nil, nil, mockError)
        ]
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        service.session = URLSession(configuration: configuration)
        
        // Track retry attempts
        var retryCount = 0
        URLProtocolMock.requestHandler = { request in
            retryCount += 1
            expectation.fulfill()
            return (nil, nil, mockError)
        }
        
        // When
        service.fetchMetadata(for: testText)
            .retry(2) // Retry twice after initial failure
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(retryCount, 3, "Should have made 3 attempts (initial + 2 retries)")
    }
}

// MARK: - URL Protocol Mock

class URLProtocolMock: URLProtocol {
    // This dictionary maps URLs to tuples of (data, response, error)
    static var mockURLs = [URL: (Data?, URLResponse?, Error?)]()
    
    // Handler for custom verification of requests
    static var requestHandler: ((URLRequest) -> (Data?, URLResponse?, Error?))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let handler = URLProtocolMock.requestHandler {
            let (data, response, error) = handler(request)
            handleRequest(data: data, response: response, error: error)
            return
        }
        
        if let url = request.url, let (data, response, error) = URLProtocolMock.mockURLs[url] {
            handleRequest(data: data, response: response, error: error)
            return
        }
        
        // Default fallback if no match
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data found for URL: \(request.url?.absoluteString ?? "unknown")"])
        client?.urlProtocol(self, didFailWithError: error)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    private func handleRequest(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // This is called when a request is cancelled or completed
    }
}
