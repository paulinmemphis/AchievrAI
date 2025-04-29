import SwiftUI
import Combine

/// A view that displays AI-generated tips and nudges to the user
struct AITipView: View {
    // MARK: - Environment
    @EnvironmentObject private var nudgeManager: AINudgeManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Properties
    let entries: [JournalEntry]
    let onDismiss: (() -> Void)?
    
    // MARK: - State
    @State private var isAnimating = false
    @State private var showDetails = false
    
    // MARK: - Initialization
    init(entries: [JournalEntry], onDismiss: (() -> Void)? = nil) {
        self.entries = entries
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    var body: some View {
        let tip = nudgeManager.latestNudge ?? aiTip
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .font(.title3)
                
                Text("AI Insight")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Button {
                    withAnimation {
                        onDismiss?() ?? nudgeManager.dismissNudge()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Content
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .rotationEffect(Angle(degrees: isAnimating ? 10 : -10))
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(tip)
                        .font(.body)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if showDetails, let pattern = nudgeManager.learningPattern {
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "brain")
                                .foregroundColor(.purple)
                                .font(.caption)
                            
                            Text("Learning style: \(pattern.rawValue)")
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Footer
            HStack {
                Button {
                    withAnimation {
                        showDetails.toggle()
                    }
                } label: {
                    Text(showDetails ? "Hide Details" : "Show Details")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
                
                Spacer()
                
                Button {
                    nudgeManager.scheduleProactiveNudge()
                } label: {
                    Text("New Tip")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - Computed Properties
    
    /// Generates an AI tip if none is available from the nudge manager
    private var aiTip: String {
        // Use the latest AI summary if available, else a generic tip
        if let latest = entries.first?.aiSummary, !latest.isEmpty {
            return latest
        }
        
        let tips = [
            "Try to reflect on both successes and challenges.",
            "Consistent journaling helps build resilience.",
            "Use your journal to set small, achievable goals.",
            "Notice patterns in your moods and thoughts.",
            "Celebrate your progress, no matter how small."
        ]
        
        return tips.randomElement() ?? "Keep reflecting!"
    }
}

// MARK: - Floating AI Tip View

/// A floating version of the AI tip view that appears at the bottom of the screen
struct FloatingAITipView: View {
    @EnvironmentObject private var nudgeManager: AINudgeManager
    @EnvironmentObject private var journalStore: JournalStore
    @State private var offset = CGSize.zero
    
    var body: some View {
        if nudgeManager.showNudge, let _ = nudgeManager.latestNudge {
            VStack {
                Spacer()
                
                AITipView(entries: journalStore.entries)
                    .offset(y: offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.height > 0 {
                                    offset = gesture.translation
                                }
                            }
                            .onEnded { gesture in
                                if gesture.translation.height > 100 {
                                    nudgeManager.dismissNudge()
                                }
                                offset = .zero
                            }
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: nudgeManager.showNudge)
                    .padding(.bottom)
            }
        }
    }
}

// MARK: - AI Nudge History View

/// A view that displays the history of AI nudges
struct AINudgeHistoryView: View {
    @EnvironmentObject private var nudgeManager: AINudgeManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if nudgeManager.nudgeHistory.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(nudgeManager.nudgeHistory) { nudge in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(nudge.text)
                                    .font(.body)
                                    .foregroundColor(themeManager.selectedTheme.textColor)
                                
                                Text(nudge.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Insight History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        nudgeManager.clearNudgeHistory()
                    }
                    .disabled(nudgeManager.nudgeHistory.isEmpty)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(themeManager.selectedTheme.accentColor.opacity(0.5))
            
            Text("No Insights Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text("As you journal, AI insights will appear here to help you reflect and grow.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .padding(.horizontal)
            
            Button {
                nudgeManager.scheduleProactiveNudge()
                dismiss()
            } label: {
                Text("Generate First Insight")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(themeManager.selectedTheme.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct AITipView_Previews: PreviewProvider {
    static var previews: some View {
        let nudgeManager = AINudgeManager()
        nudgeManager.latestNudge = "Try to reflect on both successes and challenges in your journal entries."
        
        return Group {
            AITipView(entries: [])
                .environmentObject(nudgeManager)
                .environmentObject(ThemeManager())
                .previewLayout(.sizeThatFits)
                .padding()
            
            FloatingAITipView()
                .environmentObject(nudgeManager)
                .environmentObject(JournalStore())
                .environmentObject(ThemeManager())
                .onAppear {
                    nudgeManager.showNudge = true
                }
            
            AINudgeHistoryView()
                .environmentObject(nudgeManager)
                .environmentObject(ThemeManager())
        }
    }
}
