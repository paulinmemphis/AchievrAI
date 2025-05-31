import SwiftUI

// Using consolidated model definitions from MCJModels.swift

/// A view that displays AI-generated insights about the user's journal entries
struct JournalInsightsView: View {
    // MARK: - Environment
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var nudgeManager: AINudgeManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var showNudgeHistory = false
    @State private var selectedTab = 0
    @State private var isGeneratingInsight = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Insight Type", selection: $selectedTab) {
                    Text("Recent").tag(0)
                    Text("Learning").tag(1)
                    Text("Patterns").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 24) {
                        // Current insight
                        if nudgeManager.latestNudge != nil {
                            AITipView(entries: journalStore.entries)
                        } else {
                            generateInsightButton
                        }
                        
                        // Tab-specific content
                        switch selectedTab {
                        case 0:
                            recentInsightsSection
                        case 1:
                            learningStyleSection
                        case 2:
                            patternsSection
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .sheet(isPresented: $showingPatternDetail) {
                PatternDetailView(patternType: selectedPatternType, journalStore: journalStore)
                    .environmentObject(themeManager)
            }
            .navigationTitle("Journal Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNudgeHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showNudgeHistory) {
                AINudgeHistoryView()
            }
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
    
    // MARK: - UI Components
    
    /// Button to generate a new insight
    private var generateInsightButton: some View {
        Button {
            isGeneratingInsight = true
            nudgeManager.scheduleProactiveNudge()
            
            // Reset after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isGeneratingInsight = false
            }
        } label: {
            HStack {
                if isGeneratingInsight {
                    ProgressView()
                        .padding(.trailing, 8)
                }
                
                Text(isGeneratingInsight ? "Generating..." : "Generate New Insight")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.selectedTheme.accentColor)
            )
        }
        .disabled(isGeneratingInsight)
    }
    
    /// Section showing recent insights
    private var recentInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            if nudgeManager.nudgeHistory.isEmpty {
                emptyStateCard(
                    icon: "sparkles",
                    title: "No Recent Insights",
                    message: "Generate your first insight to see it here."
                )
            } else {
                ForEach(nudgeManager.nudgeHistory.prefix(3)) { nudge in
                    insightCard(text: nudge.text, date: nudge.date)
                }
                
                if nudgeManager.nudgeHistory.count > 3 {
                    Button {
                        showNudgeHistory = true
                    } label: {
                        Text("View All \(nudgeManager.nudgeHistory.count) Insights")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    /// Section showing learning style information
    private var learningStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Learning Style")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            if let pattern = nudgeManager.learningPattern {
                learningStyleCard(pattern: pattern)
            } else {
                emptyStateCard(
                    icon: "brain",
                    title: "Learning Style Not Detected",
                    message: "Continue journaling to help identify your learning preferences."
                )
            }
        }
    }
    
    /// Section showing patterns in journal entries
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Journal Patterns")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            if journalStore.entries.count < 3 {
                emptyStateCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Not Enough Data",
                    message: "Add at least 3 journal entries to see patterns."
                )
            } else {
                // Frequency pattern
                patternCard(
                    title: "Journaling Frequency",
                    value: "\(journalStore.entries.count) entries",
                    description: "You journal most often on \(mostFrequentJournalingDay)",
                    type: .frequency
                )
                
                // Length pattern
                patternCard(
                    title: "Entry Length",
                    value: "\(averageEntryLength) words",
                    description: averageEntryLengthDescription,
                    type: .length
                )
                
                // Mood pattern
                patternCard(
                    title: "Emotional Tone",
                    value: dominantMood,
                    description: "This is your most common emotional state when journaling",
                    type: .mood
                )
            }
        }
    }
    
    /// Card for displaying an insight
    private func insightCard(text: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.body)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Card for displaying learning style information
    private func learningStyleCard(pattern: LearningStylePattern) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: learningStyleIcon(for: pattern))
                    .font(.title2)
                    .foregroundColor(learningStyleColor(for: pattern))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(learningStyleColor(for: pattern).opacity(0.2))
                    )
                
                VStack(alignment: .leading) {
                    Text(formatLearningStyleName(pattern))
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Your primary learning preference")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            
            Divider()
            
            Text("Recommendations:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(pattern.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(learningStyleColor(for: pattern))
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Pattern Detail State
    @State private var showingPatternDetail = false
    @State private var selectedPatternType: PatternType = .frequency
    
    enum PatternType {
        case frequency, length, mood
    }
    
    /// Card for displaying a pattern
    private func patternCard(title: String, value: String, description: String, type: PatternType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .font(.caption)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPatternType = type
            showingPatternDetail = true
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Card for displaying an empty state
    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(themeManager.selectedTheme.accentColor.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Gets the icon for a learning style
    private func learningStyleIcon(for pattern: LearningStylePattern) -> String {
        switch pattern {
        case .visualLearner:
            return "eye.fill"
        case .auditoryLearner:
            return "ear.fill"
        case .handsonLearner:
            return "hand.raised.fill"
        case .contextualLearner, .abstractLearner, .reflectiveThinker, .activeThinker, .sequentialProcessor, .holisticProcessor:
            return "book.fill"
        }
    }
    
    /// Formats the learning style name for display
    private func formatLearningStyleName(_ pattern: LearningStylePattern) -> String {
        switch pattern {
        case .visualLearner:
            return "Visual Learner"
        case .auditoryLearner:
            return "Auditory Learner"
        case .handsonLearner:
            return "Hands-on Learner"
        case .contextualLearner:
            return "Contextual Learner"
        case .abstractLearner:
            return "Abstract Learner"
        case .reflectiveThinker:
            return "Reflective Thinker"
        case .activeThinker:
            return "Active Thinker"
        case .sequentialProcessor:
            return "Sequential Processor"
        case .holisticProcessor:
            return "Holistic Processor"
        }
    }
    
    /// Gets the color for a learning style
    private func learningStyleColor(for pattern: LearningStylePattern) -> Color {
        switch pattern {
        case .visualLearner:
            return .blue
        case .auditoryLearner:
            return .purple
        case .handsonLearner:
            return .green
        case .contextualLearner:
            return .orange
        case .abstractLearner:
            return .pink
        case .reflectiveThinker:
            return .teal
        case .activeThinker:
            return .red
        case .sequentialProcessor:
            return .indigo
        case .holisticProcessor:
            return .yellow
        }
    }
    
    /// Gets the most frequent journaling day
    private var mostFrequentJournalingDay: String {
        let calendar = Calendar.current
        let dayComponents = journalStore.entries.map { calendar.component(.weekday, from: $0.date) }
        let dayCounts = Dictionary(grouping: dayComponents) { $0 }.mapValues { $0.count }
        
        if let (mostFrequentDay, _) = dayCounts.max(by: { $0.value < $1.value }) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            
            // Create a date with the weekday component
            var components = DateComponents()
            components.weekday = mostFrequentDay
            if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
                return dateFormatter.string(from: date)
            }
        }
        
        return "weekdays"
    }
    
    /// Gets the average entry length
    private var averageEntryLength: Int {
        guard !journalStore.entries.isEmpty else { return 0 }
        
        let totalWords = journalStore.entries.reduce(0) { count, entry in
            // Combine all text content from reflection prompts and transcription
            let reflectionText = entry.reflectionPrompts.compactMap { $0.response }.joined(separator: " ")
            let transcriptionText = entry.transcription ?? ""
            let combinedText = reflectionText + " " + transcriptionText
            return count + combinedText.split(separator: " ").count
        }
        
        return totalWords / journalStore.entries.count
    }
    
    /// Gets a description of the average entry length
    private var averageEntryLengthDescription: String {
        let length = averageEntryLength
        
        if length < 50 {
            return "Your entries are brief and concise"
        } else if length < 150 {
            return "Your entries are of moderate length"
        } else if length < 300 {
            return "Your entries are detailed and thorough"
        } else {
            return "Your entries are very comprehensive"
        }
    }
    
    /// Gets the dominant mood from journal entries
    private var dominantMood: String {
        let moodCounts = Dictionary(grouping: journalStore.entries) { $0.emotionalState }.mapValues { $0.count }
        
        if let (topMood, _) = moodCounts.max(by: { $0.value < $1.value }) {
            return topMood.rawValue.capitalized
        }
        
        return "Neutral"
    }
}

// MARK: - Preview
struct JournalInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        let nudgeManager = AINudgeManager()
        nudgeManager.latestNudge = "Try to reflect on both successes and challenges in your journal entries."
        nudgeManager.learningPattern = .visualLearner
        
        let journalStore = JournalStore()
        
        return JournalInsightsView()
            .environmentObject(nudgeManager)
            .environmentObject(journalStore)
            .environmentObject(ThemeManager())
    }
}
