#if false
import SwiftUI
import Charts

// Mock/Type Alias for compilation
typealias JournalStore = Any
typealias MetacognitiveAnalyzer = Any
typealias UserProfile = Any
typealias ThemeManager = Any


// MARK: - AnalyticsView
struct AnalyticsView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    
    // State for time frame selection, etc.
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedTabIndex = 0
    @State private var animateCharts = false
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [JournalEntry] {
        journalStore.entries.filter { entry in
            switch selectedTimeFrame {
            case .week:
                return Calendar.current.isDateInThisWeek(entry.date)
            case .month:
                return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .month)
            case .year:
                return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .year)
            case .all:
                return true
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time frame selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Main metrics 
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            metricCard(
                                title: "Current Streak",
                                value: "\(calculateCurrentStreak())",
                                subtitle: "days",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            metricCard(
                                title: "Journal Entries",
                                value: "\(filteredEntries.count)",
                                subtitle: selectedTimeFrame == .all ? "total" : "this \(selectedTimeFrame.rawValue)",
                                icon: "book.closed.fill",
                                color: .blue
                            )
                        }
                        
                        HStack(spacing: 16) {
                            let emotionalBalance = calculateEmotionalBalance()
                            metricCard(
                                title: "Emotional Balance",
                                value: formatPercentage(emotionalBalance * 0.5 + 0.5),
                                subtitle: emotionalBalanceDescription(emotionalBalance),
                                icon: "heart.fill",
                                color: emotionalBalanceColor(emotionalBalance)
                            )
                            
                            let reflectionDepth = calculateReflectionDepth()
                            metricCard(
                                title: "Reflection Depth",
                                value: formatPercentage(reflectionDepth),
                                subtitle: reflectionDepthDescription(reflectionDepth),
                                icon: "brain.head.profile",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Story Map Integration - Link to narrative journey
                    storyMapSection
                        .padding(.top, 10)
                    
                    // Simple Mood Insights
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Your mood has been mostly \(moodDescription()) in the past \(selectedTimeFrame.rawValue.lowercased()).")
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics & Insights")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                animateCharts = true
            }
        }
    }
    
    // MARK: - UI Components
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Story Map Integration
    
    private var storyMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Story Journey")
                .font(.headline)
                .padding(.horizontal)
            
            // This would navigate to a StoryMapView in the actual implementation
            NavigationLink(destination: storyMapPlaceholder) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Story Map")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("See your journal entries as chapters in your personal story")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "book.pages")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private var storyMapPlaceholder: some View {
        Group {
            // The actual StoryMapView implementation would be used here
            // For now, we'll create a placeholder that mentions the journey
            VStack(spacing: 20) {
                Text("Your Story Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This map visualizes your journal entries as chapters in your personal story journey.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Emotional journey visualization placeholder
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emotional Journey")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<10) { i in
                            Circle()
                                .fill(emotionColor(for: i))
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    Text("Your emotional journey shows how your feelings have evolved through your journaling practice.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Story Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateCurrentStreak() -> Int {
        return 3 // Simplified placeholder
    }
    
    private func calculateEmotionalBalance() -> Double {
        return 0.2 // Simplified placeholder (slightly positive)
    }
    
    private func calculateReflectionDepth() -> Double {
        return 0.6 // Simplified placeholder (moderate)
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: max(0, min(1, value)))) ?? "0%"
    }
    
    private func emotionalBalanceDescription(_ balance: Double) -> String {
        switch balance {
        case 0.5...: return "Very Positive"
        case 0.1..<0.5: return "Positive"
        case -0.1..<0.1: return "Neutral"
        case -0.5 ..< -0.1: return "Negative"
        default: return "Very Negative"
        }
    }
    
    private func emotionalBalanceColor(_ balance: Double) -> Color {
        switch balance {
        case 0.5...: return .green
        case 0.1..<0.5: return .yellow
        case -0.1..<0.1: return .gray
        case -0.5 ..< -0.1: return .orange
        default: return .red
        }
    }
    
    private func reflectionDepthDescription(_ depth: Double) -> String {
        switch depth {
        case 0.75...: return "Deep"
        case 0.5..<0.75: return "Moderate"
        case 0.25..<0.5: return "Surface"
        default: return "Shallow"
        }
    }
    
    private func moodDescription() -> String {
        let balance = calculateEmotionalBalance()
        if balance > 0.3 {
            return "positive"
        } else if balance > -0.1 {
            return "balanced"
        } else {
            return "reflective"
        }
    }
    
    private func emotionColor(for index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .green, .blue, .purple]
        return colors[index % colors.count]
    }
}

