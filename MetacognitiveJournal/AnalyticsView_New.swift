import SwiftUI
import Charts

// MARK: - MetricCard View
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
        .background(Color(.secondarySystemBackground))
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
        .onChange(of: animate) { _, _ in // Add closure parameters
            // Reset progress if animation state changes (e.g., view reappears)
            currentProgress = 0.0
            if animate {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentProgress = progress
                }
            } else {
                currentProgress = progress
            }
        }
    }
} // Closing brace for MetricCard struct

// MARK: - Main Analytics View
struct AnalyticsView: View {
    // MARK: - Properties
    let currentTabIndex: Int
    
    // MARK: - Environment Objects
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer // Assuming this exists
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - State
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var animateMetrics: Bool = false
    @State private var selectedInsightType: InsightType = .mood // Default insight
    @State private var selectedTab = 1 // 0 for analytics, 1 for rewards (default to rewards)
    @State private var currentPage = 0 // Current page for page tab navigation
    
    // New state variables for analytics data
    @State private var emotionalBalance: Double? = nil // Use Optional for loading state
    @State private var reflectionDepth: Double? = nil // Use Optional for loading state
    @State private var topics: [String] = []
    @State private var isLoadingAnalytics: Bool = false // To potentially show loading indicators
    @State private var analyticsError: Error? = nil
    
