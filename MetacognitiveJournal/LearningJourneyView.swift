// File: LearningJourneyView.swift
import SwiftUI

/// Displays a visualization of the user's learning journey across journal entries
struct LearningJourneyView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var journalStore: JournalStore
    @StateObject private var insightAnalyzer: InsightAnalyzer
    
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedSubject: K12Subject?
    @State private var isLoading = false
    
    init() {
        // We'll initialize the analyzer in init and then use @StateObject to manage its lifecycle
        _insightAnalyzer = StateObject(wrappedValue: InsightAnalyzer(journalStore: JournalStore()))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Learning Journey")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        Text("Discover patterns and insights from your reflections")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                    }
                    .padding(.horizontal)
                    
                    // Filter controls
                    HStack {
                        Picker("Time", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(themeManager.selectedTheme.backgroundColor.opacity(0.3))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Menu {
                            Button("All Subjects") {
                                selectedSubject = nil
                            }
                            
                            Divider()
                            
                            ForEach(K12Subject.allCases, id: \.self) { subject in
                                Button(subject.rawValue) {
                                    selectedSubject = subject
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedSubject?.rawValue ?? "All Subjects")
                                Image(systemName: "chevron.down")
                            }
                            .padding(8)
                            .background(themeManager.selectedTheme.backgroundColor.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Subject progression section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject Progression")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        SubjectProgressionChart(entries: filteredEntries)
                            .frame(height: 200)
                            .padding()
                            .background(themeManager.selectedTheme.backgroundColor.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Emotional journey section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emotional Journey")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        EmotionalJourneyView(entries: filteredEntries)
                            .frame(height: 180)
                            .padding()
                            .background(themeManager.selectedTheme.backgroundColor.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await insightAnalyzer.analyzePatterns()
                        }
                    }) {
                        Text("Refresh")
                    }
                }
            }
            .onAppear {
                Task {
                    await insightAnalyzer.analyzePatterns()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filtered entries based on selected time range and subject
    private var filteredEntries: [JournalEntry] {
        var entries = journalStore.entries
        
        // Filter by time range
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .last7Days:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            entries = entries.filter { $0.date >= startDate }
        case .last30Days:
            let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
            entries = entries.filter { $0.date >= startDate }
        case .last3Months:
            let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            entries = entries.filter { $0.date >= startDate }
        case .allTime:
            // No filtering needed
            break
        }
        
        // Filter by subject if selected
        if let subject = selectedSubject {
            entries = entries.filter { $0.subject == subject }
        }
        
        return entries.sorted(by: { $0.date < $1.date })
    }
}

// MARK: - Supporting Views

/// Chart showing subject progression over time
struct SubjectProgressionChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entries: [JournalEntry]
    
    var body: some View {
        if entries.isEmpty {
            Text("No entries available for the selected time period")
                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Simple placeholder for a chart
            // In a real implementation, this would use Swift Charts or another charting library
            VStack {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(subjectCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { subject, count in
                        VStack {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForSubject(subject))
                                .frame(width: 30, height: CGFloat(count) * 20)
                            
                            Text(subject.rawValue)
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: 40)
                                .rotationEffect(.degrees(-45))
                                .offset(y: 20)
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal)
                
                Text("Number of entries by subject")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
            }
        }
    }
    
    /// Counts entries by subject
    private var subjectCounts: [K12Subject: Int] {
        Dictionary(grouping: entries, by: { $0.subject })
            .mapValues { $0.count }
    }
    
    /// Returns a color for a subject
    private func colorForSubject(_ subject: K12Subject) -> Color {
        switch subject {
        case .math:
            return .blue
        case .science:
            return .green
        case .english:
            return .purple
        case .history:
            return .orange
        case .socialStudies:
            return .brown
        case .computerScience:
            return .cyan
        case .art:
            return .pink
        case .music:
            return .indigo
        case .physicalEducation:
            return .mint
        case .foreignLanguage:
            return .teal
        case .biology:
            return .green.opacity(0.7)
        case .chemistry:
            return .yellow
        case .physics:
            return .blue.opacity(0.7)
        case .geography:
            return .brown.opacity(0.7)
        case .economics:
            return .gray
        case .writing:
            return .purple.opacity(0.7)
        case .reading:
            return .red
        case .other:
            return .secondary
            return .yellow
        case .physicalEducation:
            return .red
        case .computerScience:
            return .cyan
        case .foreignLanguage:
            return .indigo
        case .other:
            return .gray
        }
    }
}

/// View showing emotional journey over time
struct EmotionalJourneyView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entries: [JournalEntry]
    
    var body: some View {
        if entries.isEmpty {
            Text("No entries available for the selected time period")
                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Simple placeholder for an emotional journey visualization
            // In a real implementation, this would use Swift Charts or another charting library
            VStack {
                HStack(alignment: .center, spacing: 4) {
                    ForEach(entries.sorted(by: { $0.date < $1.date })) { entry in
                        VStack {
                            Text(emotionEmojiFor(entry.emotionalState))
                                .font(.title)
                            
                            Text(formatDate(entry.date))
                                .font(.caption2)
                                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                                .rotationEffect(.degrees(-45))
                                .offset(y: 8)
                        }
                    }
                }
                .padding(.bottom, 20)
                
                Text("Emotional states over time")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
            }
        }
    }
    
    /// Returns an emoji for an emotional state
    private func emotionEmojiFor(_ state: EmotionalState) -> String {
        switch state {
        case .overwhelmed:
            return "😫"
        case .frustrated:
            return "😤"
        case .confused:
            return "😕"
        case .neutral:
            return "😐"
        case .curious:
            return "🤔"
        case .satisfied:
            return "😊"
        case .confident:
            return "😎"
        @unknown default:
            return "❓"
        }
    }
    
    /// Formats a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

/// Time ranges for filtering
enum TimeRange: String, CaseIterable {
    case last7Days
    case last30Days
    case last3Months
    case allTime
    
    var displayName: String {
        switch self {
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        case .last3Months:
            return "Last 3 Months"
        case .allTime:
            return "All Time"
        }
    }
}

// MARK: - Preview
struct LearningJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock JournalStore for preview
        let mockJournalStore = JournalStore()
        
        return LearningJourneyView()
            .environmentObject(ThemeManager())
            .environmentObject(mockJournalStore)
    }
}
