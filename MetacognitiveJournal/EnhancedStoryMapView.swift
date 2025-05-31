import SwiftUI
import Combine

/// An enhanced visualization view for displaying a user's narrative journey
struct EnhancedStoryMapView: View {
    // MARK: - Properties
    @StateObject private var viewModel = EnhancedStoryMapViewModel() // Correct ViewModel type
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var showNodeDetails = false
    @State private var selectedNodeID: String? = nil
    @State private var showingNewEntrySheet = false
    @State private var showingStorySettings = false
    
    // Environment objects
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject var psychologicalEnhancementsCoordinator: PsychologicalEnhancementsCoordinator
    @EnvironmentObject var narrativeEngineManager: NarrativeEngineManager
    @EnvironmentObject var journalStore: JournalStore
    
    // Create a MetacognitiveAnalyzer for AIJournalEntryView
    @StateObject private var analyzer = MetacognitiveAnalyzer()
    
    // Node positions (in a real implementation, these would be calculated dynamically)
    @State private var nodePositions: [String: CGPoint] = [:]
    
    // MARK: - Constants
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 2.5
    
    // MARK: - Body
    var body: some View {
        ZStack {
            content
        }
        .withPsychologicalEnhancements(psychologicalEnhancementsCoordinator)
        .sheet(isPresented: $showingNewEntrySheet) {
            NavigationView {
                AIJournalEntryView()
                    .environmentObject(themeManager)
                    .environmentObject(psychologicalEnhancementsCoordinator)
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
            }
        }
        .sheet(isPresented: $showingStorySettings) {
            StorySettingsView()
                .environmentObject(themeManager)
                .environmentObject(narrativeEngineManager)
        }
        .sheet(isPresented: $narrativeEngineManager.showGenreSelection) {
            GenreSelectionView(
                selectedGenre: $narrativeEngineManager.defaultGenre,
                isPresented: $narrativeEngineManager.showGenreSelection
            )
        }
        .onAppear {
            // Load story data when the view appears
            viewModel.loadIfNeeded()
            
            // Initialize node positions (in a real implementation, these would be calculated based on the story structure)
            calculateNodePositions()
        }
    }

    // Extracted content for clarity
    private var content: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                themeManager.selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                // Map content with zoom and pan
                mapContent
                    .scaleEffect(zoomScale)
                    .offset(offset)
                    .gesture(dragGesture)
                    .gesture(magnificationGesture)
                
                // Overlay controls
                VStack {
                    HStack {
                        // Settings button
                        Button(action: { showingStorySettings = true }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .padding()
                                .background(Circle().fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.8)))
                                .shadow(radius: 3)
                        }
                        
                        Spacer()
                        
