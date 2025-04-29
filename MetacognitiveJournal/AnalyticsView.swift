import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    
    // Computed properties to fix compilation errors
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var mostCommonWords: [String: Double] {
        extractMostCommonWords()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    Text("Weekly Mood Trend")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    MoodTrendBarChart(entries: journalStore.entries)
                        .frame(height: 180)
                        .padding(.horizontal)
                    HStack(spacing: 32) {
                        StatCard(title: "Current Streak", value: "\(currentStreak)", icon: "flame.fill", color: .orange)
                        StatCard(title: "Total Entries", value: "\(journalStore.entries.count)", icon: "book.closed.fill", color: .blue)
                    }
                    .padding(.horizontal)
                    Text("Reflection Word Cloud")
                        .font(.headline)
                    if mostCommonWords.isEmpty {
                        EmptyWordCloudView()
                            .padding(.horizontal)
                    } else {
                        WordCloudView(words: Array(mostCommonWords.keys))
                            .frame(height: 100)
                            .padding(.horizontal)
                    }
                    Text("AI-Powered Tip")
                        .font(.headline)
                        .padding(.top)
                    AITipView(entries: journalStore.entries)
                        .padding(.horizontal)
                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Insights & Analytics")
        }
    }
}

// MARK: - Helper Methods
extension AnalyticsView {
    /// Calculate the current streak of consecutive days with entries
    private func calculateCurrentStreak() -> Int {
        guard !journalStore.entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = journalStore.entries.map { $0.date }.sorted(by: >)
        
        var streak = 1
        var lastDate = calendar.startOfDay(for: sortedDates[0])
        
        for i in 1..<sortedDates.count {
            let currentDate = calendar.startOfDay(for: sortedDates[i])
            let daysBetween = calendar.dateComponents([.day], from: currentDate, to: lastDate).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                streak += 1
                lastDate = currentDate
            } else if daysBetween == 0 {
                // Same day, continue checking
                lastDate = currentDate
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    /// Extract the most common words from journal entries for the word cloud
    private func extractMostCommonWords() -> [String: Double] {
        // Return empty dictionary if no entries
        guard !journalStore.entries.isEmpty else { return [:] }
        
        let allText = journalStore.entries.flatMap { entry in
            entry.reflectionPrompts.compactMap { $0.response }
        }.joined(separator: " ")
        
        // Split into words and count frequencies
        let words = allText.lowercased()
            .components(separatedBy: .punctuationCharacters).joined()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 3 } // Filter out short words
        
        let commonStopWords = ["this", "that", "with", "from", "have", "were", "what", "when", "where", "which", "while", "would", "could", "should", "their", "there", "about"]
        
        var wordCounts: [String: Int] = [:]
        for word in words {
            if !commonStopWords.contains(word) {
                wordCounts[word, default: 0] += 1
            }
        }
        
        // Convert to format needed for word cloud (word: size)
        let maxCount = wordCounts.values.max() ?? 1
        var result: [String: Double] = [:]
        
        for (word, count) in wordCounts.sorted(by: { $0.value > $1.value }).prefix(30) {
            // Normalize size between 10 and 40
            let size = 10 + (Double(count) / Double(maxCount) * 30)
            result[word] = size
        }
        
        return result
    }
}

// Empty placeholder to show when there's no data
struct EmptyWordCloudView: View {
    var body: some View {
        Text("Not enough data for word cloud")
            .foregroundColor(.secondary)
            .italic()
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(JournalStore())
            .environmentObject(MetacognitiveAnalyzer())
    }
}
