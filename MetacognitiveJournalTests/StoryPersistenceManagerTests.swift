import XCTest
import Combine
@testable import MetacognitiveJournal

class StoryPersistenceManagerTests: XCTestCase {
    
    var persistenceManager: StoryPersistenceManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        
        // Use a test-specific instance to avoid affecting actual user data
        persistenceManager = try! StoryPersistenceManager(skipInitialLoad: true)
        
        // Clear any existing test data
        persistenceManager.storyNodes = []
        persistenceManager.storyArcs = []
    }
    
    override func tearDown() {
        persistenceManager = nil
        cancellables = []
        super.tearDown()
    }
    
    func testSaveAndLoadStoryNode() {
        // Given
        let expectation = XCTestExpectation(description: "Save and load story node")
        
        let testNode = StoryNode(
            entryId: "entry-123",
            chapterId: "chapter-123",
            parentId: nil,
            metadata: MetadataResponse(
                themes: ["adventure"],
                sentiment: "excited",
                characters: ["Alice"],
                setting: "forest",
                keyInsights: ["Exploration leads to discovery."]
            ),
            chapter: ChapterResponse(
                chapterId: "chapter-123",
                text: "This is a test chapter.",
                cliffhanger: "What will happen next?",
                metadata: MetadataResponse(
                    themes: ["adventure"],
                    sentiment: "excited",
                    characters: ["Alice"],
                    setting: "forest",
                    keyInsights: ["Exploration leads to discovery."]
                ),
                studentName: "Alice",
                feedback: "Great job, Alice!"
            )
        )
        
        // When
        persistenceManager.saveNode(testNode) { result in
            switch result {
            case .success:
                // Then
                XCTAssertEqual(self.persistenceManager.storyNodes.count, 1, "Should have 1 story node")
                XCTAssertEqual(self.persistenceManager.storyNodes.first?.chapterId, "chapter-123")
                
                // Test loading
                self.persistenceManager.storyNodes = [] // Clear memory
                self.persistenceManager.loadStoryNodes { _ in
                    XCTAssertEqual(self.persistenceManager.storyNodes.count, 1, "Should load 1 story node")
                    XCTAssertEqual(self.persistenceManager.storyNodes.first?.chapterId, "chapter-123")
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to save node: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSaveAndLoadStoryArc() {
        // Given
        let expectation = XCTestExpectation(description: "Save and load story arc")
        
        let testArc = StoryArc(
            summary: "Alice ventured into the forest...",
            chapterId: "chapter-123",
            timestamp: Date(),
            themes: ["adventure", "discovery"]
        )
        
        // When
        persistenceManager.saveStoryArc(testArc) { result in
            switch result {
            case .success:
                // Then
                XCTAssertEqual(self.persistenceManager.storyArcs.count, 1, "Should have 1 story arc")
                XCTAssertEqual(self.persistenceManager.storyArcs.first?.chapterId, "chapter-123")
                XCTAssertEqual(self.persistenceManager.storyArcs.first?.themes, ["adventure", "discovery"])
                
                // Test loading
                self.persistenceManager.storyArcs = [] // Clear memory
                self.persistenceManager.loadStoryArcs { _ in
                    XCTAssertEqual(self.persistenceManager.storyArcs.count, 1, "Should load 1 story arc")
                    XCTAssertEqual(self.persistenceManager.storyArcs.first?.chapterId, "chapter-123")
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to save arc: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testGetRecentStoryArcs() {
        // Given: Multiple story arcs with different timestamps
        let now = Date()
        
        let arc1 = StoryArc(
            summary: "First arc",
            chapterId: "ch-1",
            timestamp: now.addingTimeInterval(-3600), // 1 hour ago
            themes: ["adventure"]
        )
        
        let arc2 = StoryArc(
            summary: "Second arc",
            chapterId: "ch-2",
            timestamp: now.addingTimeInterval(-1800), // 30 minutes ago
            themes: ["mystery"]
        )
        
        let arc3 = StoryArc(
            summary: "Third arc",
            chapterId: "ch-3",
            timestamp: now, // Now
            themes: ["friendship"]
        )
        
        let arc4 = StoryArc(
            summary: "Fourth arc",
            chapterId: "ch-4",
            timestamp: now.addingTimeInterval(-7200), // 2 hours ago
            themes: ["courage"]
        )
        
        // Add arcs in non-chronological order
        persistenceManager.storyArcs = [arc1, arc4, arc2, arc3]
        
        // When: Get most recent arcs
        let recentArcs = persistenceManager.getRecentStoryArcs(count: 2)
        
        // Then: Should return the most recent 2 arcs in order
        XCTAssertEqual(recentArcs.count, 2, "Should return 2 arcs")
        XCTAssertEqual(recentArcs[0], "Third arc", "First arc should be the most recent")
        XCTAssertEqual(recentArcs[1], "Second arc", "Second arc should be the second most recent")
    }
    
    func testCreateStoryArcFromChapter() {
        // Given
        let chapter = ChapterResponse(
            chapterId: "ch-test",
            text: "This is a long chapter text that will be summarized in the arc. The protagonist goes on an adventure and discovers a hidden treasure.",
            cliffhanger: "What will they do with the treasure?",
            metadata: MetadataResponse(
                themes: ["adventure", "discovery"],
                sentiment: "excited",
                characters: ["protagonist"],
                setting: "forest",
                keyInsights: ["Persistence leads to rewards."]
            ),
            studentName: "Sam",
            feedback: "Great job, Sam!"
        )
        
        // When
        let arc = StoryArc.createFrom(chapter: chapter, themes: ["adventure", "discovery"])
        
        // Then
        XCTAssertEqual(arc.chapterId, "ch-test")
        XCTAssertEqual(arc.themes, ["adventure", "discovery"])
        XCTAssertEqual(arc.summary, "This is a long chapter text that will be summarized in the arc. The protagonist goes on an adventure and di...")
    }
}
