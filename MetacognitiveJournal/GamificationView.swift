import SwiftUI

struct GamificationView: View {
    @EnvironmentObject var gamification: GamificationManager
    @EnvironmentObject var journalStore: JournalStore // Keep for mood
    @State private var appearsAnimated = false
    @State private var showBadgeAlert = false

    // Determine the mood from the latest journal entry
    private var currentMood: String {
        // Sort entries by date descending and get the first one
        guard let latestEntry = journalStore.entries.sorted(by: { $0.date > $1.date }).first else {
            return "neutral" // Default mood if no entries
        }
        // Convert EmotionalState enum to the String expected by MascotView
        return latestEntry.emotionalState.rawValue
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 28) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Level Display
            levelSection
                .padding(.bottom, 10) // Slightly reduce bottom padding
            
            // Streak and Badge Count
            statsSection
                .padding(.horizontal)
            
            Divider()
            
            // Badges Section
            badgesSection
                .padding(.horizontal)
            
            Spacer()
            MascotView(mood: currentMood)
                .padding(.bottom)
        }
        .onChange(of: gamification.badges) { newValue, oldValue in
            // Check if a *new* badge was added to trigger the alert
            // This simple check might trigger if badges are reordered, a more robust check might be needed
            // if badges can be removed or reordered.
            if gamification.badges.count > (gamification.badges.count - 1) { // Simplified logic, assumes badges only increase
                showBadgeAlert = true
            }
        }
        .alert(isPresented: $showBadgeAlert) {
            Alert(title: Text("New Badge Earned!"),
                  message: Text("Congratulations! You've earned a new badge. Check your Progress tab."),
                  dismissButton: .default(Text("Awesome!")))
        }
        .opacity(appearsAnimated ? 1 : 0) // Apply fade-in opacity
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { // Animate the fade-in
                appearsAnimated = true
            }
        }
        .animation(.easeInOut, value: gamification.level) // Animate level changes
        .animation(.easeInOut, value: gamification.points) // Animate points changes
        .animation(.easeInOut, value: gamification.streak) // Animate streak changes
        .animation(.easeInOut, value: gamification.badges) // Animate badge list changes
    }

    // MARK: - View Components

    private var levelSection: some View {
        VStack {
            Text("Level \(gamification.level)")
                .font(.largeTitle)
                .fontWeight(.bold)
            ProgressView(value: Double(gamification.points), total: Double(gamification.pointsNeededForLevel)) {
                Text("\(gamification.points) / \(gamification.pointsNeededForLevel) XP")
            }
            .animation(.easeInOut, value: gamification.points) // Animate progress bar specifically
            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            .padding(.horizontal)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 24) { // Reduced spacing
            VStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Streak")
                    .font(.caption)
                Text("\(gamification.streak) days")
                    .font(.title)
                    .fontWeight(.medium)
            }
            VStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                Text("Badges")
                    .font(.caption)
                Text("\(gamification.badges.count)")
                    .font(.title)
                    .fontWeight(.medium)
            }
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading) {
            Text("Badges Earned")
                .font(.headline)
                .padding(.bottom, 4)
            
            if gamification.badges.isEmpty {
                Text("Keep journaling to earn badges!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                // Use horizontal scrolling instead of FlowLayout for badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(gamification.badges, id: \.self) { badgeId in
                            BadgeView(badgeId: badgeId)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews (e.g., Badge View)
struct BadgeView: View {
    @EnvironmentObject var gamification: GamificationManager
    let badgeId: String

    var body: some View {
        let details = gamification.badgeDetails(for: badgeId)
        VStack {
            Image(systemName: details.icon)
                .font(.system(size: 36))
                .foregroundColor(.purple)
                .frame(width: 50, height: 50)
                .background(Color.purple.opacity(0.1))
                .clipShape(Circle())
            Text(details.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80) // Give each badge item a consistent width
    }
}

// MARK: - Preview
struct GamificationView_Previews: PreviewProvider {
    static var previews: some View {
        GamificationView()
            .environmentObject(GamificationManager()) // Provide GamificationManager for preview
            .environmentObject(JournalStore.preview) // Provide JournalStore for preview
    }
}
