import SwiftUI
import Combine

// Add import for EntryMetadata if not already included in this file's scope
import Foundation

/// A test harness for the enhanced story map visualization
struct StoryMapVisualTester: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var testMode: TestMode = .realData
    
    enum TestMode: String, CaseIterable, Identifiable {
        case realData = "Real Data"
        case sampleData = "Sample Data"
        case stressTest = "Stress Test"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Test Mode", selection: $testMode) {
                    ForEach(TestMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ZStack {
                    switch testMode {
                    case .realData:
                        EnhancedStoryMapView()
                            .environmentObject(themeManager)
                    case .sampleData:
                        SampleDataStoryMapView()
                            .environmentObject(themeManager)
                    case .stressTest:
                        StressTestStoryMapView()
                            .environmentObject(themeManager)
                    }
                }
            }
            .navigationTitle("Story Map Testing")
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
}

/// View that uses sample data to showcase the enhanced story map
struct SampleDataStoryMapView: View {
    @StateObject private var viewModel = TestStoryMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            if !viewModel.injectedData {
                Button("Load Sample Data") {
                    viewModel.injectSampleData()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                EnhancedStoryMapView()
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            viewModel.injectSampleData()
        }
    }
}

/// View that uses a large dataset to stress test the enhanced story map
struct StressTestStoryMapView: View {
    @StateObject private var viewModel = TestStoryMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            if !viewModel.injectedData {
                Button("Load Stress Test Data") {
                    viewModel.injectStressTestData()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                EnhancedStoryMapView()
                    .environmentObject(themeManager)
            }
        }
    }
}

/// View model for testing the enhanced story map
class TestStoryMapViewModel: ObservableObject {
    @Published var injectedData = false
    
    func injectSampleData() {
        guard !injectedData else { return }
        
        // Create sample nodes and arcs
        let sampleNodes = createSampleStoryNodes()
        let sampleArcs = createSampleStoryArcs()
        
        // Get access to the persistence manager
        let persistenceManager = StoryPersistenceManager.shared
        
        // Clear existing data and add our sample data
        clearAndAddNodes(nodes: sampleNodes, arcs: sampleArcs, to: persistenceManager)
        
        injectedData = true
    }
    
    func injectStressTestData() {
        guard !injectedData else { return }
        
        // Create a large set of story nodes for stress testing
        let stressNodes = createLargeStoryNodeSet(count: 50)
        let stressArcs = createSampleStoryArcs()
        
        // Get access to the persistence manager
        let persistenceManager = StoryPersistenceManager.shared
        
        // Clear existing data and add our stress test data
        clearAndAddNodes(nodes: stressNodes, arcs: stressArcs, to: persistenceManager)
        
        injectedData = true
    }
    
    /// Helper method to clear existing data and add new nodes and arcs
    private func clearAndAddNodes(nodes: [StoryNode], arcs: [StoryArc], to persistenceManager: StoryPersistenceManager) {
        // First clear existing nodes
        for node in persistenceManager.storyNodes {
            persistenceManager.deleteNode(with: UUID(uuidString: node.id) ?? UUID())
        }
        
        // Then add each node individually
        for node in nodes {
            persistenceManager.addNode(node)
        }
        
        // Add arcs using the saveStoryArc method
        for arc in arcs {
            persistenceManager.saveStoryArc(arc) { _ in }
        }
    }
    
    /// Create a set of sample story nodes with variety for testing
    private func createSampleStoryNodes() -> [StoryNode] {
        // Create a parent node
        let rootNode = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-root",
            parentId: nil,
            themes: ["beginning", "introduction"],
            sentiment: "neutral",
            title: "The Journey Begins",
            text: "Once upon a time in a small village nestled between ancient mountains, a young adventurer named Elara prepared for a journey that would change everything.",
            cliffhanger: "What mysteries await beyond the mountain pass?"
        )
        