    // Required body property to conform to View
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Insights").tag(0)
                Text("Rewards").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 16) // Add top padding
            .padding(.bottom, 8)
            .zIndex(10) // Ensure picker is above other content
            
            // Content based on selected tab
            if selectedTab == 0 {
                // Analytics content
                Group {
                    switch userProfile.ageGroup {
                    case .child:
                        childAnalytics
                    case .teen:
                        childAnalytics // Using childAnalytics for teens too
                    case .adult, .parent:
                        childAnalytics // Using childAnalytics for adults/parents too
                    }
                }
            } else {
                // Rewards content with GamificationView
                GamificationView()
            }
        }
        .onAppear { 
            animateMetrics = true
        }
        .onDisappear {
            animateMetrics = false
        }
        .task(id: filteredEntries) { // Re-run when filteredEntries changes
            await loadAnalyticsData()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [JournalEntry] {
        // Placeholder filter logic - assuming JournalEntry has a 'date' property
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
    
    // MARK: - View Implementations (Placeholders)
    
    private var childAnalytics: some View {
        ScrollView {
            LazyVStack(spacing: 16) { // Use LazyVStack for better performance
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
                    .zIndex(1) // Ensure this is above other elements
                
                // Simple mood insights for children
                moodInsights 
                    .padding(.horizontal)
                    .padding(.top, 10) // Add some space after the story map link
            }
            .padding(.vertical)
        }
    }
    
    private var teenAnalytics: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeFrameSelector
                    .padding(.horizontal)
                
                // Metrics grid (Ensure MetricCard exists and conforms to View)
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
                            icon: "heart.fill", // Use icon from InsightType if desired
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
                
                // <<< ADD INSIGHT PICKER AND SWITCH HERE >>>
                Divider().padding(.vertical, 8)

                // Insight tabs
                insightTypePicker
                    .padding(.horizontal)
                
                // Insights based on selected type
                switch selectedInsightType {
                case .mood: moodInsights
                case .topics: topicInsights 
                case .patterns: patternInsights
                case .growth: growthInsights
                }
                // <<< END OF ADDED SECTION >>>

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
                        
                        let balance = calculateEmotionalBalance() // Assuming this reflects child's data source
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
                storyMapLink // Might need modification for parent context
                    .padding(.top, 10)
                
                // Parent-specific insights about child's progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Discussion Starters")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Ensure conversationPrompt function exists
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
                
                // Metrics (Ensure MetricCard exists and conforms to View)
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
                            icon: "heart.fill", // Use icon from InsightType if desired
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
                case .topics: topicInsights 
                case .patterns: patternInsights
                case .growth: growthInsights
                }
                
                personalRecommendations 
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - UI Components (Copied/Restored) 
    
    private var timeFrameSelector: some View {
        Picker("Time Frame", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases) { timeFrame in
                Text(timeFrame.rawValue).tag(timeFrame)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var insightTypePicker: some View {
        // Ensure InsightType has 'icon' and 'title' properties/computed vars
        HStack(spacing: 8) { // Reduced spacing between buttons
            ForEach(InsightType.allCases) { insightType in
                Button(action: {
                    withAnimation {
                        selectedInsightType = insightType
                    }
                }) {
                    VStack(spacing: 4) { // Reduced spacing between icon and text
                        Image(systemName: insightType.icon) 
                            .font(.system(size: 18)) // Slightly smaller icon
                            .foregroundColor(selectedInsightType == insightType ?
                                            themeManager.selectedTheme.accentColor :
                                            Color.primary.opacity(0.6))
                        
                        Text(insightType.title)
                            .font(.caption2) // Smaller font
                            .foregroundColor(selectedInsightType == insightType ?
                                            themeManager.selectedTheme.accentColor :
                                            Color.primary.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true) // Ensure text doesn't cause layout issues
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8) // Slightly reduced vertical padding
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedInsightType == insightType ?
                                 themeManager.selectedTheme.accentColor.opacity(0.1) :
                                 Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle()) // Ensure the entire area is tappable
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding(.top, 8) // Add top padding to separate from other elements
        .padding(.bottom, 12) // Add bottom padding to separate from content below
    }
    
    private func conversationPrompt(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
    
    // MARK: - Story Map Integration (Copied/Restored)
    
    private var storyMapLink: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Story Journey")
                .font(.headline)
                .padding(.horizontal)
            
            // Ensure EnhancedStoryMapView exists and EnvironmentObjects are correct
            // Use actual StoryMapView type instead of placeholder
            NavigationLink(destination: EnhancedStoryMapView() // Replace with actual view if available
                .environmentObject(themeManager) // Keep only the used environment object
            ) {
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
            .buttonStyle(PlainButtonStyle()) // Add button style to ensure tap area is correct
            .contentShape(Rectangle()) // Ensure the entire area is tappable
        }
    }
    
    // MARK: - Insight Views (Placeholders)
    
    private var moodInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mood Insights")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            .padding(.horizontal) // Add horizontal padding
            
            if isLoadingAnalytics {
                ProgressView("Analyzing mood patterns...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if filteredEntries.isEmpty {
                Text("No journal entries available for the selected time period.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Mood trend chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood Trend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    moodTrendChart
                        .frame(height: 150)
                        .padding(.vertical, 8)
                }
                
                // Mood distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood Distribution")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    moodDistributionChart
                        .frame(height: 100)
                        .padding(.vertical, 8)
                }
                
                // Mood insights text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(generateMoodInsights(), id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                                .padding(.top, 6)
                            Text(insight)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Mood trend chart showing emotional balance over time
    private var moodTrendChart: some View {
        Chart {
            ForEach(moodDataPoints) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.value)
                )
                .foregroundStyle(themeManager.selectedTheme.accentColor.gradient)
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.value)
                )
                .foregroundStyle(themeManager.selectedTheme.accentColor.opacity(0.2).gradient)
                
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.value)
                )
                .foregroundStyle(themeManager.selectedTheme.accentColor)
            }
        }
        .chartYScale(domain: -1...1)
        .chartYAxis {
            AxisMarks(values: [-1, 0, 1]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        switch doubleValue {
                        case -1: Text("Negative")
                        case 0: Text("Neutral")
                        case 1: Text("Positive")
                        default: Text("")
                        }
                    }
                }
            }
        }
    }
    
    // Mood distribution chart showing the distribution of emotions
    private var moodDistributionChart: some View {
        Chart {
            ForEach(moodDistribution, id: \.emotion) { item in
                BarMark(
                    x: .value("Emotion", item.emotion),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(emotionColor(for: item.emotion))
            }
        }
    }
    
    // Generate mood data points for the chart
    private var moodDataPoints: [MoodDataPoint] {
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        return sortedEntries.map { entry in
            // Convert emotional state to a value between -1 and 1
            let value = moodValueFromEmotionalState(entry.emotionalState)
            return MoodDataPoint(date: entry.date, value: value)
        }
    }
    
    // Generate mood distribution data
    private var moodDistribution: [MoodDistributionItem] {
        var distribution: [EmotionalState: Int] = [:]
        
        // Count occurrences of each emotional state
        for entry in filteredEntries {
            distribution[entry.emotionalState, default: 0] += 1
        }
        
        // Convert to array of MoodDistributionItem
        return distribution.map { emotion, count in
            MoodDistributionItem(emotion: emotion.rawValue, count: count)
        }.sorted { $0.count > $1.count }
    }
    
    // Convert emotional state to a value between -1 and 1
    private func moodValueFromEmotionalState(_ state: EmotionalState) -> Double {
        switch state {
        case .overwhelmed, .frustrated: return -0.75
        case .confused: return -0.25
        case .neutral: return 0.0
        case .curious: return 0.25
        case .satisfied, .confident: return 0.75
        }
    }
    
    // Get color for emotion in distribution chart
    private func emotionColor(for emotion: String) -> Color {
        if let emotionalState = EmotionalState(rawValue: emotion) {
            return emotionalState.color
        }
        return .gray
    }
    
    // Generate textual insights about mood patterns
    private func generateMoodInsights() -> [String] {
        var insights: [String] = []
        
        // No entries case
        if filteredEntries.isEmpty {
            return ["No journal entries available for analysis."]
        }
        
        // Calculate average mood
        let moodValues = filteredEntries.map { moodValueFromEmotionalState($0.emotionalState) }
        let averageMood = moodValues.reduce(0, +) / Double(moodValues.count)
        
        // Determine dominant mood
        let dominantMood = moodDistribution.first?.emotion ?? "neutral"
        
        // Add insights based on data
        if averageMood > 0.3 {
            insights.append("Your overall mood has been positive during this period.")
        } else if averageMood < -0.3 {
            insights.append("Your overall mood has been challenging during this period.")
        } else {
            insights.append("Your overall mood has been balanced during this period.")
        }
        
        // Add insight about dominant mood
        insights.append("Your most frequent emotional state was \(dominantMood).")
        
        // Check for mood variability
        if let maxMood = moodValues.max(), let minMood = moodValues.min(), (maxMood - minMood) > 1.0 {
            insights.append("Your mood showed significant variation, which is normal and healthy.")
        }
        
        // Add a personalized suggestion
        if averageMood < 0 {
            insights.append("Consider practicing mindfulness or gratitude journaling to help improve your mood.")
        } else {
            insights.append("Continue your current journaling practice to maintain your emotional well-being.")
        }
        
        return insights
    }
    
    @ViewBuilder
    private var topicInsights: some View {
        if isLoadingAnalytics {
            ProgressView("Loading Topics...")
        } else if !topics.isEmpty {
            WordCloudView(words: topics)
                .padding()
                .frame(minHeight: 200) // Give the cloud some space
        } else if analyticsError != nil {
            Text("Error loading topics.")
                .foregroundColor(.red)
        } else {
            EmptyInsightsView()
        }
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

    // MARK: - Helper Functions (Copied/Restored)
    
    // Placeholder - needs real implementation
    private func calculateCurrentStreak() -> Int {
        guard !filteredEntries.isEmpty else { return 0 }
        
        let sortedEntries = filteredEntries.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        
        var streak = 0
        // Find the date of the most recent entry within the filtered set
        if let mostRecentEntryDate = sortedEntries.first?.date {
            // Only start counting if the most recent entry is today or yesterday
            if calendar.isDateInToday(mostRecentEntryDate) || calendar.isDateInYesterday(mostRecentEntryDate) {
                // Continue with streak calculation using mostRecentEntryDate
                streak = 1 // Count the most recent entry as 1 day in the streak
            } else {
                // If the most recent entry wasn't recent, streak is 0
                return 0
            }
        } else {
            return 0 // Should not happen if !filteredEntries.isEmpty
        }
        
        var uniqueEntryDays = Set<Date>()
        for entry in sortedEntries {
            uniqueEntryDays.insert(calendar.startOfDay(for: entry.date))
        }
        
        let sortedUniqueDays = uniqueEntryDays.sorted { $0 > $1 }
        
        guard let mostRecentDay = sortedUniqueDays.first else { return 0 }
        
        // Check if the most recent entry day is today or yesterday to start the streak count
        if !calendar.isDate(mostRecentDay, inSameDayAs: Date()) && !calendar.isDateInYesterday(mostRecentDay) {
            return 0
        }
        
        streak = 1 // Start with 1 for the most recent day
        var previousDay = mostRecentDay
        
        for i in 1..<sortedUniqueDays.count {
            let currentDay = sortedUniqueDays[i]
            // Check if currentDay is exactly one day before previousDay
            if let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: previousDay), 
               calendar.isDate(currentDay, inSameDayAs: expectedPreviousDay) {
                streak += 1
                previousDay = currentDay
            } else {
                // Gap detected, stop counting
                break
            }
        }
        
        return streak
    }
    
    // Placeholder - needs real implementation using MetacognitiveAnalyzer
    private func calculateEmotionalBalance() -> Double {
        // Return the calculated value, or 0.0 (neutral) as a default/loading value
        // Note: OpenAI sentiment is -1.0 to 1.0. We might need to normalize this.
        // Mapping [-1, 1] to [0, 1] for progress: (emotionalBalance ?? 0.0 + 1.0) / 2.0
        // Returning raw value for now, assuming MetricCard can handle it or is adapted.
        return emotionalBalance ?? 0.0
    }
    
    // Placeholder - needs real implementation using MetacognitiveAnalyzer
    private func calculateReflectionDepth() -> Double {
        // Return the calculated value, or 0.5 (moderate) as a default/loading value
        return reflectionDepth ?? 0.5
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        // Ensure value is clamped between 0 and 1 before formatting
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

    // MARK: - Helper Types

    // Define TimeFrame enum if not already defined elsewhere
    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        var id: String { self.rawValue }
    }

    struct SentimentTimePoint: Identifiable {
        let id = UUID()
        let date: Date
        let sentiment: Double // Assuming sentiment is a Double
    }

    struct ReflectionDepthTimePoint: Identifiable {
        let id = UUID()
        let date: Date
        let depth: Double // Assuming depth is a Double
    }

    // Data structures for mood analytics
    struct MoodDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    struct MoodDistributionItem {
        let emotion: String
        let count: Int
    }
    
    enum InsightType: String, CaseIterable, Identifiable {
        case mood = "Mood"
        case topics = "Topics"
        case patterns = "Patterns"
        case growth = "Growth"
        
        var id: String { rawValue } // Explicit id for Identifiable conformance
        
        var title: String {
            switch self {
            case .mood: return "Mood"
            case .topics: return "Topics"
            case .patterns: return "Patterns"
            case .growth: return "Growth"
            }
        }
        
        var icon: String {
            switch self {
            case .mood: return "heart.fill"
            case .topics: return "text.bubble.fill"
            case .patterns: return "chart.bar.fill"
            case .growth: return "chart.line.uptrend.xyaxis"
            }
        }
    }
} // Closing brace for AnalyticsView struct

