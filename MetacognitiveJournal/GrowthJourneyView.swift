import SwiftUI
import Combine

// Using consolidated model definitions from MCJModels.swift

/// A view that visualizes the user's growth journey over time
struct GrowthJourneyView: View {
    // MARK: - Dependencies
    @ObservedObject var metricsManager: GrowthMetricsManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var narrativeEngineManager: NarrativeEngineManager
    
    // MARK: - State
    @State private var selectedTimeframe: Timeframe = .month
    @State private var showDetailModal: Bool = false
    @State private var selectedMetric: MCJGrowthMetric?
    @State private var animateChart: Bool = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                header
                
                // Timeframe Selector
                timeframeSelector
                
                // Growth Metrics Grid
                metricsGrid
                
                // Journey Visualization
                journeyVisualization
                
                // Growth Milestones
                growthMilestones
            }
            .padding()
        }
        .onAppear {
            // Load metrics for the selected timeframe
            metricsManager.loadGrowthMetrics(for: selectedTimeframe)
            
            // Animate chart after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateChart = true
                }
            }
        }
        .sheet(isPresented: $showDetailModal) {
            if let metric = selectedMetric {
                metricDetailView(metric: metric)
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 10) {
            Text("Your Growth Journey")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text("Track your progress and celebrate your growth over time")
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedTimeframe) { _ in
            withAnimation {
                metricsManager.loadGrowthMetrics(for: selectedTimeframe)
            }
        }
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(metricsManager.metrics) { metric in
                Button {
                    selectedMetric = metric
                    showDetailModal = true
                } label: {
                    metricCard(metric: metric)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Metric Card
    private func metricCard(metric: MCJGrowthMetric) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.iconName)
                    .font(.title3)
                    .foregroundColor(metric.color)
                
                Spacer()
                
                Text(metric.trend > 0 ? "↑" : (metric.trend < 0 ? "↓" : "→"))
                    .font(.headline)
                    .foregroundColor(metric.trend > 0 ? .green : (metric.trend < 0 ? .red : themeManager.selectedTheme.secondaryTextColor))
            }
            
            Text(metric.title)
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .lineLimit(1)
            
            Text(metric.valueFormatted)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text(metric.description)
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
    }
    
    // MARK: - Metric Detail View
    private func metricDetailView(metric: MCJGrowthMetric) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(metric.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Detailed Analysis")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Button {
                    showDetailModal = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            .padding()
            
            // Metric Value
            HStack {
                Image(systemName: metric.iconName)
                    .font(.largeTitle)
                    .foregroundColor(metric.color)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(metric.valueFormatted)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    HStack {
                        Image(systemName: metric.trend > 0 ? "arrow.up" : (metric.trend < 0 ? "arrow.down" : "arrow.forward"))
                        
                        Text("\(abs(Int(metric.trend * 100)))% \(metric.trend > 0 ? "increase" : (metric.trend < 0 ? "decrease" : "no change"))")
                        
                        Text("from previous \(selectedTimeframe.rawValue.lowercased())")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(metric.trend > 0 ? .green : (metric.trend < 0 ? .red : themeManager.selectedTheme.secondaryTextColor))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .padding(.horizontal)
            
            // Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Trend Over Time")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                // Simple line chart
                GeometryReader { geometry in
                    Path { path in
                        // Draw the line chart
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let count = metric.historicalValues.count
                        
                        // Start point
                        let firstPoint = CGPoint(
                            x: 0,
                            y: height - CGFloat(metric.historicalValues.first ?? 0) / 100 * height
                        )
                        path.move(to: firstPoint)
                        
                        // Path points
                        for i in 1..<count {
                            let point = CGPoint(
                                x: width * CGFloat(i) / CGFloat(count - 1),
                                y: height - CGFloat(metric.historicalValues[i]) / 100 * height
                            )
                            path.addLine(to: point)
                        }
                    }
                    .trim(from: 0, to: animateChart ? 1 : 0)
                    .stroke(metric.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(0..<metric.historicalValues.count, id: \.self) { i in
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                            .position(
                                x: geometry.size.width * CGFloat(i) / CGFloat(metric.historicalValues.count - 1),
                                y: geometry.size.height - CGFloat(metric.historicalValues[i]) / 100 * geometry.size.height
                            )
                            .opacity(animateChart ? 1 : 0)
                    }
                }
                .frame(height: 150)
                .padding(.vertical)
                
                // X-axis labels
                HStack {
                    ForEach(getXAxisLabels(for: selectedTimeframe), id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .padding(.horizontal)
            
            // Insights
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                ForEach(metricsManager.generateInsights(for: metric), id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .ignoresSafeArea()
    }
    
    // MARK: - Journey Visualization
    private var journeyVisualization: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Journey Path")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(metricsManager.journeyPoints, id: \.id) { point in
                        VStack(spacing: 15) {
                            // Point indicator
                            ZStack {
                                Circle()
                                    .fill(point.completed ? themeManager.selectedTheme.accentColor : themeManager.selectedTheme.cardBackgroundColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(themeManager.selectedTheme.accentColor, lineWidth: 2)
                                    )
                                
                                if point.completed {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(point.index)")
                                        .font(.headline)
                                        .foregroundColor(themeManager.selectedTheme.textColor)
                                }
                            }
                            
                            // Point title
                            Text(point.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                                .multilineTextAlignment(.center)
                                .frame(width: 120)
                            
                            // Point details
                            if point.completed {
                                Text(point.dateCompleted?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            } else {
                                Text("Upcoming")
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Growth Milestones
    private var growthMilestones: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Growth Milestones")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                ForEach(metricsManager.milestones) { milestone in
                    HStack(alignment: .top) {
                        // Milestone icon
                        Image(systemName: milestone.iconName)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(milestone.achieved ? milestone.color : Color.gray.opacity(0.3))
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(milestone.title)
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Text(milestone.description)
                                .font(.subheadline)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if milestone.achieved, let date = milestone.dateAchieved {
                                Text("Achieved on \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                                    .padding(.top, 2)
                            } else {
                                Text(milestone.progressText)
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                    .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                        
                        if milestone.achieved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(milestone.achieved ? 
                                 milestone.color.opacity(0.1) : 
                                 themeManager.selectedTheme.cardBackgroundColor)
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets X-axis labels based on timeframe
    private func getXAxisLabels(for timeframe: Timeframe) -> [String] {
        switch timeframe {
        case .week:
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case .month:
            return ["Week 1", "Week 2", "Week 3", "Week 4"]
        case .year:
            return ["Jan", "Mar", "May", "Jul", "Sep", "Nov"]
        case .allTime:
            return ["2022", "2023", "2024", "2025"]
        }
    }
}

// MARK: - Supporting Types

/// Timeframe for viewing growth metrics
enum Timeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All Time"
}

// Using MCJGrowthMetric from MCJModels.swift

// Extension to add UI-specific properties to MCJGrowthMetric
extension MCJGrowthMetric {
    var iconName: String {
        switch type {
        case .depth:
            return "chart.bar.fill"
        case .consistency:
            return "calendar.badge.clock"
        case .diversity:
            return "rectangle.3.group.fill"
        case .emotionalGrowth:
            return "heart.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .depth:
            return .blue
        case .consistency:
            return .green
        case .diversity:
            return .purple
        case .emotionalGrowth:
            return .pink
        }
    }
    
    var valueFormatted: String {
        return "\(value)%"
    }
    
    var historicalValues: [Double] {
        // This would normally come from the actual data
        // For now, we'll return a placeholder array
        return [Double(value) * 0.7, Double(value) * 0.8, Double(value) * 0.9, Double(value)]
    }
    
    var trend: Double {
        // Calculate trend from historical values
        return Double(value) * 0.1 // 10% growth as placeholder
    }
}

/// A point on the user's growth journey
struct JourneyPoint: Identifiable {
    let id: String
    let index: Int
    let title: String
    let completed: Bool
    let dateCompleted: Date?
}

/// A growth milestone
struct Milestone: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let achieved: Bool
    let dateAchieved: Date?
    let progress: Int
    let total: Int
    let color: Color
    
    var progressText: String {
        return "Progress: \(progress)/\(total)"
    }
}

// MARK: - Preview
struct GrowthJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        let journalStore = JournalStore()
        let insightStreakManager = InsightStreakManager()
        let gamificationManager = GamificationManager()
        let metricsManager = GrowthMetricsManager(journalStore: journalStore, insightStreakManager: insightStreakManager, gamificationManager: gamificationManager)
        
        return NavigationStack {
            GrowthJourneyView(metricsManager: metricsManager)
                .environmentObject(ThemeManager())
                .environmentObject(NarrativeEngineManager())
        }
    }
}
