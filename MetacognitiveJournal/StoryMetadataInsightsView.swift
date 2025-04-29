// StoryMetadataInsightsView.swift
import SwiftUI

/// A view that displays insights and patterns from the story metadata
struct StoryMetadataInsightsView: View {
    let storyNodes: [StoryNode]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Story Insights")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Emotional journey visualization
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotional Journey")
                        .font(.headline)
                    
                    emotionalJourneyChart()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Recurring themes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recurring Themes")
                        .font(.headline)
                    
                    let themeFrequency = calculateThemeFrequency()
                    ForEach(Array(themeFrequency.keys.sorted().prefix(5)), id: \.self) { theme in
                        ThemeProgressView(
                            theme: theme,
                            count: themeFrequency[theme] ?? 0,
                            maxCount: themeFrequency.values.max() ?? 1
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Key characters/entities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Characters & Elements")
                        .font(.headline)
                    
                    let entityFrequency = calculateEntityFrequency()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(Array(entityFrequency.keys.sorted().prefix(6)), id: \.self) { entity in
                            EntityBubbleView(entity: entity, count: entityFrequency[entity] ?? 0)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Story stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Story Statistics")
                        .font(.headline)
                    
                    HStack {
                        StatisticView(
                            title: "Chapters",
                            value: "\(storyNodes.count)",
                            icon: "book"
                        )
                        
                        StatisticView(
                            title: "Word Count",
                            value: "\(calculateTotalWordCount())",
                            icon: "text.word.count"
                        )
                        
                        StatisticView(
                            title: "Timeline",
                            value: calculateTimelineSpan(),
                            icon: "calendar"
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Story Insights")
        .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
    }
    
    // MARK: - Chart Views
    
    private func emotionalJourneyChart() -> some View {
        // Sort nodes chronologically
        let sortedNodes = storyNodes.sorted { $0.timestamp < $1.timestamp }
        
        return VStack {
            // Chart header - labels
            HStack {
                Text("Positive")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Neutral")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("Negative")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // Chart visualization
            ZStack(alignment: .leading) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Divider()
                        Spacer()
                    }
                    Divider()
                }
                
                // Plot points and lines
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let chartWidth = width - 20
                    let chartHeight = height - 20
                    
                    // Create path for the sentiment line
                    Path { path in
                        guard !sortedNodes.isEmpty else { return }
                        
                        let pointSpacing = chartWidth / CGFloat(max(1, sortedNodes.count - 1))
                        
                        // Start point
                        let firstY = calculateYPosition(for: sortedNodes[0].metadata.sentiment, height: chartHeight)
                        path.move(to: CGPoint(x: 10, y: firstY + 10))
                        
                        // Draw lines to each point
                        for i in 1..<sortedNodes.count {
                            let pointX = 10 + pointSpacing * CGFloat(i)
                            let pointY = calculateYPosition(for: sortedNodes[i].metadata.sentiment, height: chartHeight) + 10
                            path.addLine(to: CGPoint(x: pointX, y: pointY))
                        }
                    }
                    .stroke(themeManager.selectedTheme.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Points for each sentiment
                    ForEach(sortedNodes.indices, id: \.self) { index in
                        let node = sortedNodes[index]
                        let pointX = 10 + (chartWidth / CGFloat(max(1, sortedNodes.count - 1))) * CGFloat(index)
                        let pointY = calculateYPosition(for: node.metadata.sentiment, height: chartHeight) + 10
                        
                        Circle()
                            .fill(sentimentColor(for: node.metadata.sentiment))
                            .frame(width: 12, height: 12)
                            .position(x: pointX, y: pointY)
                        
                        // Chapter numbers
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.gray))
                            .position(x: pointX, y: height - 8)
                    }
                }
                .frame(height: 160)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Views
    
    /// Visualizes theme frequency
    struct ThemeProgressView: View {
        let theme: String
        let count: Int
        let maxCount: Int
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(theme)
                    .font(.callout)
                
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            
                            // Progress bar
                            Rectangle()
                                .fill(Color.blue)
                                .cornerRadius(4)
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
            }
        }
    }
    
    /// Visualizes entity frequency as bubbles
    struct EntityBubbleView: View {
        let entity: String
        let count: Int
        
        var body: some View {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
                
                Text(entity)
                    .font(.callout)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    /// Displays a simple statistic
    struct StatisticView: View {
        let title: String
        let value: String
        let icon: String
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Maps sentiment string to Y position on chart
    private func calculateYPosition(for sentiment: String, height: CGFloat) -> CGFloat {
        let normalizedValue = normalizedSentimentValue(for: sentiment)
        return height - (normalizedValue * height)
    }
    
    /// Normalizes sentiment to a 0-1 range
    private func normalizedSentimentValue(for sentiment: String) -> CGFloat {
        switch sentiment.lowercased() {
        case "positive", "happy", "excited", "hopeful":
            return 0.1 // Top of chart (positive)
        case "neutral", "calm":
            return 0.5 // Middle
        case "tense", "anxious", "nervous":
            return 0.7 // Somewhat negative
        case "negative", "sad", "depressed":
            return 0.9 // Bottom of chart (negative)
        default:
            return 0.5 // Default to middle
        }
    }
    
    /// Returns color based on sentiment
    private func sentimentColor(for sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive", "happy", "excited", "hopeful":
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
    
    /// Calculates theme frequency across chapters
    private func calculateThemeFrequency() -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for node in storyNodes {
            for theme in node.metadata.themes {
                frequency[theme, default: 0] += 1
            }
        }
        
        return frequency
    }
    
    /// Calculates entity frequency across chapters
    private func calculateEntityFrequency() -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for node in storyNodes {
            for entity in node.metadata.entities {
                frequency[entity, default: 0] += 1
            }
        }
        
        return frequency
    }
    
    /// Calculates the total word count across chapters
    private func calculateTotalWordCount() -> Int {
        let allText = storyNodes.map { $0.chapter.text }.joined(separator: " ")
        let components = allText.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
    
    /// Calculates the time span of the story
    private func calculateTimelineSpan() -> String {
        guard let oldestNode = storyNodes.min(by: { $0.timestamp < $1.timestamp }),
              let newestNode = storyNodes.max(by: { $0.timestamp < $1.timestamp }) else {
            return "N/A"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if Calendar.current.isDate(oldestNode.timestamp, equalTo: newestNode.timestamp, toGranularity: .month) {
            return formatter.string(from: oldestNode.timestamp)
        } else {
            return "\(formatter.string(from: oldestNode.timestamp)) - \(formatter.string(from: newestNode.timestamp))"
        }
    }
}

// MARK: - Preview
struct StoryMetadataInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryMetadataInsightsView(storyNodes: mockStoryNodes())
            .environmentObject(ThemeManager())
    }
    
    // Create mock story nodes for preview
    static func mockStoryNodes() -> [StoryNode] {
        let metadataEntries = [
            MetadataResponse(
                sentiment: "positive",
                themes: ["adventure", "discovery", "exploration"],
                entities: ["forest", "map", "ruins"],
                keyPhrases: ["ancient ruins"]
            ),
            MetadataResponse(
                sentiment: "tense",
                themes: ["danger", "mystery", "adventure"],
                entities: ["stranger", "cave", "artifact"],
                keyPhrases: ["strange sounds"]
            ),
            MetadataResponse(
                sentiment: "neutral",
                themes: ["reflection", "discovery", "mystery"],
                entities: ["village", "elder", "artifact"],
                keyPhrases: ["ancient wisdom"]
            ),
            MetadataResponse(
                sentiment: "hopeful",
                themes: ["friendship", "adventure", "discovery"],
                entities: ["friend", "mountain", "gate"],
                keyPhrases: ["unexpected ally"]
            )
        ]
        
        let chapterEntries = [
            ChapterResponse(
                chapterId: "ch-1",
                text: "The forest floor crunched underfoot as Elara ventured deeper, the ancient map clutched in her hand. Strange symbols glowed faintly on the parchment, reacting to the proximity of the hidden grove.",
                cliffhanger: "Strange symbols glowed faintly on the parchment.",
                studentName: "Student",
                feedback: "Great job on your journal entry!"
            ),
            ChapterResponse(
                chapterId: "ch-2",
                text: "Elara whirled around, hand instinctively reaching for the dagger at her belt. A tall figure stood partially obscured by shadow, watching her from between two ancient oaks.",
                cliffhanger: "A tall figure stood partially obscured by shadow.",
                studentName: "Student",
                feedback: "Your story is developing nicely!"
            ),
            ChapterResponse(
                chapterId: "ch-3",
                text: "The village elder's eyes widened as Elara presented the artifact. 'Where did you find this?' he whispered, hands trembling as he reached for it. 'This has been lost for generations.'",
                cliffhanger: "'This has been lost for generations.'",
                studentName: "Student",
                feedback: "You're making excellent progress in your journal entries!"
            ),
            ChapterResponse(
                chapterId: "ch-4",
                text: "The mountain pass opened to reveal a breathtaking vista. In the valley below, ancient stone structures rose from the mist, their surfaces etched with the same symbols from her map.",
                cliffhanger: "Ancient stone structures rose from the mist.",
                studentName: "Student",
                feedback: "Your storytelling skills are advancing with each entry!"
            )
        ]
        
        var nodes: [StoryNode] = []
        var currentDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        for i in 0..<4 {
            let node = StoryNode(
                entryId: UUID(),
                chapterId: chapterEntries[i].chapterId,
                parentId: i > 0 ? nodes[i-1].entryId : nil,
                metadata: metadataEntries[i],
                chapter: chapterEntries[i]
            )
            nodes.append(node)
            currentDate = currentDate.addingTimeInterval(7 * 24 * 60 * 60) // 7 days later
        }
        
        return nodes
    }
}
