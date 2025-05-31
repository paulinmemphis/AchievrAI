import SwiftUI
import Combine

/// A view that displays journey progress information including streaks, completion statistics, and optimal timing
struct JourneyProgressView: View {
    // MARK: - Dependencies
    @ObservedObject var insightStreakManager: InsightStreakManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - State
    @State private var optimalTimeShown: Bool = false
    @State private var showingCompletionStats: Bool = false
    @State private var animateProgress: Bool = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Streak Card
            streakCard
            
            // Completion Window Card
            completionWindowCard
            
            // Optimal Time Card
            optimalTimeCard
        }
        .padding()
        .onAppear {
            // Animate progress bars when view appears
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - Streak Card
    private var streakCard: some View {
        VStack(spacing: 15) {
            HStack {
                Label("Insight Streak", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Button {
                    // Show streak info
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(insightStreakManager.currentStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                
                Text(" days")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .padding(.leading, 4)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                    
                    Text("\(insightStreakManager.longestStreak) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
            .padding(.top, 5)
            
            // Progress to next milestone
            let nextMilestone = calculateNextMilestone()
            let progress = calculateMilestoneProgress(nextMilestone: nextMilestone)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to \(nextMilestone) days")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(insightStreakManager.currentStreak)/\(nextMilestone)")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.selectedTheme.backgroundColor.opacity(0.5))
                            .frame(width: geometry.size.width, height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(themeManager.selectedTheme.accentColor)
                            .frame(width: geometry.size.width * (animateProgress ? progress : 0), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10)
        )
    }
    
    // MARK: - Completion Window Card
    private var completionWindowCard: some View {
        VStack(spacing: 15) {
            HStack {
                Label("12-Hour Window", systemImage: "clock.fill")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showingCompletionStats.toggle()
                    }
                } label: {
                    Image(systemName: showingCompletionStats ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                }
            }
            
            if let hoursRemaining = insightStreakManager.hoursRemainingToMaintainStreak() {
                VStack(spacing: 10) {
                    Text("\(hoursRemaining) hours")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(hoursRemainingColor(hours: hoursRemaining))
                    
                    Text("remaining to continue your streak")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                // Progress bar for time remaining
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.selectedTheme.backgroundColor.opacity(0.5))
                            .frame(width: geometry.size.width, height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(hoursRemainingColor(hours: hoursRemaining))
                            .frame(width: geometry.size.width * (animateProgress ? timeRemainingProgress(hours: hoursRemaining) : 0), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            } else {
                Text("Start your insight journey to see the completion window")
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
            }
            
            if showingCompletionStats {
                VStack(spacing: 12) {
                    Divider()
                        .background(themeManager.selectedTheme.textColor.opacity(0.3))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Consistency")
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                            
                            Text("93%")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Entries this week")
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                            
                            Text("5/7 days")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                        }
                    }
                    
                    HStack {
                        Text("Entries completed in optimal window")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                        
                        Spacer()
                        
                        Text("86%")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                    }
                }
                .padding(.top, 5)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10)
        )
    }
    
    // MARK: - Optimal Time Card
    private var optimalTimeCard: some View {
        VStack(spacing: 15) {
            HStack {
                Label("Your Optimal Time", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Button {
                    withAnimation {
                        optimalTimeShown.toggle()
                    }
                } label: {
                    Text(optimalTimeShown ? "Hide" : "View")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            
            if optimalTimeShown {
                VStack(spacing: 15) {
                    Text("Based on your activity patterns, your optimal time for reflection is:")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("8:30 PM")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                    
                    HStack(spacing: 20) {
                        // Add id: \.self to explicitly identify elements
                        ForEach(0..<7, id: \.self) { day in
                            VStack(spacing: 4) {
                                Text(dayLetter(for: day))
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                                
                                Circle()
                                    .fill(isDayActive(day) ? themeManager.selectedTheme.accentColor : themeManager.selectedTheme.backgroundColor)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Button {
                        // Schedule notification
                    } label: {
                        Label("Set Reminder", systemImage: "bell.fill")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeManager.selectedTheme.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                HStack {
                    Text("View your personalized optimal reflection time")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(themeManager.selectedTheme.imageColor.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the next milestone based on current streak
    private func calculateNextMilestone() -> Int {
        let streak = insightStreakManager.currentStreak
        if streak < 3 { return 3 }
        if streak < 7 { return 7 }
        if streak < 14 { return 14 }
        if streak < 30 { return 30 }
        if streak < 60 { return 60 }
        if streak < 100 { return 100 }
        return ((streak / 100) + 1) * 100 // Next 100 milestone
    }
    
    /// Calculates progress to next milestone (0-1)
    private func calculateMilestoneProgress(nextMilestone: Int) -> CGFloat {
        let streak = insightStreakManager.currentStreak
        let previousMilestone = getPreviousMilestone(currentMilestone: nextMilestone)
        let range = nextMilestone - previousMilestone
        let progress = streak - previousMilestone
        
        return min(1.0, max(0.0, CGFloat(progress) / CGFloat(range)))
    }
    
    /// Gets the previous milestone
    private func getPreviousMilestone(currentMilestone: Int) -> Int {
        switch currentMilestone {
        case 3: return 0
        case 7: return 3
        case 14: return 7
        case 30: return 14
        case 60: return 30
        case 100: return 60
        default:
            if currentMilestone > 100 {
                return (currentMilestone / 100 - 1) * 100
            }
            return 0
        }
    }
    
    /// Calculates the progress for time remaining (0-1)
    private func timeRemainingProgress(hours: Int) -> CGFloat {
        // 48 hours total window
        return CGFloat(48 - hours) / 48.0
    }
    
    /// Returns color based on hours remaining
    private func hoursRemainingColor(hours: Int) -> Color {
        if hours < 4 {
            return .red
        } else if hours < 12 {
            return .orange
        } else {
            return themeManager.selectedTheme.accentColor
        }
    }
    
    /// Gets the day letter for given weekday index
    private func dayLetter(for day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day]
    }
    
    /// Determines if a day is active in optimal schedule
    private func isDayActive(_ day: Int) -> Bool {
        // Example: All days except weekend are active
        return day < 5
    }
}

// MARK: - Preview
struct JourneyProgressView_Previews: PreviewProvider {
    static var previews: some View {
        JourneyProgressView(insightStreakManager: InsightStreakManager())
            .environmentObject(ThemeManager())
            .padding()
    }
}