// MARK: - Previews

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data / environment objects for preview
        let mockJournalStore = JournalStore() // Populate with sample data if needed
        let mockAnalyzer = MetacognitiveAnalyzer()
        let mockUserProfile = UserProfile()
        let mockThemeManager = ThemeManager()

        NavigationView {
            AnalyticsView(currentTabIndex: 0) // Use 0 as default for preview
                .environmentObject(mockJournalStore)
                .environmentObject(mockAnalyzer)
                .environmentObject(mockUserProfile)
                .environmentObject(mockThemeManager)
        }
    }
}

// MARK: - Load Analytics Data

extension AnalyticsView {
    private func loadAnalyticsData() async {
        guard !filteredEntries.isEmpty else {
            // Reset if no entries
             await MainActor.run {
                emotionalBalance = 0.0
                reflectionDepth = 0.0
                topics = []
                isLoadingAnalytics = false
                print("No entries in filter, resetting analytics.")
            }
            return
        }
        
        await MainActor.run { isLoadingAnalytics = true }
        print("Starting analytics calculations...") // Debugging

        // Create a TaskGroup or run tasks sequentially/concurrently
        // Running concurrently for potentially faster results
        let sentimentTask = Task {
            var totalSentiment: Double = 0
            for entry in filteredEntries {
                if let sentiment = try? await analyzer.analyzeTone(entry: entry) {
                    totalSentiment += sentiment
                }
            }
            return filteredEntries.isEmpty ? 0 : totalSentiment / Double(filteredEntries.count)
        }
        let depthTask = Task {
            var totalDepth: Double = 0
            for entry in filteredEntries {
                if let depth = try? await analyzer.analyzeReflectionDepth(entry: entry) {
                    totalDepth += depth
                }
            }
            return filteredEntries.isEmpty ? 0 : totalDepth / Double(filteredEntries.count)
        }
        let topicsTask = Task { try? await analyzer.extractTopics(from: filteredEntries) }

        // Await results - explicitly mark with await to comply with Swift 6 mode
        let sentimentResult = await sentimentTask.value
        let depthResult = await depthTask.value
        let topicsResult = await topicsTask.value

        // Update state on the main thread
        await MainActor.run {
            emotionalBalance = sentimentResult
            reflectionDepth = depthResult   // Use the result directly, fallback is handled in analyzer
            // Convert the tuple array to a simple string array by extracting just the topic names
            topics = (topicsResult ?? []).map { $0.topic }
            print("Analytics loaded: Balance=\(emotionalBalance ?? -999), Depth=\(reflectionDepth ?? -999)") // Debugging
            isLoadingAnalytics = false
        }
    }
}
