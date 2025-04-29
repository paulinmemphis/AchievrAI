// EnhancedStoryMapView_Fixed.swift
import SwiftUI

/// An enhanced story map view with multiple visualization modes and narrative arcs
struct EnhancedStoryMapView: View {
    @StateObject private var viewModel = EnhancedStoryMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    // UI state
    @State private var showingThemeSelector = false
    @State private var showingInfoOverlay = false
    @State private var showingSettingsPanel = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            // Main content
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.storyNodes.isEmpty {
                emptyStateView
            } else {
                mainContentView
            }
        }
        .navigationTitle("Story Map")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingInfoOverlay = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingThemeSelector = true
                }) {
                    Image(systemName: "paintpalette")
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettingsPanel = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                }
            }
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView(themeManager: themeManager)
        }
        .sheet(item: $viewModel.selectedNodeId) { nodeId in
            if let node = viewModel.node(for: nodeId) {
                ChapterView(chapter: node.chapter)
                    .environmentObject(themeManager)
            }
        }
        .sheet(isPresented: $showingSettingsPanel) {
            SettingsPanel(viewModel: viewModel)
        }
        .overlay {
            if showingInfoOverlay {
                infoOverlay
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onChange(of: themeManager.selectedTheme) { oldValue, newValue in
            // Refresh the view when theme changes
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView("Loading your story...")
                .progressViewStyle(CircularProgressViewStyle())
                .foregroundColor(Color.primary)
            
            Text("Building your narrative map...")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
    
    // Error view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            Text("Error loading story")
                .font(.headline)
                .foregroundColor(Color.primary)
            Text(message)
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                viewModel.loadStoryData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 30))
                .foregroundColor(themeManager.selectedTheme.imageColor)
            Text("Your story hasn't begun yet")
                .font(.headline)
                .foregroundColor(Color.primary)
            Text("Create journal entries to start your personal narrative")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            NavigationLink(destination: AIJournalEntryView()) {
                Text("Create Journal Entry")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // Main visualization content
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Mode selector at top
            modeSelectorView
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.9))
            
            // Visualization takes remaining space
            ZStack {
                // Content changes based on visualization mode
                Group {
                    if viewModel.visualMode == .tree {
                        treeVisualView
                    } else if viewModel.visualMode == .timeline {
                        timelineVisualView
                    } else if viewModel.visualMode == .thematic {
                        thematicVisualView
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            // Limit zoom range
                            scale = min(max(scale * delta, 0.5), 3.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                .gesture(
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
                
                // Controls overlay
                VStack {
                    Spacer()
                    
                    HStack {
                        // Theme filter
                        Menu {
                            Button("All Themes") {
                                viewModel.highlightedTheme = nil
                            }
                            
                            Divider()
                            
                            ForEach(viewModel.allThemes, id: \.self) { theme in
                                Button(theme) {
                                    viewModel.highlightedTheme = theme
                                }
                            }
                        } label: {
                            Label(
                                viewModel.highlightedTheme ?? "All Themes",
                                systemImage: "tag"
                            )
                            .padding(8)
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Reset view
                        Button {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .padding(8)
                                .background(Color(.systemBackground).opacity(0.8))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // Mode selector view
    private var modeSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(EnhancedStoryMapViewModel.VisualizationMode.allCases) { mode in
                Button(action: {
                    withAnimation {
                        viewModel.visualMode = mode
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: mode.iconName)
                            .foregroundColor(themeManager.selectedTheme.imageColor)
                            .font(.system(size: 16))
                        Text(mode.rawValue)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        viewModel.visualMode == mode
                            ? Color.blue.opacity(0.2)
                            : Color.clear
                    )
                    .cornerRadius(8)
                    .foregroundColor(
                        viewModel.visualMode == mode
                            ? Color.blue
                            : Color.primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if mode != EnhancedStoryMapViewModel.VisualizationMode.allCases.last {
                    Divider()
                        .frame(height: 24)
                }
            }
        }
    }
    
    // Tree visualization view
    private var treeVisualView: some View {
        Text("Tree View")
    }
    
    // Timeline visualization view
    private var timelineVisualView: some View {
        Text("Timeline View")
    }
    
    // Thematic visualization view
    private var thematicVisualView: some View {
        Text("Thematic View")
    }
    
    // Information overlay
    private var infoOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingInfoOverlay = false
                    }
                }
            
            VStack(spacing: 24) {
                Text("How to Use the Story Map")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    infoItem(
                        icon: "square.grid.3x3",
                        title: "Tree View",
                        description: "Visualize your story as a tree with connections between related chapters."
                    )
                    
                    infoItem(
                        icon: "arrow.left.arrow.right",
                        title: "Timeline View",
                        description: "See your story chapters arranged chronologically from oldest to newest."
                    )
                    
                    infoItem(
                        icon: "tag",
                        title: "Thematic View",
                        description: "Group chapters by shared themes to discover patterns in your narrative."
                    )
                    
                    infoItem(
                        icon: "hand.tap",
                        title: "Interact",
                        description: "Tap nodes to view chapters. Pinch to zoom, drag to pan, and use buttons to filter or reset."
                    )
                }
                
                Button {
                    withAnimation {
                        showingInfoOverlay = false
                    }
                } label: {
                    Text("Got it!")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(24)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .padding(24)
        }
    }
    
    // Helper for info overlay items
    private func infoItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .padding(.bottom, 4)
                .foregroundColor(themeManager.selectedTheme.imageColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.secondary)
            }
        }
    }
}

// MARK: - Helper Views

/// Theme button style
struct ThemeButton: View {
    let theme: ThemeManager.Theme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 20, height: 20)
                
                Text(theme.rawValue)
                    .foregroundColor(Color.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
    }
}

/// Theme selector view
struct ThemeSelectorView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ThemeManager.Theme.allCases) { theme in
                    ThemeButton(
                        theme: theme,
                        isSelected: themeManager.selectedTheme == theme,
                        action: {
                            themeManager.setTheme(theme)
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Select Theme")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// Settings panel for visualization options
struct SettingsPanel: View {
    @ObservedObject var viewModel: EnhancedStoryMapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Options")) {
                    Toggle("Show Arc Labels", isOn: $viewModel.showingArcLabels)
                    
                    Picker("Visualization Mode", selection: $viewModel.visualMode) {
                        ForEach(EnhancedStoryMapViewModel.VisualizationMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                Section(header: Text("Theme Filtering")) {
                    Button("Show All Themes") {
                        viewModel.highlightedTheme = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    ForEach(viewModel.allThemes, id: \.self) { theme in
                        Button(theme) {
                            viewModel.highlightedTheme = theme
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Story Map Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct EnhancedStoryMapView_Previews: PreviewProvider {
    static let previewThemeManager = ThemeManager()
    
    static var previews: some View {
        NavigationView {
            EnhancedStoryMapView()
                .environmentObject(previewThemeManager)
        }
        .previewDisplayName("Default View")
    }
}
