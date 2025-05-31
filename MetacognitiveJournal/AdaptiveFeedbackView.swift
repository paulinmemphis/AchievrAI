import SwiftUI

/// View for displaying adaptive feedback to children
struct AdaptiveFeedbackView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    let feedback: AdaptiveFeedback
    let onChallengeAccepted: ((MetacognitiveChallenge) -> Void)?
    let onSupportSelected: ((LearningSupport) -> Void)?
    let onDismiss: (() -> Void)?
    
    // MARK: - State
    @State private var showingChallenge = false
    @State private var showingSupport = false
    @State private var showingFollowUp = false
    @State private var selectedFollowUpIndex = 0
    @State private var animateContent = false
    @State private var showConfetti = false
    
    // MARK: - Initialization
    init(feedback: AdaptiveFeedback, 
         onChallengeAccepted: ((MetacognitiveChallenge) -> Void)? = nil,
         onSupportSelected: ((LearningSupport) -> Void)? = nil,
         onDismiss: (() -> Void)? = nil) {
        self.feedback = feedback
        self.onChallengeAccepted = onChallengeAccepted
        self.onSupportSelected = onSupportSelected
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Header
                feedbackHeader
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Main feedback message
                        mainFeedbackContent
                        
                        // Supporting details if available
                        if let details = feedback.supportingDetails {
                            supportingDetailsView(details)
                        }
                        
                        // Celebration of progress if available
                        if let celebration = feedback.celebratedProgress {
                            celebrationView(celebration)
                        }
                        
                        // Follow-up prompts if available and showing
                        if showingFollowUp, let followUps = feedback.followUpPrompts, !followUps.isEmpty {
                            followUpView(followUps)
                        }
                        
                        // Strategy suggestions if available
                        if let strategies = feedback.suggestedStrategies, !strategies.isEmpty {
                            strategiesView(strategies)
                        }
                        
                        // Challenge preview if available
                        if let challenge = feedback.challenge {
                            challengePreviewView(challenge)
                        }
                        
                        // Learning support preview if available
                        if let support = feedback.learningSupport {
                            supportPreviewView(support)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                // Action buttons
                actionButtons
            }
            .padding()
            
            // Confetti animation for celebration
            if showConfetti {
                confettiView
            }
            
            // Challenge detail sheet
            if showingChallenge, let challenge = feedback.challenge {
                challengeDetailView(challenge)
            }
            
            // Support detail sheet
            if showingSupport, let support = feedback.learningSupport {
                supportDetailView(support)
            }
        }
        .onAppear {
            // Animate content in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) {
                    animateContent = true
                }
            }
            
            // Show confetti for celebration feedback
            if feedback.feedbackType == .celebrationOfProgress {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
            
            // Automatically show follow-up after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showingFollowUp = true
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var feedbackHeader: some View {
        HStack {
            // Icon
            Image(systemName: feedback.feedbackType.iconName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(feedback.feedbackType.color)
                )
                .shadow(radius: 2)
            
            // Title
            VStack(alignment: .leading) {
                Text(feedbackTypeTitle)
                    .font(fontForAge(size: 18, weight: .bold))
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                
                if feedback.feedbackType == .celebrationOfProgress {
                    Text("You're making great progress!")
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                withAnimation {
                    onDismiss?()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Main Content View
    
    private var mainFeedbackContent: some View {
        Text(feedback.content)
            .font(fontForAge(size: 16))
            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(feedback.feedbackType.color.opacity(0.1))
            )
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
    }
    
    // MARK: - Supporting Views
    
    private func supportingDetailsView(_ details: String) -> some View {
        Text(details)
            .font(fontForAge(size: 14))
            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
    }
    
    private func celebrationView(_ celebration: String) -> some View {
        VStack {
            Text("🎉 " + celebration + " 🎉")
                .font(fontForAge(size: 16, weight: .medium))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow, lineWidth: 2)
                                .opacity(0.5)
                        )
                )
        }
        .padding(.vertical, 4)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private func followUpView(_ followUps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Think about...")
                .font(fontForAge(size: 14, weight: .medium))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            ForEach(0..<min(followUps.count, 2), id: \.self) { index in
                HStack(alignment: .top) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(feedback.feedbackType.color)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    
                    Text(followUps[index])
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private func strategiesView(_ strategies: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Helpful strategies:")
                .font(fontForAge(size: 14, weight: .medium))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            ForEach(strategies, id: \.self) { strategy in
                HStack(alignment: .top) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    
                    Text(strategy)
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private func challengePreviewView(_ challenge: MetacognitiveChallenge) -> some View {
        Button(action: {
            withAnimation {
                showingChallenge = true
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try this challenge:")
                        .font(fontForAge(size: 14, weight: .medium))
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    
                    Text(challenge.title)
                        .font(fontForAge(size: 16, weight: .bold))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                    
                    Text(challenge.description)
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(challenge.targetSkill.color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(challenge.targetSkill.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(challenge.targetSkill.color, lineWidth: 1)
                            .opacity(0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private func supportPreviewView(_ support: LearningSupport) -> some View {
        Button(action: {
            withAnimation {
                showingSupport = true
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning support:")
                        .font(fontForAge(size: 14, weight: .medium))
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    
                    Text(support.title)
                        .font(fontForAge(size: 16, weight: .bold))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                    
                    Text("Tap to learn more")
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: support.supportType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                            .opacity(0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack {
            // Challenge button if available
            if let challenge = feedback.challenge {
                Button(action: {
                    withAnimation {
                        showingChallenge = true
                    }
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Try Challenge")
                    }
                    .font(fontForAge(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(challenge.targetSkill.color)
                    )
                }
            }
            
            // Support button if available
            if let support = feedback.learningSupport {
                Button(action: {
                    withAnimation {
                        showingSupport = true
                    }
                }) {
                    HStack {
                        Image(systemName: support.supportType.iconName)
                        Text("Get Help")
                    }
                    .font(fontForAge(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: {
                withAnimation {
                    onDismiss?()
                }
            }) {
                Text("Got it!")
                    .font(fontForAge(size: 14, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(themeManager.selectedTheme.accentColor, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Detail Views
    
    private func challengeDetailView(_ challenge: MetacognitiveChallenge) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingChallenge = false
                    }
                }
            
            // Challenge card
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(challenge.title)
                            .font(fontForAge(size: 20, weight: .bold))
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        
                        HStack {
                            Image(systemName: challenge.targetSkill.iconName)
                                .foregroundColor(challenge.targetSkill.color)
                            
                            Text(challenge.targetSkill.childFriendlyName)
                                .font(fontForAge(size: 14))
                                .foregroundColor(challenge.targetSkill.color)
                            
                            Spacer()
                            
                            Text(challenge.difficulty.description(for: feedback.developmentalLevel))
                                .font(fontForAge(size: 12))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingChallenge = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                // Description
                Text(challenge.description)
                    .font(fontForAge(size: 16))
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                
                // Time estimate
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    
                    Text("About \(challenge.estimatedTimeMinutes) minutes")
                        .font(fontForAge(size: 14))
                        .foregroundColor(.gray)
                }
                
                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Challenge Steps:")
                        .font(fontForAge(size: 16, weight: .medium))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                    
                    ForEach(Array(challenge.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(fontForAge(size: 14, weight: .bold))
                                .foregroundColor(challenge.targetSkill.color)
                            
                            Text(step)
                                .font(fontForAge(size: 14))
                                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(challenge.targetSkill.color.opacity(0.1))
                )
                
                // Completion prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("After you finish:")
                        .font(fontForAge(size: 14, weight: .medium))
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    
                    Text(challenge.completionPrompt)
                        .font(fontForAge(size: 14))
                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical)
                
                // Action buttons
                HStack {
                    Button(action: {
                        withAnimation {
                            showingChallenge = false
                        }
                    }) {
                        Text("Maybe Later")
                            .font(fontForAge(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingChallenge = false
                            onChallengeAccepted?(challenge)
                        }
                    }) {
                        Text("Start Challenge")
                            .font(fontForAge(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(challenge.targetSkill.color)
                            )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .shadow(radius: 10)
            .padding()
        }
    }
    
    private func supportDetailView(_ support: LearningSupport) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingSupport = false
                    }
                }
            
            // Support card
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(support.title)
                            .font(fontForAge(size: 20, weight: .bold))
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        
                        HStack {
                            Image(systemName: support.supportType.iconName)
                                .foregroundColor(.blue)
                            
                            Text(support.supportType.rawValue)
                                .font(fontForAge(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingSupport = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                // Visual aid if available
                if let visualAid = support.visualAid {
                    HStack {
                        Spacer()
                        
                        Image(systemName: visualAid)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Spacer()
                    }
                }
                
                // Main content
                Text(support.content)
                    .font(fontForAge(size: 16))
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                // Example scenario if available
                if let example = support.exampleScenario {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example:")
                            .font(fontForAge(size: 14, weight: .medium))
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        
                        Text(example)
                            .font(fontForAge(size: 14))
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.selectedTheme.backgroundColor)
                            )
                    }
                }
                
                // Practice activity if available
                if let practice = support.practiceActivity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try this:")
                            .font(fontForAge(size: 14, weight: .medium))
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        
                        Text(practice)
                            .font(fontForAge(size: 14))
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                // Action buttons
                HStack {
                    Button(action: {
                        withAnimation {
                            showingSupport = false
                        }
                    }) {
                        Text("Close")
                            .font(fontForAge(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingSupport = false
                            onSupportSelected?(support)
                        }
                    }) {
                        Text("Try This Strategy")
                            .font(fontForAge(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
            )
            .shadow(radius: 10)
            .padding()
        }
    }
    
    // MARK: - Confetti View
    
    private var confettiView: some View {
        // In a real app, this would be a proper confetti animation
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.random)
                    .frame(width: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var feedbackTypeTitle: String {
        switch feedback.feedbackType {
        case .encouragement:
            return "Keep Going!"
        case .metacognitiveInsight:
            return "Thinking Insight"
        case .emotionalAwareness:
            return "Emotional Awareness"
        case .growthOpportunity:
            return "Growth Opportunity"
        case .strategyRecommendation:
            return "Strategy Suggestion"
        case .celebrationOfProgress:
            return "Celebration!"
        case .reflectionPrompt:
            return "Think About This"
        case .supportiveIntervention:
            return "Learning Support"
        }
    }
    
    private func fontForAge(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch feedback.developmentalLevel {
        case .earlyChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

// MARK: - Preview
struct AdaptiveFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        AdaptiveFeedbackView(
            feedback: AdaptiveFeedback(
                childId: "child1",
                journalEntryId: UUID(),
                feedbackType: .metacognitiveInsight,
                content: "I noticed you were thinking about how you solved that math problem! That's called metacognition - thinking about your thinking. This is a super important skill that helps your brain grow stronger.",
                supportingDetails: "When you pay attention to how you solve problems, you can use those strategies again in the future.",
                followUpPrompts: [
                    "What strategy helped you the most?",
                    "When else might you use this approach?"
                ],
                suggestedStrategies: [
                    "Break problems into smaller steps",
                    "Draw a picture of the problem",
                    "Explain your thinking out loud"
                ],
                celebratedProgress: nil,
                challenge: MetacognitiveChallenge(
                    title: "Strategy Detective",
                    description: "Investigate which strategies work best for you",
                    steps: [
                        "Choose a learning task (like memorizing information)",
                        "Try three different strategies (like visualization, repetition, teaching someone)",
                        "Rate how well each strategy worked for you",
                        "Write about which strategy worked best and why"
                    ],
                    targetSkill: .evaluating,
                    difficulty: .explorer,
                    estimatedTimeMinutes: 20,
                    completionPrompt: "How will knowing your best strategies help you in the future?"
                ),
                learningSupport: nil,
                developmentalLevel: .middleChildhood
            )
        )
        .environmentObject(ThemeManager())
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