                        // Zoom controls
                        HStack(spacing: 15) {
                            Button(action: { zoomOut() }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2)
                                    .padding()
                                    .background(Circle().fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.8)))
                                    .shadow(radius: 3)
                            }
                            
                            Button(action: { resetZoom() }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .padding()
                                    .background(Circle().fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.8)))
                                    .shadow(radius: 3)
                            }
                            
                            Button(action: { zoomIn() }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2)
                                    .padding()
                                    .background(Circle().fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.8)))
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Add new entry button
                    Button(action: { showingNewEntrySheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Journal Entry")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(themeManager.selectedTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
    }
    
    // The actual map visualization
    private var mapContent: some View {
        VStack {
            if viewModel.nodeViewModels.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.nodeViewModels) { node in
                    storyNodeView(for: node)
                        .position(nodePositions[node.id] ?? CGPoint(x: 100, y: 100))
                        .onTapGesture {
                            selectedNodeID = node.id
                            showNodeDetails = true
                        }
                }
                
                // Draw connections between nodes
                ForEach(viewModel.nodeConnections, id: \.id) { connection in
                    connectionLine(from: connection.source, to: connection.target)
                }
            }
        }
        .frame(width: 2000, height: 2000) // Large canvas for panning
        .sheet(isPresented: $showNodeDetails) {
            if let nodeID = selectedNodeID, let node = viewModel.nodeViewModels.first(where: { $0.id == nodeID }) {
                NodeDetailView(node: node)
                    .environmentObject(themeManager)
            }
        }
    }
    
    // View for an empty story map
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 70))
                .foregroundColor(themeManager.selectedTheme.accentColor)
            
            Text("Your Story Map is Empty")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Start your journey by creating your first journal entry")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: { showingNewEntrySheet = true }) {
                Text("Create First Entry")
                    .fontWeight(.semibold)
                    .padding()
                    .background(themeManager.selectedTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackgroundColor)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // View for a story node
    private func storyNodeView(for node: StoryNodeViewModel) -> some View {
        VStack(spacing: 8) {
            // Node icon with sentiment color
            ZStack {
                Circle()
                    .fill(node.sentimentColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "book.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            
            // Node title
            Text(node.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .padding(10)
        .background(themeManager.selectedTheme.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
    
    // Line connecting nodes
    private func connectionLine(from source: String, to target: String) -> some View {
        GeometryReader { geometry in
            Path { path in
                guard let sourcePoint = nodePositions[source],
                      let targetPoint = nodePositions[target] else {
                    return
                }
                
                path.move(to: sourcePoint)
                path.addLine(to: targetPoint)
            }
            .stroke(themeManager.selectedTheme.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 5]))
        }
    }
    
    // Calculate positions for nodes (in a real implementation, this would be more sophisticated)
    private func calculateNodePositions() {
        // Simple layout algorithm - position nodes in a grid
        let nodeViewModels = viewModel.nodeViewModels
        let columns = 3
        let spacing: CGFloat = 200
        
        for (index, node) in nodeViewModels.enumerated() {
            let row = index / columns
            let col = index % columns
            let x = CGFloat(col) * spacing + 500
            let y = CGFloat(row) * spacing + 500
            
            nodePositions[node.id] = CGPoint(x: x, y: y)
        }
    }
    
    // MARK: - Gestures
    
    // Pan gesture for moving the map
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                lastOffset = offset
            }
    }
    
    // Pinch gesture for zooming
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = zoomScale * value.magnitude
                zoomScale = min(max(newScale, minScale), maxScale)
            }
    }
    
    // MARK: - Helper Methods
    
    private func zoomIn() {
        withAnimation {
            zoomScale = min(zoomScale * 1.2, maxScale)
        }
    }
    
    private func zoomOut() {
        withAnimation {
            zoomScale = max(zoomScale * 0.8, minScale)
        }
    }
    
    private func resetZoom() {
        withAnimation {
            zoomScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

// Simple node detail view
struct NodeDetailView: View {
    let node: StoryNodeViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(node.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Sentiment indicator
                    Circle()
                        .fill(node.sentimentColor)
                        .frame(width: 20, height: 20)
                }
                
                Divider()
                
                // Chapter preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chapter Preview")
                        .font(.headline)
                    
                    Text(node.chapterPreview)
                        .font(.body)
                        .lineSpacing(5)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                // Themes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Themes")
                        .font(.headline)
                    
                    if node.themes.isEmpty {
                        Text("No themes identified")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(node.themes, id: \.self) { theme in
                                    Text(theme)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(themeManager.selectedTheme.accentColor.opacity(0.2))
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                
                // Entry preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Journal Entry")
                        .font(.headline)
                    
                    Text(node.chapterPreview)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata")
                        .font(.headline)
                    
                    HStack {
                        Text("Created:")
                            .fontWeight(.medium)
                        Text(node.node.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Genre:")
                            .fontWeight(.medium)
                        Text(node.themes.first ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sentiment:")
                            .fontWeight(.medium)
                        Text(String(format: "%.2f", node.sentiment))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.selectedTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct EnhancedStoryMapView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedStoryMapView()
            .environmentObject(ThemeManager())
            .environmentObject(PsychologicalEnhancementsCoordinator())
            .environmentObject(NarrativeEngineManager())
            .environmentObject(JournalStore())
    }
}