// MARK: - Supporting Types

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All Time"
    var id: String { self.rawValue }
}
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double // Assuming progress is 0.0 to 1.0
    let animate: Bool
    
    @State private var currentProgress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: currentProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .padding(.top, 4)
        }
        .padding()
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(12)
        .onAppear {
            if animate {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentProgress = progress
                }
            } else {
                currentProgress = progress
            }
        }
        .onChange(of: animate) { newValue in
            // Reset progress if animation state changes (e.g., view reappears)
            currentProgress = 0.0
            if newValue {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentProgress = progress
                }
            } else {
                currentProgress = progress
            }
        }
    }
}

// MARK: - Main Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    
    // State for time frame selection, insights, etc.
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var animateMetrics: Bool = false
    @State private var selectedInsightType: InsightType = .mood // Default insight
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [JournalEntry] {
        journalStore.entries.filter { entry in
            switch selectedTimeFrame {
            case .week:
                return Calendar.current.isDateInThisWeek(entry.date)
            case .month:
                return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .month)
            case .year:
                return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .year)
            case .all:
                return true
            }
        }
    }
    
    // MARK: - View Implementations
    
    var body: some View {
        Group {
            switch userProfile.ageGroup {
            case .child:
                childAnalytics
            case .teen:
                teenAnalytics
            case .parent:
                parentAnalytics
            default:
                defaultAnalytics
            }
        }
        .navigationTitle("Analytics")
        .onAppear { 
            animateMetrics = true
        }
        .onDisappear {
            animateMetrics = false
        }
    }
    
    // MARK: - Age-Specific Views
    
    private var childAnalytics: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeFrameSelector
                    .padding(.horizontal)
                
                // Simple metrics for children
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(calculateCurrentStreak()) days")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(filteredEntries.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Story Map Integration - Link to the narrative journey
                storyMapLink
                    .padding(.top, 20)
                
                // Simple mood insights for children
                moodInsights
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var teenAnalytics: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeFrameSelector
                    .padding(.horizontal)
                
                // Metrics grid
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        MetricCard(
                            title: "Current Streak",
                            value: "\(calculateCurrentStreak())",
                            subtitle: "days",
                            icon: "flame.fill",
                            color: .orange,
                            progress: min(Double(calculateCurrentStreak()) / 30.0, 1.0),
                            animate: animateMetrics
                        )
                        
                        MetricCard(
                            title: "Journal Entries",
                            value: "\(filteredEntries.count)",
                            subtitle: selectedTimeFrame == .all ? "total" : "this \(selectedTimeFrame.rawValue)",
                            icon: "book.closed.fill",
                            color: .blue,
                            progress: min(Double(filteredEntries.count) / 20.0, 1.0),
                            animate: animateMetrics
                        )
                    }
                    
                    HStack(spacing: 16) {
                        let emotionalBalance = calculateEmotionalBalance()
                        MetricCard(
                            title: "Emotional Balance",
                            value: formatPercentage(emotionalBalance * 0.5 + 0.5), // Map -1..1 to 0..1
                            subtitle: emotionalBalanceDescription(emotionalBalance),
                            icon: "heart.fill",
                            color: emotionalBalanceColor(emotionalBalance),
                            progress: emotionalBalance * 0.5 + 0.5, // Map -1..1 to 0..1
                            animate: animateMetrics
                        )
                        
                        let reflectionDepth = calculateReflectionDepth()
                        MetricCard(
                            title: "Reflection Depth",
                            value: formatPercentage(reflectionDepth),
                            subtitle: reflectionDepthDescription(reflectionDepth),
                            icon: "brain.head.profile",
                            color: .purple,
                            progress: reflectionDepth,
                            animate: animateMetrics
                        )
                    }
                }
                .padding(.horizontal)
                
                // Story Map Integration - more detailed for teens
                storyMapLink
                    .padding(.top, 10)
                
                // Insight tabs
                insightTypePicker
                    .padding(.horizontal)
                
                // Insights based on selected type
                switch selectedInsightType {
                case .mood: moodInsights
                case .topic: topicInsights
                case .patterns: patternInsights
                case .growth: growthInsights
                }
                
                personalRecommendations
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var parentAnalytics: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeFrameSelector
                    .padding(.horizontal)
                
                // Parent summary metrics
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Child's Entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(filteredEntries.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                        
                        let balance = calculateEmotionalBalance()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emotional Tone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(emotionalBalanceDescription(balance))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(emotionalBalanceColor(balance))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Story Map Integration - parental overview
                storyMapLink
                    .padding(.top, 10)
                
                // Parent-specific insights about child's progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Discussion Starters")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        conversationPrompt("What was your favorite moment this week?")
                        conversationPrompt("Did you learn anything surprising recently?")
                        conversationPrompt("Is there something you're proud of accomplishing?")
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .padding(.vertical)
        }
    }
    
    private var defaultAnalytics: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeFrameSelector
                    .padding(.horizontal)
                
                // Metrics
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        MetricCard(
                            title: "Current Streak",
                            value: "\(calculateCurrentStreak())",
                            subtitle: "days",
                            icon: "flame.fill",
                            color: .orange,
                            progress: min(Double(calculateCurrentStreak()) / 30.0, 1.0),
                            animate: animateMetrics
                        )
                        
                        MetricCard(
                            title: "Journal Entries",
                            value: "\(filteredEntries.count)",
                            subtitle: selectedTimeFrame == .all ? "total" : "this \(selectedTimeFrame.rawValue)",
                            icon: "book.closed.fill",
                            color: .blue,
                            progress: min(Double(filteredEntries.count) / 20.0, 1.0),
                            animate: animateMetrics
                        )
                    }
                    
                    HStack(spacing: 16) {
                        let emotionalBalance = calculateEmotionalBalance()
                        MetricCard(
                            title: "Emotional Balance",
                            value: formatPercentage(emotionalBalance * 0.5 + 0.5), // Map -1..1 to 0..1
                            subtitle: emotionalBalanceDescription(emotionalBalance),
                            icon: "heart.fill",
                            color: emotionalBalanceColor(emotionalBalance),
                            progress: emotionalBalance * 0.5 + 0.5, // Map -1..1 to 0..1
                            animate: animateMetrics
                        )
                        
                        let reflectionDepth = calculateReflectionDepth()
                        MetricCard(
                            title: "Reflection Depth",
                            value: formatPercentage(reflectionDepth),
                            subtitle: reflectionDepthDescription(reflectionDepth),
                            icon: "brain.head.profile",
                            color: .purple,
                            progress: reflectionDepth,
                            animate: animateMetrics
                        )
                    }
                }
                .padding(.horizontal)
                
                // Story Map Integration
                storyMapLink
                    .padding(.top, 20)
                
                // Insight tabs
                insightTypePicker
                    .padding(.horizontal)
                
                // Insights based on selected type
                switch selectedInsightType {
                case .mood: moodInsights
                case .topic: topicInsights
                case .patterns: patternInsights
                case .growth: growthInsights
                }
                
                personalRecommendations
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - UI Components
    
    private var timeFrameSelector: some View {
        Picker("Time Frame", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases) { timeFrame in
                Text(timeFrame.rawValue).tag(timeFrame)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var insightTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightType.allCases) { insightType in
                Button(action: {
                    withAnimation {
                        selectedInsightType = insightType
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: insightType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedInsightType == insightType ? 
                                            themeManager.selectedTheme.accentColor : 
                                            Color.primary.opacity(0.6))
                        
                        Text(insightType.title)
                            .font(.caption)
                            .fontWeight(selectedInsightType == insightType ? .semibold : .regular)
                            .foregroundColor(selectedInsightType == insightType ? 
                                            themeManager.selectedTheme.accentColor : 
                                            Color.primary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(Color.clear)
                            .overlay(
                                Rectangle()
                                    .frame(height: 3)
                                    .foregroundColor(selectedInsightType == insightType ? 
                                                    themeManager.selectedTheme.accentColor : 
                                                    Color.clear),
                                alignment: .bottom
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if insightType != .growth { // Add spacer between items if needed
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
    
    // MARK: - Story Map Integration
    
    private var storyMapLink: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Story Journey")
                .font(.headline)
                .padding(.horizontal)
            
            NavigationLink(destination: EnhancedStoryMapView()
                .environmentObject(journalStore)
                .environmentObject(analyzer)
                .environmentObject(themeManager)
                .environmentObject(userProfile)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Story Map")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("See your journal entries as chapters in your personal story")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "book.pages")
                        .font(.largeTitle)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
                .padding()
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Insight Views
    
    private var moodInsights: some View {
        Text("Mood Insights Placeholder")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    private var topicInsights: some View {
        Text("Topic Insights Placeholder")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    private var patternInsights: some View {
        Text("Pattern Insights Placeholder")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    private var growthInsights: some View {
        Text("Growth Insights Placeholder")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    private var personalRecommendations: some View {
        Text("Personal Recommendations Placeholder")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    private func conversationPrompt(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func calculateCurrentStreak() -> Int {
        return 3 // Simplified placeholder
    }
    
    private func extractMostCommonWords() -> [String: Double] {
        return ["journal": 30.0, "reflect": 25.0, "think": 20.0] // Simplified placeholder
    }
    
    private func calculateEmotionalBalance() -> Double {
        return 0.2 // Simplified placeholder (slightly positive)
    }
    
    private func calculateReflectionDepth() -> Double {
        return 0.6 // Simplified placeholder (moderate)
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: max(0, min(1, value)))) ?? "0%"
    }
    
    private func emotionalBalanceDescription(_ balance: Double) -> String {
        switch balance {
        case 0.5...: return "Very Positive"
        case 0.1..<0.5: return "Positive"
        case -0.1..<0.1: return "Neutral"
        case -0.5 ..< -0.1: return "Negative"
        default: return "Very Negative"
        }
    }
    
    private func emotionalBalanceColor(_ balance: Double) -> Color {
        switch balance {
        case 0.5...: return .green
        case 0.1..<0.5: return .yellow
        case -0.1..<0.1: return .gray
        case -0.5 ..< -0.1: return .orange
        default: return .red
        }
    }
    
    private func reflectionDepthDescription(_ depth: Double) -> String {
        switch depth {
        case 0.75...: return "Deep"
        case 0.5..<0.75: return "Moderate"
        case 0.25..<0.5: return "Surface"
        default: return "Shallow"
        }
    }
}

// MARK: - Supporting Enums

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All Time"
    var id: String { self.rawValue }
}

// Removed duplicate enum InsightType. Use public enum from AnalyticsTypes.swift.

// MARK: - Previews

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsView()
                .environmentObject(JournalStore())
                .environmentObject(MetacognitiveAnalyzer())
                .environmentObject(UserProfile())
                .environmentObject(ThemeManager())
        }
    }
}
#endif
