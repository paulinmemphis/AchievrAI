// StoryMapView.swift
import SwiftUI
import Combine

/// A view model for the StoryMapView to handle data fetching and state management.
class StoryMapViewModel: ObservableObject {
    @Published var storyNodes: [StoryNode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedNodeId: UUID?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: NarrativeAPIService
    
    // Defer loading to prevent startup issues
    private var hasInitiallyLoaded = false
    
    init(apiService: NarrativeAPIService = NarrativeAPIService()) {
        self.apiService = apiService
        // Don't immediately load nodes - wait until view appears
    }
    
    // Call this method when the view appears to safely load data
    func loadIfNeeded() {
        if !hasInitiallyLoaded {
            hasInitiallyLoaded = true
            loadStoryNodes()
        }
    }
    
    func loadStoryNodes() {
        isLoading = true
        errorMessage = nil
        
        // Using a placeholder user ID for now; in a real app, you'd get this from user authentication
        let userId = "user-placeholder"
        
        apiService.fetchStoryNodes(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] nodes in
                self?.storyNodes = nodes
            })
            .store(in: &cancellables)
    }
    
    /// Returns story nodes arranged in a tree structure
    /// Each level contains nodes at the same depth
    func arrangedNodes() -> [[StoryNode]] {
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
    
    /// Select a story node to view
    func selectNode(_ nodeId: UUID) {
        selectedNodeId = nodeId
    }
    
    /// Clear the selected node
    func clearSelection() {
        selectedNodeId = nil
    }
    
    /// Get a node by its ID
    func node(for id: UUID) -> StoryNode? {
        return storyNodes.first(where: { $0.id == id })
    }
}

/// A zoomable and pannable view for displaying story nodes in a tree structure
struct StoryMapView: View {
    @StateObject private var viewModel = StoryMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            // Background
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading your story...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("Error loading story")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        viewModel.loadStoryNodes()
                    }
                    .padding(.top)
                }
                .padding()
            } else if viewModel.storyNodes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Your story hasn't begun yet")
                        .font(.headline)
                    Text("Create journal entries to start your personal narrative")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                // Zoomable, pannable content
                storyTreeView
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                // Limit scale between 0.5 and 3.0
                                scale = min(max(scale * delta, 0.5), 3.0)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                
                // Reset button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .padding(12)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Your Story Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { 
            viewModel.selectedNodeId.map { IdentifiableUUID($0) }
        }, set: { 
            viewModel.selectedNodeId = $0?.id 
        })) { wrappedId in
            if let node = viewModel.node(for: wrappedId.id) {
                ChapterView(chapter: node.chapter)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            // Load nodes when view appears
            viewModel.loadIfNeeded()
        }
    }
    
    // View for displaying nodes in a tree structure
    private var storyTreeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                ForEach(viewModel.arrangedNodes().indices, id: \.self) { levelIndex in
                    let level = viewModel.arrangedNodes()[levelIndex]
                    
                    HStack(spacing: 20) {
                        ForEach(level) { node in
                            StoryNodeView(
                                node: node,
                                onTap: { viewModel.selectNode(node.id) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

/// A visual representation of a single story node
struct StoryNodeView: View {
    let node: StoryNode
    let onTap: () -> Void
    
    // Determine node color based on sentiment
    private var nodeColor: Color {
        switch node.metadata.sentiment.lowercased() {
        case "positive", "happy", "hopeful":
            return .green
        case "negative", "sad", "depressed":
            return .blue
        case "angry", "furious":
            return .red
        case "tense", "anxious", "nervous":
            return .orange
        default:
            return .purple // Default for neutral or unknown sentiment
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Node header with chapter ID and date
            HStack {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 12, height: 12)
                
                Text("Chapter \(node.chapterId.suffix(1))")
                    .font(.caption)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(node.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Node content
            VStack(alignment: .leading, spacing: 8) {
                // Key themes
                if !node.metadata.themes.isEmpty {
                    HStack {
                        ForEach(node.metadata.themes.prefix(2), id: \.self) { theme in
                            Text(theme)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(nodeColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Cliffhanger preview
                Text(node.chapter.cliffhanger)
                    .font(.caption)
                    .italic()
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Helper Extensions

// The IdentifiableUUID struct is now defined in IdentifiableUUID.swift

// MARK: - Preview
struct StoryMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoryMapView()
                .environmentObject(ThemeManager())
        }
    }
}