        // Create child nodes with different themes
        let child1 = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-forest",
            parentId: UUID(uuidString: rootNode.id),
            themes: ["nature", "discovery"],
            sentiment: "positive",
            title: "The Enchanted Forest",
            text: "Elara ventured into the dense forest, where sunlight filtered through emerald leaves. Strange creatures watched from the shadows, curious but not threatening.",
            cliffhanger: "What ancient secrets does the heart of the forest hold?"
        )
        
        let child2 = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-cave",
            parentId: UUID(uuidString: rootNode.id),
            themes: ["danger", "mystery"],
            sentiment: "negative",
            title: "The Dark Cavern",
            text: "The mountain caves echoed with ominous sounds. Water dripped from stalactites as Elara cautiously advanced, her torch revealing ancient carvings on the walls.",
            cliffhanger: "Who left these warnings etched in stone?"
        )
        
        // Create a grandchild node
        let grandchild1 = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-artifact",
            parentId: UUID(uuidString: child1.id),
            themes: ["discovery", "magic"],
            sentiment: "positive",
            title: "The Glowing Artifact",
            text: "Deep in the forest, Elara discovered a clearing where a strange artifact hovered above a stone pedestal, pulsing with blue light that seemed alive.",
            cliffhanger: "What power does this ancient object contain?"
        )
        
        let grandchild2 = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-guardian",
            parentId: UUID(uuidString: child2.id),
            themes: ["conflict", "challenge"],
            sentiment: "negative",
            title: "The Cave Guardian",
            text: "A massive creature of stone and crystal blocked the passage. Its eyes, like molten gold, studied Elara as she approached the ancient guardian.",
            cliffhanger: "How will Elara overcome this imposing sentinel?"
        )
        
        // Create a branching storyline
        let branch1 = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-village",
            parentId: UUID(uuidString: child1.id),
            themes: ["community", "friendship"],
            sentiment: "positive",
            title: "The Hidden Village",
            text: "Following a winding path through the trees, Elara discovered a village of tree-houses connected by rope bridges, home to forest-dwellers who welcomed her warmly.",
            cliffhanger: "What wisdom do these forest people possess?"
        )
        
        // Return all nodes
        return [rootNode, child1, child2, grandchild1, grandchild2, branch1]
    }
    
    /// Create story arcs to match the sample nodes
    private func createSampleStoryArcs() -> [StoryArc] {
        return [
            StoryArc(summary: "Elara begins her journey into the unknown", chapterId: "chapter-root", timestamp: Date(), themes: ["beginning", "adventure"]),
            StoryArc(summary: "The forest reveals its secrets and beauty", chapterId: "chapter-forest", timestamp: Date(), themes: ["nature", "discovery"]),
            StoryArc(summary: "Dark caverns hide ancient mysteries", chapterId: "chapter-cave", timestamp: Date(), themes: ["danger", "mystery"]),
            StoryArc(summary: "A powerful artifact with unknown potential", chapterId: "chapter-artifact", timestamp: Date(), themes: ["discovery", "magic"]),
            StoryArc(summary: "A guardian stands between Elara and her goal", chapterId: "chapter-guardian", timestamp: Date(), themes: ["conflict", "challenge"]),
            StoryArc(summary: "New allies provide shelter and knowledge", chapterId: "chapter-village", timestamp: Date(), themes: ["community", "friendship"])
        ]
    }
    
    /// Create a large set of story nodes for stress testing
    private func createLargeStoryNodeSet(count: Int) -> [StoryNode] {
        let themes = [
            ["adventure", "discovery"],
            ["mystery", "suspense"],
            ["friendship", "loyalty"],
            ["conflict", "challenge"],
            ["growth", "learning"],
            ["love", "connection"],
            ["loss", "grief"],
            ["hope", "inspiration"],
            ["betrayal", "deception"],
            ["redemption", "forgiveness"]
        ]
        
        let sentiments = ["positive", "negative", "neutral", "mixed"]
        
        var nodes: [StoryNode] = []
        
        // Create a root node
        let rootNode = createStoryNode(
            entryId: UUID(),
            chapterId: "chapter-0",
            parentId: nil,
            themes: themes[0],
            sentiment: sentiments[0],
            title: "The Beginning",
            text: "This is where it all begins...",
            cliffhanger: "What happens next?"
        )
        nodes.append(rootNode)
        
        // Create many nodes with various themes and sentiments
        for i in 1..<count {
            // Decide on parent node - create a tree-like structure
            let parentIndex = i > 5 ? Int.random(in: 0..<i-1) : 0
            let parentIdString = nodes[parentIndex].id
            let parentId = UUID(uuidString: parentIdString)
            
            // Pick random themes and sentiment
            let themeIndex = i % themes.count
            let sentimentIndex = i % sentiments.count
            
            let node = createStoryNode(
                entryId: UUID(),
                chapterId: "chapter-\(i)",
                parentId: parentId,
                themes: themes[themeIndex],
                sentiment: sentiments[sentimentIndex],
                title: "Chapter \(i)",
                text: "This is the story for chapter \(i), continuing the narrative with some new developments...",
                cliffhanger: "What will chapter \(i+1) reveal?"
            )
            
            nodes.append(node)
        }
        
        return nodes
    }
    
    /// Helper to create a story node with all required properties
    private func createStoryNode(
        entryId: UUID,
        chapterId: String,
        parentId: UUID?,
        themes: [String],
        sentiment: String,
        title: String,
        text: String,
        cliffhanger: String
    ) -> StoryNode {
        // Create metadata response
        let metadata = MetadataResponse(
            sentiment: sentiment,
            themes: themes,
            entities: ["character", "location"],
            keyPhrases: [title]
        )
        
        // Create and return the story node
        return StoryNode(
            id: UUID().uuidString,
            journalEntryId: entryId.uuidString, // Corrected name
            chapterId: chapterId,
            parentId: parentId?.uuidString,
            metadataSnapshot: StoryMetadata(    // Corrected name and type
                sentimentScore: Double(metadata.sentiment), // Convert String to Double?
                themes: metadata.themes,
                entities: metadata.entities,
                keyPhrases: metadata.keyPhrases
                // No genre, as StoryMetadata.swift doesn't define it
            ),
            createdAt: Date()                   // Corrected name
        )
    }
}

// MARK: - Preview
struct StoryMapVisualTester_Previews: PreviewProvider {
    static var previews: some View {
        StoryMapVisualTester()
    }
}
