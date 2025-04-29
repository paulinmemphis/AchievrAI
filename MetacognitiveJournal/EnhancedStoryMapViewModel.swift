// EnhancedStoryMapViewModel.swift
import SwiftUI
import Combine
import Foundation

/// Enhanced view model for the StoryMapView to visualize story arcs and continuity
class EnhancedStoryMapViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var storyNodes: [StoryNode] = []
    @Published var storyArcs: [StoryArc] = []
    @Published var chapters: [String: Chapter] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedNodeId: String? = nil
    @Published var selectedArcId: IdentifiableUUID?
    @Published var showingArcLabels = true
    @Published var visualMode: VisualizationMode = .tree
    @Published var highlightedTheme: String?
    @Published var nodeConnections: [NodeConnection] = []
    @Published var expandedNodeIds: Set<String> = []
    
    // Computed property to provide ViewModels for the view
    var nodeViewModels: [StoryNodeViewModel] {
        storyNodes.map { node in
            // Look up the chapter using node.chapterId
            let chapter = chapters[node.chapterId]
            let previewText = chapter?.text.prefix(150).appending("...") ?? "Chapter text not available."
            let genre = chapter?.genre ?? "Unknown"

            // Use the full initializer
            return StoryNodeViewModel(
                id: node.id,
                chapterId: node.chapterId,
                title: "Chapter \(node.chapterId.suffix(6))", // Keep existing title logic or refine
                entryPreview: "Entry preview placeholder...", // Keep placeholder for now
                chapterPreview: String(previewText),
                sentiment: Double(node.metadata.sentiment) ?? 0.0,
                themes: node.metadata.themes,
                creationDate: node.creationDate,
                genre: genre
            )
        }
    }

    // Visualization modes
    enum VisualizationMode: String, CaseIterable, Identifiable {
        case tree = "Tree View"
        case timeline = "Timeline"
        case thematic = "Thematic"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .tree: return "square.grid.3x3"
            case .timeline: return "arrow.left.arrow.right"
            case .thematic: return "tag"
            }
        }
    }
    
    // Store common themes from all story nodes
    var allThemes: [String] {
        let themeSet = Set(storyNodes.flatMap { $0.metadata.themes })
        return Array(themeSet).sorted()
    }
    
    // Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    // Services
    private let apiService: NarrativeAPIService
    private let storyPersistenceManager = StoryPersistenceManager.shared
    private var persistenceManager: StoryPersistenceManager?
    
    // Analytics manager for tracking engagement
    private let analyticsManager = AnalyticsManager.shared
    
    // Defer loading to prevent startup issues
    private var hasInitiallyLoaded = false
    
    init(apiService: NarrativeAPIService = NarrativeAPIService()) {
        self.apiService = apiService
        
        // Initialize persistence manager
        self.persistenceManager = StoryPersistenceManager.shared
        // Error handling moved to loadStoryData method
    }
    
    // Call this method when the view appears to safely load data
    func loadIfNeeded() {
        if !hasInitiallyLoaded {
            hasInitiallyLoaded = true
            loadStoryData()
        }
    }
    
    
    // Load all story data (nodes and arcs)
    func loadStoryData() {
        isLoading = true
        errorMessage = nil
        
        
        // Track analytics
        analyticsManager.logEvent(.userInteraction, properties: ["action": "viewed_story_map"])
        
        // Load data from persistence manager
        guard let persistenceManager = persistenceManager else {
            errorMessage = "Story persistence manager not available"
            isLoading = false
            return
        }
        
        // First load story nodes
        loadStoryNodes { [weak self] (result: Result<Void, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Nodes are loaded (self.storyNodes is updated inside loadStoryNodes)
                // Ensure local copy reflects the manager's state after loading
                if let manager = self.persistenceManager {
                    self.storyNodes = manager.storyNodes
                }

                // Fetch chapters individually using getChapter(id:)
                var loadedChapters: [String: Chapter] = [:]
                if let manager = self.persistenceManager {
                    for node in self.storyNodes {
                        if let chapter = manager.getChapter(id: node.chapterId) {
                            loadedChapters[node.chapterId] = chapter
                        } else {
                            // Handle case where chapter is missing for a node, if necessary
                            print("Warning: Chapter data not found for node \(node.id), chapterId: \(node.chapterId)")
                        }
                    }
                }
                self.chapters = loadedChapters // Update the published dictionary

                // Now load story arcs
                self.loadStoryArcs() // Assuming this might also be async

                // isLoading should likely be set to false within the completion handler of the *last* async operation
                // If loadStoryArcs is async and we need its results, move isLoading = false there.
                // If loadStoryArcs is sync or not essential to wait for, this is okay.
                // For now, we'll leave it here, but be aware it might need moving if arcs load async.
                 DispatchQueue.main.async { // Ensure UI updates on main thread
                    self.isLoading = false
                 }

            case .failure(let error):
                 // Handle node loading failure
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load story nodes: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Loads story nodes from the persistence manager
    func loadStoryNodes(completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("[EnhancedStoryMapViewModel] Loading story nodes...")
        
        // Get story nodes from persistence manager
        guard let manager = persistenceManager else {
            isLoading = false
            return
        }
        
        manager.getAllStoryNodes()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .finished:
                    print("[EnhancedStoryMapViewModel] Successfully loaded \(self.storyNodes.count) story nodes")
                    completion(.success(()))
                case .failure(let error):
                    print("[EnhancedStoryMapViewModel] Error loading story nodes: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load stories: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] nodes in
                self?.storyNodes = nodes
            })
            .store(in: &cancellables)
    }
    
    // Load story arcs
    private func loadStoryArcs() {
        guard let persistenceManager = persistenceManager else {
            errorMessage = "Story persistence manager not available"
            isLoading = false
            return
        }
        
        persistenceManager.loadStoryArcs { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    // Get arcs from persistence manager
                    self.storyArcs = persistenceManager.storyArcs
                    
                    // Build connections between nodes based on story arcs
                    self.buildNodeConnections()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load story arcs: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Build connections between nodes for visualization
    private func buildNodeConnections() {
        nodeConnections = []
        
        // Generate connections based on parentId relationships
        for node in storyNodes where node.parentId != nil {
            if let parentNode = storyNodes.first(where: { $0.entryId == node.parentId }) {
                let connection = NodeConnection(
                    source: parentNode.id,
                    target: node.id,
                    type: .narrative
                )
                nodeConnections.append(connection)
            }
        }
        
        // Generate thematic connections based on shared themes
        if visualMode == .thematic {
            for i in 0..<storyNodes.count {
                for j in (i+1)..<storyNodes.count {
                    let node1 = storyNodes[i]
                    let node2 = storyNodes[j]
                    
                    // Find shared themes
                    let themes1 = Set(node1.metadata.themes)
                    let themes2 = Set(node2.metadata.themes)
                    let sharedThemes = themes1.intersection(themes2)
                    
                    if !sharedThemes.isEmpty {
                        // Create a thematic connection
                        let connection = NodeConnection(
                            source: node1.id,
                            target: node2.id,
                            type: .thematic,
                            theme: sharedThemes.first
                        )
                        nodeConnections.append(connection)
                    }
                }
            }
        }
    }
    
    // Arrange nodes by visualization mode
    func arrangedNodes() -> [[StoryNode]] {
        switch visualMode {
        case .tree:
            return arrangeNodesAsTree()
        case .timeline:
            return arrangeNodesAsTimeline()
        case .thematic:
            return arrangeNodesByTheme()
        }
    }
    
    // Tree structure - group by parent-child relationships
    private func arrangeNodesAsTree() -> [[StoryNode]] {
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
    
    // Timeline - arrange by chronological order
    private func arrangeNodesAsTimeline() -> [[StoryNode]] {
        let sortedNodes = storyNodes.sorted { $0.timestamp < $1.timestamp }
        return [sortedNodes] // Single row for timeline
    }
    
    // Thematic - group by shared themes
    private func arrangeNodesByTheme() -> [[StoryNode]] {
        var result: [[StoryNode]] = []
        
        // If a theme is highlighted, prioritize it
        if let theme = highlightedTheme {
            let nodesWithTheme = storyNodes.filter { $0.metadata.themes.contains(theme) }
            if !nodesWithTheme.isEmpty {
                result.append(nodesWithTheme)
            }
        }
        
        // Add remaining nodes by dominant theme
        let remainingNodes = highlightedTheme != nil 
            ? storyNodes.filter { !$0.metadata.themes.contains(highlightedTheme!) }
            : storyNodes
        
        // Group remaining nodes by their dominant theme
        let groupedByTheme = Dictionary(grouping: remainingNodes) { node -> String in
            // Use the first theme as the dominant one, or "unknown" if no themes
            return node.metadata.themes.first ?? "unknown"
        }
        
        // Add each theme group as a row
        for (_, nodes) in groupedByTheme.sorted(by: { $0.key < $1.key }) {
            result.append(nodes)
        }
        
        return result
    }
    
    // Node connection type
    enum ConnectionType {
        case narrative
        case thematic
    }
    
    // Structure to represent a connection between nodes
    struct NodeConnection: Identifiable {
        let id = UUID()
        let source: String
        let target: String
        let type: ConnectionType
        var theme: String?
        
        var color: Color {
            switch type {
            case .narrative:
                return .blue
            case .thematic:
                return .green
            }
        }
        
        var lineWidth: CGFloat {
            switch type {
            case .narrative:
                return 2
            case .thematic:
                return 1
            }
        }
        
        var dashPattern: [CGFloat]? {
            switch type {
            case .narrative:
                return nil
            case .thematic:
                return [4, 2]
            }
        }
    }
    
    // MARK: - User Interactions
    
    /// Select a node
    /// - Parameter nodeId: The ID of the node to select
    func selectNode(nodeId: String) {
        if let node = storyNodes.first(where: { $0.id == nodeId }) {
            selectedNodeId = nodeId
            
            // Track node selection in analytics
            analyticsManager.logEvent(.userInteraction, properties: [
                "action": "selected_story_node", 
                "chapter_id": node.chapterId
            ])
        }
    }
    
    /// Clear the selected node
    func clearSelection() {
        selectedNodeId = nil
        selectedArcId = nil
    }
    
    /// Get a node by its ID
    func node(for id: String) -> StoryNode? {
        return storyNodes.first(where: { $0.id == id })
    }
    
    /// Get an arc by its ID
    func arc(for id: IdentifiableUUID) -> StoryArc? {
        return storyArcs.first(where: { $0.id.uuidString == id.id.uuidString })
    }
    
    /// Get an arc by its raw UUID
    func arc(forUUID id: String) -> StoryArc? {
        return storyArcs.first(where: { $0.id.uuidString == id })
    }
    
    /// Change visualization mode
    func setVisualizationMode(_ mode: VisualizationMode) {
        visualMode = mode
        buildNodeConnections() // Rebuild connections when changing modes
        
        // Track mode change in analytics
        analyticsManager.logEvent(.userInteraction, properties: [
            "action": "changed_story_map_view", 
            "mode": mode.rawValue
        ])
    }
    
    /// Highlight a specific theme
    func highlightTheme(_ theme: String?) {
        highlightedTheme = theme
        if theme != nil && visualMode != .thematic {
            visualMode = .thematic // Switch to thematic mode when highlighting
        }
        buildNodeConnections()
        
        // Track theme highlighting in analytics
        if let theme = theme {
            analyticsManager.logEvent(.userInteraction, properties: [
                "action": "highlighted_theme", 
                "theme": theme
            ])
        }
    }
}
