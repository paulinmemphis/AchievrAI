// StoryVisualizationComponents.swift
import SwiftUI

// Use the shared StoryNode type directly
import Foundation

/// Defines the different visualization modes for story content
enum StoryViewMode: String, CaseIterable, Identifiable {
    case map = "Map"
    case timeline = "Timeline"
    case list = "List"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .map: return "map"
        case .timeline: return "timeline.selection"
        case .list: return "list.bullet"
        }
    }
}

/// A filter bar for the StoryMapView
struct StoryFilterBar: View {
    @Binding var viewMode: StoryViewMode
    @Binding var sentimentFilter: String?
    @Binding var searchText: String
    @EnvironmentObject private var themeManager: ThemeManager
    
    let sentiments = ["All", "Positive", "Negative", "Neutral", "Tense", "Hopeful"]
    
    var body: some View {
        VStack(spacing: 12) {
            // View mode selector
            HStack {
                Text("View:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("View Mode", selection: $viewMode) {
                    ForEach(StoryViewMode.allCases) { mode in
                        HStack {
                            Image(systemName: mode.iconName)
                            Text(mode.rawValue)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Search and filter
            HStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search themes, entities...", text: $searchText)
                        .font(.subheadline)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                
                // Filter menu
                Menu {
                    ForEach(sentiments, id: \.self) { sentiment in
                        Button(action: {
                            sentimentFilter = sentiment == "All" ? nil : sentiment.lowercased()
                        }) {
                            HStack {
                                Text(sentiment)
                                if sentiment == "All" && sentimentFilter == nil ||
                                    sentiment.lowercased() == sentimentFilter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(sentimentFilter == nil ? "All" : sentimentFilter!.capitalized)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

/// A timeline visualization for story nodes
struct StoryTimelineView: View {
    let storyNodes: [StoryNode]
    let onSelectNode: (String) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Order story nodes chronologically
    var sortedNodes: [StoryNode] {
        storyNodes.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortedNodes.indices, id: \.self) { index in
                    let node = sortedNodes[index]
                    timelineItem(for: node, index: index, isLast: index == sortedNodes.count - 1)
                }
            }
            .padding()
        }
    }
    
    // Timeline entry for a single node
    private func timelineItem(for node: StoryNode, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline connector
            VStack {
                Circle()
                    .fill(sentimentColor(for: node.metadata.sentiment))
                    .frame(width: 16, height: 16)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2)
                }
            }
            .frame(width: 20)
            
            // Node content
            VStack(alignment: .leading, spacing: 8) {
                // Date and title
                HStack {
                    Text(node.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Chapter \(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sentimentColor(for: node.metadata.sentiment).opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Content card
                VStack(alignment: .leading, spacing: 10) {
                    // Themes
                    if !node.metadata.themes.isEmpty {
                        HStack {
                            ForEach(node.metadata.themes.prefix(2), id: \.self) { theme in
                                Text(theme)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Preview of text
                    if let chapter = StoryPersistenceManager.shared.getChapter(id: node.chapterId) {
                        Text(chapter.cliffhanger)
                            .font(.body)
                            .italic()
                            .lineLimit(2)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        onSelectNode(node.id)
                    }) {
                        Text("Read Chapter")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .padding(.bottom, 16)
            }
            .padding(.leading, 16)
        }
    }
    
    // Helper to determine color based on sentiment
    private func sentimentColor(for sentiment: String) -> Color {
        switch sentiment.lowercased() {
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
}

/// A list visualization for story nodes
struct StoryListView: View {
    let storyNodes: [StoryNode]
    let onSelectNode: (String) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Order story nodes chronologically
    var sortedNodes: [StoryNode] {
        storyNodes.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        List {
            ForEach(sortedNodes.indices, id: \.self) { index in
                let node = sortedNodes[index]
                listItem(for: node, index: index)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectNode(node.id)
                    }
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // List item for a single node
    private func listItem(for node: StoryNode, index: Int) -> some View {
        HStack(spacing: 12) {
            // Chapter number circle
            VStack {
                Text("\(index + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(sentimentColor(for: node.metadata.sentiment))
                    .clipShape(Circle())
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Date
                Text(node.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Cliffhanger preview
                if let chapter = StoryPersistenceManager.shared.getChapter(id: node.chapterId) {
                    Text(chapter.cliffhanger)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                // Themes
                if !node.metadata.themes.isEmpty {
                    HStack {
                        ForEach(node.metadata.themes.prefix(3), id: \.self) { theme in
                            Text(theme)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // Helper to determine color based on sentiment
    private func sentimentColor(for sentiment: String) -> Color {
        switch sentiment.lowercased() {
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
}
