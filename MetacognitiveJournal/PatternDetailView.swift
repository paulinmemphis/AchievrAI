import SwiftUI
import Charts

/// A view that displays detailed information about a specific journal pattern
struct PatternDetailView: View {
    // MARK: - Properties
    var patternType: JournalInsightsView.PatternType
    var journalStore: JournalStore
    
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Display different content based on pattern type
                    switch patternType {
                    case .frequency:
                        frequencyPatternDetail
                    case .length:
                        lengthPatternDetail
                    case .mood:
                        moodPatternDetail
                    }
                }
                .padding()
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        switch patternType {
        case .frequency:
            return "Journaling Frequency"
        case .length:
            return "Entry Length"
        case .mood:
            return "Emotional Tone"
        }
    }
    
    // MARK: - Pattern Detail Views
    
    private var frequencyPatternDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary section
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let entriesCount = journalStore.entries.count
                let mostFrequentDay = calculateMostFrequentJournalingDay()
                
                Text("You have created \(entriesCount) journal entries.")
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Text("You journal most often on \(mostFrequentDay).")
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                if let streak = calculateCurrentStreak() {
                    Text("Current streak: \(streak) days")
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
            
            Divider()
            
            // Chart section
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Distribution")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let weekdayData = calculateWeekdayDistribution()
                
                Chart {
                    ForEach(weekdayData, id: \.weekday) { item in
                        BarMark(
                            x: .value("Day", item.weekday),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(themeManager.selectedTheme.accentColor.gradient)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            
            Divider()
            
            // Tips section
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                tipCard(
                    icon: "calendar.badge.plus",
                    title: "Consistency is Key",
                    message: "Try to journal at the same time each day to build a habit."
                )
                
                tipCard(
                    icon: "clock",
                    title: "Find Your Best Time",
                    message: "Experiment with journaling at different times to find when you're most reflective."
                )
            }
        }
    }
    
    private var lengthPatternDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary section
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let avgLength = calculateAverageEntryLength()
                
                Text("Your average entry is \(avgLength) words long.")
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let lengthDescription = getLengthDescription(avgLength)
                Text(lengthDescription)
                    .foregroundColor(themeManager.selectedTheme.textColor)
            }
            
            Divider()
            
            // Chart section
            VStack(alignment: .leading, spacing: 8) {
                Text("Entry Length Over Time")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let lengthData = calculateEntryLengthOverTime()
                
                Chart {
                    ForEach(lengthData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Words", item.wordCount)
                        )
                        .foregroundStyle(themeManager.selectedTheme.accentColor.gradient)
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Calculate average length
                    let avgLength = lengthData.map { $0.wordCount }.reduce(0, +) / max(1, lengthData.count)
                    
                    RuleMark(
                        y: .value("Average", avgLength)
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            
            Divider()
            
            // Tips section
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                tipCard(
                    icon: "text.bubble",
                    title: "Quality Over Quantity",
                    message: "Focus on meaningful reflection rather than word count."
                )
                
                tipCard(
                    icon: "list.bullet",
                    title: "Use Prompts",
                    message: "If you're stuck, try using the suggested prompts to inspire deeper reflection."
                )
            }
        }
    }
    
    private var moodPatternDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary section
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let dominantMood = calculateDominantMood()
                
                Text("Your most common emotional state is \(dominantMood).")
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let emotionalBalance = calculateEmotionalBalance()
                Text("Your emotional balance: \(formatPercentage(emotionalBalance))% positive")
                    .foregroundColor(themeManager.selectedTheme.textColor)
            }
            
            Divider()
            
            // Chart section
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Distribution")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let moodData = calculateMoodDistribution()
                
                Chart {
                    ForEach(moodData, id: \.mood) { item in
                        BarMark(
                            x: .value("Mood", item.mood),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(colorForMood(item.mood).gradient)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            
            Divider()
            
            // Mood over time
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Over Time")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                let moodTimeData = calculateMoodOverTime()
                
                Chart {
                    ForEach(moodTimeData, id: \.date) { item in
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Mood", item.moodValue)
                        )
                        .foregroundStyle(colorForMood(item.mood))
                    }
                    
                    // Use individual points for the line mark instead of arrays
                    ForEach(Array(zip(moodTimeData.indices, moodTimeData)), id: \.0) { index, item in
                        if index > 0 {
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Trend", item.moodValue)
                            )
                        }
                    }
                    .foregroundStyle(.gray.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(moodNameForValue(intValue))
                                    .font(.caption)
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            
            Divider()
            
            // Tips section
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                tipCard(
                    icon: "heart.fill",
                    title: "Emotional Awareness",
                    message: "Recognizing your emotional patterns is the first step to managing them."
                )
                
                tipCard(
                    icon: "arrow.up.and.down",
                    title: "Balance is Natural",
                    message: "It's normal to experience a range of emotions. Try to accept all feelings without judgment."
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func tipCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.selectedTheme.accentColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateMostFrequentJournalingDay() -> String {
        let calendar = Calendar.current
        var weekdayCounts: [Int: Int] = [:]
        
        for entry in journalStore.entries {
            let weekday = calendar.component(.weekday, from: entry.date)
            weekdayCounts[weekday, default: 0] += 1
        }
        
        if let mostFrequent = weekdayCounts.max(by: { $0.value < $1.value }) {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            return dateFormatter.weekdaySymbols[mostFrequent.key - 1]
        }
        
        return "No pattern yet"
    }
    
    private func calculateCurrentStreak() -> Int? {
        guard !journalStore.entries.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let sortedEntries = journalStore.entries.sorted(by: { $0.date > $1.date })
        
        var streak = 1
        var currentDate = calendar.startOfDay(for: sortedEntries[0].date)
        let today = calendar.startOfDay(for: Date())
        
        // If the most recent entry is not from today, there's no active streak
        if !calendar.isDate(currentDate, inSameDayAs: today) {
            return nil
        }
        
        for i in 1..<sortedEntries.count {
            let previousDate = calendar.startOfDay(for: sortedEntries[i].date)
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysBetween == 1 {
                streak += 1
                currentDate = previousDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private struct WeekdayData {
        let weekday: String
        let count: Int
    }
    
    private func calculateWeekdayDistribution() -> [WeekdayData] {
        let calendar = Calendar.current
        var weekdayCounts: [Int: Int] = [:]
        
        for entry in journalStore.entries {
            let weekday = calendar.component(.weekday, from: entry.date)
            weekdayCounts[weekday, default: 0] += 1
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        
        return (1...7).map { weekday in
            WeekdayData(
                weekday: dateFormatter.shortWeekdaySymbols[weekday - 1],
                count: weekdayCounts[weekday, default: 0]
            )
        }
    }
    
    private func calculateAverageEntryLength() -> Int {
        guard !journalStore.entries.isEmpty else { return 0 }
        
        let totalWords = journalStore.entries.reduce(0) { total, entry in
            let content = entry.content
            let words = content.split(separator: " ").count
            return total + words
        }
        
        return totalWords / journalStore.entries.count
    }
    
    private func getLengthDescription(_ avgLength: Int) -> String {
        if avgLength < 30 {
            return "Your entries are brief. Consider expanding your thoughts for deeper reflection."
        } else if avgLength < 100 {
            return "Your entries are concise and focused."
        } else if avgLength < 200 {
            return "Your entries are detailed and thoughtful."
        } else {
            return "Your entries are extensive and deeply reflective."
        }
    }
    
    private struct LengthData {
        let date: Date
        let wordCount: Int
    }
    
    private func calculateEntryLengthOverTime() -> [LengthData] {
        let sortedEntries = journalStore.entries.sorted(by: { $0.date < $1.date })
        
        return sortedEntries.map { entry in
            let content = entry.content
            let words = content.split(separator: " ").count
            return LengthData(date: entry.date, wordCount: words)
        }
    }
    
    private func calculateDominantMood() -> String {
        guard !journalStore.entries.isEmpty else { return "Neutral" }
        
        var moodCounts: [EmotionalState: Int] = [:]
        
        for entry in journalStore.entries {
            moodCounts[entry.emotionalState, default: 0] += 1
        }
        
        if let mostFrequent = moodCounts.max(by: { $0.value < $1.value }) {
            return mostFrequent.key.rawValue
        }
        
        return "Neutral"
    }
    
    private func calculateEmotionalBalance() -> Double {
        guard !journalStore.entries.isEmpty else { return 50 }
        
        let positiveEmotions: [EmotionalState] = [.confident, .satisfied, .curious]
        let negativeEmotions: [EmotionalState] = [.confused, .frustrated, .overwhelmed]
        
        var positiveCount = 0
        var negativeCount = 0
        
        for entry in journalStore.entries {
            if positiveEmotions.contains(entry.emotionalState) {
                positiveCount += 1
            } else if negativeEmotions.contains(entry.emotionalState) {
                negativeCount += 1
            }
        }
        
        let total = positiveCount + negativeCount
        guard total > 0 else { return 50 }
        
        return Double(positiveCount) / Double(total) * 100
    }
    
    private func formatPercentage(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }
    
    private struct MoodData {
        let mood: String
        let count: Int
    }
    
    private func calculateMoodDistribution() -> [MoodData] {
        var moodCounts: [String: Int] = [:]
        
        for entry in journalStore.entries {
            let mood = entry.emotionalState.rawValue
            moodCounts[mood, default: 0] += 1
        }
        
        return moodCounts.map { MoodData(mood: $0.key, count: $0.value) }
            .sorted(by: { $0.count > $1.count })
            .prefix(5)
            .map { $0 }
    }
    
    private struct MoodTimeData {
        let date: Date
        let mood: String
        let moodValue: Double
    }
    
    private func calculateMoodOverTime() -> [MoodTimeData] {
        let sortedEntries = journalStore.entries.sorted(by: { $0.date < $1.date })
        
        return sortedEntries.map { entry in
            MoodTimeData(
                date: entry.date,
                mood: entry.emotionalState.rawValue,
                moodValue: moodValueForState(entry.emotionalState)
            )
        }
    }
    
    private func moodValueForState(_ state: EmotionalState) -> Double {
        switch state {
        case .confident:
            return 5.0
        case .satisfied:
            return 4.0
        case .neutral, .curious:
            return 3.0
        case .confused:
            return 2.0
        case .frustrated, .overwhelmed:
            return 1.0
        }
    }
    
    private func moodNameForValue(_ value: Int) -> String {
        switch value {
        case 5:
            return "Very Positive"
        case 4:
            return "Positive"
        case 3:
            return "Neutral"
        case 2:
            return "Negative"
        case 1:
            return "Very Negative"
        default:
            return ""
        }
    }
    
    private func colorForMood(_ mood: String) -> Color {
        if let emotionalState = EmotionalState(rawValue: mood) {
            return emotionalState.color
        }
        return .gray
    }
}

// MARK: - Preview
struct PatternDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PatternDetailView(
            patternType: .frequency,
            journalStore: JournalStore()
        )
        .environmentObject(ThemeManager())
    }
}
