// StoryMapView.swift
//
// Depends on:
//   - StoryNode: see StoryPersistenceManager.swift
//   - IdentifiableUUID: see IdentifiableUUID.swift
//   - ThemeManager: see ThemeManager.swift
//   - NarrativeAPIService: see NarrativeAPIService.swift
//
// Navigation: This view currently mixes NavigationLink and .sheet for navigation. For best UX, consider adopting a consistent navigation pattern throughout the app.
import SwiftUI
import Combine

// Using IdentifiableUUID from IdentifiableUUID.swift

// Duplicate EnhancedStoryMapViewModel removed, using the one from EnhancedStoryMapViewModel.swift

/// A zoomable and pannable view for displaying story nodes in a tree structure
struct StoryMapView: View {
    @StateObject private var viewModel = EnhancedStoryMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var coordinator: PsychologicalEnhancementsCoordinator // Added coordinator
    @StateObject private var analyzer = MetacognitiveAnalyzer() // Add analyzer for AIJournalEntryView
    
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
                        viewModel.loadStoryNodes { _ in }
                    }
                    .padding(.top)
                }
                .padding()
            } else if viewModel.storyNodes.isEmpty {
                emptyStoryStateView
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
            viewModel.selectedNodeId.map { IdentifiableString(id: $0) }
        }, set: { 
            viewModel.selectedNodeId = $0?.id 
        })) { wrapper in
            // Find the selected ViewModel
            if let selectedNodeViewModel = viewModel.nodeViewModels.first(where: { $0.id == wrapper.id }) {
                // Initialize ChapterView directly with the StoryNodeViewModel
                ChapterView(
                    nodeViewModel: selectedNodeViewModel // Pass the correct view model
                )
                .environmentObject(themeManager)
            } else {
                Text("Error: Node details not found.") // Fallback
            }
        }
        .onAppear {
            // Load nodes using the ViewModel
            viewModel.loadIfNeeded()
        }
    }

    // MARK: - Empty State View
    private var emptyStoryStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars") // Or a custom illustration
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Your Story Awaits!")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Create your first journal entry to begin generating your personalized story.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Navigate to the view for creating a new entry
            NavigationLink(destination: AIJournalEntryView()
                            .environmentObject(journalStore)
                            .environmentObject(analyzer)
                            .environmentObject(themeManager)
                            .environmentObject(coordinator)) {
                Text("Start your first entry")
                    .fontWeight(.semibold)
                    .padding()
            }
        }
        .padding()
    }
                
    // MARK: - Story Tree View
    private var storyTreeView: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .center, spacing: 60) {
                // Iterate over nodeViewModels instead of storyNodes
                ForEach(viewModel.nodeViewModels) { nodeViewModel in 
                    // Pass the nodeViewModel to StoryNodeView
                    StoryNodeView(nodeViewModel: nodeViewModel) { 
                        viewModel.selectedNodeId = nodeViewModel.id // Update selection
                    }
                    // Explicitly add background based on selection state
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(nodeViewModel.id == viewModel.selectedNodeId ? themeManager.selectedTheme.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                    )
                    .overlay(
                         RoundedRectangle(cornerRadius: 12)
                            .stroke(nodeViewModel.id == viewModel.selectedNodeId ? themeManager.selectedTheme.accentColor : Color.clear, lineWidth: 2)
                    )
                }
            }
            .padding(80) // Extra padding for zooming and panning
        }
    }
}

// Identifiable wrapper for sheet
struct IdentifiableString: Identifiable {
    var id: String
}

// MARK: - StoryNodeView
struct StoryNodeView: View {
    // Expect StoryNodeViewModel instead of StoryNode
    let nodeViewModel: StoryNodeViewModel 
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Node header with title and date from ViewModel
            HStack {
                Circle()
                    .fill(nodeViewModel.sentimentColor) // Use sentimentColor from ViewModel
                    .frame(width: 12, height: 12)
                Text(nodeViewModel.title) // Use title from ViewModel
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text(nodeViewModel.node.createdAt, style: .date) // Use creationDate from ViewModel
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            // Node content
            VStack(alignment: .leading, spacing: 8) {
                // Key themes from ViewModel
                if !nodeViewModel.themes.isEmpty { // Use themes from ViewModel
                    HStack {
                        ForEach(nodeViewModel.themes.prefix(2), id: \.self) { theme in // Use themes from ViewModel
                            Text(theme)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(nodeViewModel.sentimentColor.opacity(0.2)) // Use sentimentColor from ViewModel
                                .cornerRadius(4)
                        }
                    }
                }
                // Chapter preview from ViewModel
                Text(nodeViewModel.chapterPreview) // Use chapterPreview from ViewModel
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

// MARK: - Preview
struct StoryMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoryMapView()
                .environmentObject(ThemeManager())
                .environmentObject(JournalStore())
                .environmentObject(PsychologicalEnhancementsCoordinator()) // Added coordinator
        }
    }
}
