import Foundation
import Combine
import SwiftUI

class BasicStoryMapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var nodes: [StoryNodeViewModel] = []
    @Published var connections: [StoryConnection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedNode: StoryNodeViewModel? = nil
    @Published var visualizationStyle: VisualizationStyle = .timeline
    @Published var filterCriteria: StoryFilterCriteria = .init()
    
    // MARK: - Internal Properties
    private let persistenceManager: StoryPersistenceManager
    private var cancellables = Set<AnyCancellable>()
    
    /// Converts a string sentiment value to a Double
    /// - Parameter sentiment: The sentiment as a string (e.g., "positive", "negative", "neutral")
    /// - Returns: A Double value between -1 and 1 representing the sentiment
    private func convertSentimentToDouble(_ sentiment: String) -> Double {
        switch sentiment.lowercased() {
        case "positive", "joy", "happy":
            return 0.7
        case "very positive", "elated", "excited":
            return 1.0
        case "somewhat positive", "pleased":
            return 0.3
        case "neutral", "balanced":
            return 0.0
        case "somewhat negative", "concerned":
            return -0.3
        case "negative", "sad", "upset":
            return -0.7
        case "very negative", "distressed", "angry":
            return -1.0
        default:
            // Try to extract numeric value if present (e.g. "0.5" or "-0.2")
            if let numericValue = Double(sentiment) {
                return max(-1.0, min(1.0, numericValue)) // Clamp between -1 and 1
            }
            return 0.0 // Default to neutral if unknown
        }
    }
    
    // MARK: - Initialization
    
    init(persistenceManager: StoryPersistenceManager = .shared) {
        self.persistenceManager = persistenceManager
        
        // Load the user's preferred visualization style
        if let savedStyle = UserDefaults.standard.string(forKey: "visualization_style"),
           let style = VisualizationStyle(rawValue: savedStyle) {
            self.visualizationStyle = style
        }
        
        // Load initial data
        loadStoryMap()
    }
    
    // MARK: - Public Methods
    
    /// Loads the story map data
    func loadStoryMap() {
        isLoading = true
        errorMessage = nil
        
        // Fetch story nodes from persistence
        persistenceManager.getAllStoryNodes()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load story map: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] storyNodes in
                self?.processStoryNodes(storyNodes)
            }
            .store(in: &cancellables)
    }
    
    /// Selects a node for detailed viewing
    /// - Parameter nodeId: The ID of the node to select
    func selectNode(withId nodeId: String) {
        selectedNode = nodes.first { $0.id == nodeId }
    }
    
    /// Clears the currently selected node
    func clearSelectedNode() {
        selectedNode = nil
    }
    
    /// Applies the current filter criteria to the story map
    func applyFilter() {
        // Re-fetch and process nodes with the current filter
        loadStoryMap()
    }
    
    /// Clears all filters
    func clearFilters() {
        filterCriteria = StoryFilterCriteria()
        applyFilter()
    }
    
    /// Changes the visualization style
    /// - Parameter style: The new visualization style
    func changeVisualizationStyle(_ style: VisualizationStyle) {
        self.visualizationStyle = style
        
        // Save user preference
        UserDefaults.standard.set(style.rawValue, forKey: "visualization_style")
        
        // Re-layout nodes based on new style
        layoutNodes()
    }
    
    // MARK: - Private Methods
    
    /// Processes the story nodes retrieved from persistence
    /// - Parameter storyNodes: The array of story nodes
    private func processStoryNodes(_ storyNodes: [StoryNode]) {
        // First, filter nodes based on criteria if any
        let filteredNodes = filterNodes(storyNodes)
        
        // Transform to view models
        let newViewModels: [StoryNodeViewModel] = filteredNodes.compactMap { node in
            guard let chapter = persistenceManager.getChapter(id: node.chapterId) else {
                print("Warning: Could not find chapter with ID \(node.chapterId) for node \(node.id). Skipping view model creation.")
                return nil // Skip this node if its chapter is missing
            }
            return StoryNodeViewModel(node: node, chapter: chapter)
        }
        
        // Update the published properties on the main thread
        DispatchQueue.main.async {
            self.nodes = newViewModels
            self.buildConnections()
            self.layoutNodes()
        }
    }
    
    /// Builds connections between nodes
    private func buildConnections() {
        var nodeConnections: [StoryConnection] = []
        
        for node in nodes {
            if let parentId = node.node.parentId,
               let parentNode = nodes.first(where: { $0.id == parentId }) {
                let connection = StoryConnection(
                    id: UUID().uuidString,
                    sourceId: parentId,
                    targetId: node.id,
                    strength: calculateConnectionStrength(
                        parentMetadata: parentNode.node.metadataSnapshot,
                        childMetadata: node.node.metadataSnapshot
                    )
                )
                nodeConnections.append(connection)
            }
        }
        
        self.connections = nodeConnections
        
        // Layout nodes based on current visualization style
        layoutNodes()
    }
    
    /// Creates a node view model from a story node and its chapter
    /// - Parameters:
    ///   - node: The story node
    ///   - chapter: The story chapter
    /// - Returns: A configured StoryNodeViewModel
    private func createNodeViewModel(from node: StoryNode, chapter: StoryChapter) -> StoryNodeViewModel {
        return StoryNodeViewModel(node: node, chapter: chapter)
    }
    
    /// Filters nodes based on the current filter criteria
    /// - Parameter nodes: The array of nodes to filter
    /// - Returns: The filtered array of nodes
    private func filterNodes(_ nodes: [StoryNode]) -> [StoryNode] {
        return nodes.filter { node in
            var shouldInclude = true
            
            // Filter by date range if set
            if let startDate = filterCriteria.startDate {
                shouldInclude = shouldInclude && node.createdAt >= startDate
            }
            
            if let endDate = filterCriteria.endDate {
                shouldInclude = shouldInclude && node.createdAt <= endDate
            }
            
            // Filter by sentiment range
            if filterCriteria.minSentiment != -1 || filterCriteria.maxSentiment != 1 {
                // Convert string sentiment to numeric value for comparison
                let sentimentValue = node.metadataSnapshot?.sentimentScore ?? 0.0
                shouldInclude = shouldInclude && sentimentValue >= filterCriteria.minSentiment && sentimentValue <= filterCriteria.maxSentiment
            }
            
            // Filter by themes if any are selected
            if !filterCriteria.selectedThemes.isEmpty { // Corrected property name
                let nodeThemes = node.metadataSnapshot?.themes ?? []
                // Ensure all selected themes are present in the node's themes
                shouldInclude = shouldInclude && filterCriteria.selectedThemes.allSatisfy { selectedTheme in
                    nodeThemes.contains(selectedTheme)
                }
            }
            
            // Filter by search term if provided
            if let term = filterCriteria.searchTerm, !term.isEmpty {
                // Search in themes and entities
                let themeMatch = (node.metadataSnapshot?.themes ?? []).contains { $0.lowercased().contains(term.lowercased()) }
                let entityMatch = (node.metadataSnapshot?.entities ?? []).contains { $0.lowercased().contains(term.lowercased()) }
                
                shouldInclude = shouldInclude && (themeMatch || entityMatch)
            }
            
            return shouldInclude
        }
    }
    
    /// Layouts nodes based on the current visualization style
    private func layoutNodes() {
        switch visualizationStyle {
        case .timeline:
            applyTimelineLayout()
        case .tree:
            applyTreeLayout()
        case .cluster:
            applyClusterLayout()
        }
    }
    
    /// Applies a timeline layout to the nodes
    private func applyTimelineLayout() {
        // Sort nodes by creation date
        let sortedNodes = nodes.sorted { $0.node.createdAt < $1.node.createdAt }
        
        // Calculate time range
        guard let firstDate = sortedNodes.first?.node.createdAt,
              let lastDate = sortedNodes.last?.node.createdAt else {
            return
        }
        
        let _ = lastDate.timeIntervalSince(firstDate)
        let horizontalSpacing: CGFloat = 150
        let startX: CGFloat = 100
        let baseY: CGFloat = 300
        
        // Position nodes along a horizontal timeline
        for (index, node) in sortedNodes.enumerated() {
            if nodes.firstIndex(where: { $0.id == node.id }) != nil {
                // Calculate x position based on time
                let _ = node.node.createdAt.timeIntervalSince(firstDate)
                let _ = startX + CGFloat(index) * horizontalSpacing
                
                // Add some vertical variation based on sentiment
                let sentimentOffset = CGFloat(node.sentiment) * 100
                let _ = baseY + sentimentOffset
                
                // Update node position - Logic needs refactoring to store position externally
                // nodes[nodeIndex].position = CGPoint(x: xPosition, y: yPosition)
            }
        }
    }
    
    /// Applies a tree layout to the nodes
    private func applyTreeLayout() {
        // Identify root nodes (nodes without parents)
        let rootIds = Set(nodes.map { $0.id }).subtracting(connections.map { $0.targetId })
        
        // Start layout from root nodes
        // These values would be used when uncommenting the positioning code
        // let horizontalSpacing: CGFloat = 200
        // let verticalSpacing: CGFloat = 150
        // let startX: CGFloat = 400
        // let startY: CGFloat = 100
        
        var positionedNodes = Set<String>()
        var rowPositions: [Int: [String]] = [:]
        
        // Position root nodes first
        for (_, rootId) in rootIds.enumerated() {
            if nodes.firstIndex(where: { $0.id == rootId }) != nil {
                // Position needs to be stored externally
                // nodes[nodeIndex].position = CGPoint(
                //     x: startX + CGFloat(index) * horizontalSpacing,
                //     y: startY
                // )
                positionedNodes.insert(rootId)
                
                // Track row positions
                if rowPositions[0] == nil {
                    rowPositions[0] = []
                }
                rowPositions[0]?.append(rootId)
            }
        }
        
        // Position remaining nodes level by level
        var currentRow = 1
        while positionedNodes.count < nodes.count {
            let nodesInCurrentRow = nodes.filter { node in
                // Node is not positioned yet
                !positionedNodes.contains(node.id) &&
                // Node's parent is in the previous row
                connections.contains { conn in
                    conn.targetId == node.id &&
                    positionedNodes.contains(conn.sourceId) &&
                    rowPositions[currentRow - 1]?.contains(conn.sourceId) ?? false
                }
            }
            
            if nodesInCurrentRow.isEmpty {
                // No more nodes to position this way
                break
            }
            
            // Position nodes in this row
            rowPositions[currentRow] = []
            for (_, node) in nodesInCurrentRow.enumerated() {
                // Find parent position
                let parentConn = connections.first { $0.targetId == node.id && positionedNodes.contains($0.sourceId) }
                let _ = nodes.firstIndex { $0.id == parentConn?.sourceId }
                // let parentPosition = parentIndex.map { nodes[$0].position } ?? CGPoint(x: startX, y: startY)
                // Temporary default - removed since unused
                // let parentPosition = CGPoint.zero
                
                // Position based on parent
                if nodes.firstIndex(where: { $0.id == node.id }) != nil {
                    // nodes[nodeIndex].position = CGPoint(
                    //     x: parentPosition.x + CGFloat(index - nodesInCurrentRow.count / 2) * (horizontalSpacing / 2),
                    //     y: startY + CGFloat(currentRow) * verticalSpacing
                    // )
                    positionedNodes.insert(node.id)
                    rowPositions[currentRow]?.append(node.id)
                }
            }
            
            currentRow += 1
        }
        
        // Position any remaining nodes in a fallback layout
        for node in nodes {
            if !positionedNodes.contains(node.id) {
                if nodes.firstIndex(where: { $0.id == node.id }) != nil {
                    // Fallback position needs to be stored externally
                    // nodes[nodeIndex].position = CGPoint(
                    //     x: startX + CGFloat.random(in: -200...200),
                    //     y: startY + CGFloat.random(in: 0...400)
                    // )
                }
            }
        }
    }
    
    /// Applies a cluster layout based on themes
    private func applyClusterLayout() {
        // Group nodes by primary theme
        var themeGroups: [String: [StoryNodeViewModel]] = [:]
        
        for node in nodes {
            // Theme grouping is commented out in the current implementation
            // let primaryTheme = node.themes.first ?? "Unknown"
            if themeGroups["Unknown"] == nil {
                themeGroups["Unknown"] = []
            }
            themeGroups["Unknown"]?.append(node)
        }
        
        // Position nodes in clusters by theme
        let clusterRadius: CGFloat = 150
        let centerX: CGFloat = 400
        let centerY: CGFloat = 300
        let clusterSpacing: CGFloat = 350
        
        var clusterPositions: [CGPoint] = []
        let clusterCount = themeGroups.count
        
        // Calculate cluster center positions in a circle
        for i in 0..<clusterCount {
            let angle = (2 * CGFloat.pi * CGFloat(i)) / CGFloat(clusterCount)
            let x = centerX + cos(angle) * clusterSpacing
            let y = centerY + sin(angle) * clusterSpacing
            clusterPositions.append(CGPoint(x: x, y: y))
        }
        
        // Position nodes within each cluster
        var clusterIndex = 0
        for (_, clusterNodes) in themeGroups {
            let clusterCenter = clusterPositions[clusterIndex]
            
            for (i, node) in clusterNodes.enumerated() {
                if nodes.contains(where: { $0.id == node.id }) {
                    // Position in a spiral within the cluster
                    let nodeAngle = (2 * CGFloat.pi * CGFloat(i)) / CGFloat(clusterNodes.count)
                    let distanceFromCenter = min(CGFloat(i) * 20, clusterRadius)
                    
                    // These would be used when uncommenting the positioning code
                    let _ = clusterCenter.x + cos(nodeAngle) * distanceFromCenter
                    let _ = clusterCenter.y + sin(nodeAngle) * distanceFromCenter
                    
                    // Position needs to be stored externally
                    // nodes[nodeIndex].position = CGPoint(x: xPos, y: yPos)
                }
            }
            
            clusterIndex = (clusterIndex + 1) % clusterCount
        }
    }
    
    /// Calculates the strength of connection between two nodes
    /// - Parameters:
    ///   - parentMetadata: Metadata of the parent node (StoryMetadata)
    ///   - childMetadata: Metadata of the child node (StoryMetadata)
    /// - Returns: A connection strength value between 0 and 1
    private func calculateConnectionStrength(
        parentMetadata: StoryMetadata?,
        childMetadata: StoryMetadata?
    ) -> Double {
        // Calculate theme similarity
        let parentThemes = Set(parentMetadata?.themes ?? [])
        let childThemes = Set(childMetadata?.themes ?? [])
        let themeOverlap = parentThemes.intersection(childThemes).count
        let themeUnion = parentThemes.union(childThemes).count
        let themeSimilarity = themeUnion > 0 ? Double(themeOverlap) / Double(themeUnion) : 0.0

        // Calculate sentiment similarity
        // Assuming sentimentScore is normalized between -1.0 (very negative) and 1.0 (very positive)
        // Default to 0.0 (neutral) if nil
        let parentSentiment = parentMetadata?.sentimentScore ?? 0.0
        let childSentiment = childMetadata?.sentimentScore ?? 0.0
        
        // Difference ranges from 0 (identical) to 2.0 (opposite extremes)
        let sentimentDifference = abs(parentSentiment - childSentiment)
        // Normalize difference to similarity (1.0 for identical, 0.0 for opposite extremes)
        let sentimentSimilarity = 1.0 - (sentimentDifference / 2.0) 

        // Weighted average, e.g., 70% theme, 30% sentiment
        let weightedStrength = 0.7 * themeSimilarity + 0.3 * sentimentSimilarity
        
        // Ensure the final value is clamped between 0.0 and 1.0
        return max(0.0, min(1.0, weightedStrength))
    }
}

// MARK: - Supporting Types

/// Represents a connection between two story nodes
struct StoryConnection: Identifiable {
    let id: String
    let sourceId: String
    let targetId: String
    let strength: Double
}

/// Visualization styles for the story map
enum VisualizationStyle: String, CaseIterable {
    case timeline = "Timeline"
    case tree = "Tree"
    case cluster = "Cluster"
}

/// Criteria for filtering the story map
struct StoryFilterCriteria {
    var startDate: Date? = nil
    var endDate: Date? = nil
    var minSentiment: Double = -1.0
    var maxSentiment: Double = 1.0
    var selectedThemes: [String] = []
    var searchTerm: String? = nil
}
