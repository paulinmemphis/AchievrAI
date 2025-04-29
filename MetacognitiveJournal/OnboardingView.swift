// File: OnboardingView.swift
// MetacognitiveJournal

import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingRole") private var onboardingRole: String?
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @EnvironmentObject private var userProfile: UserProfile

    @State private var showStudent = false
    @State private var showParent = false
    @State private var showTeacher = false
    @State private var currentPage = 0
    @State private var hasSeenRoleSelection = false
    @State private var hasSeenAgeSelection = false
    @State private var selectedAgeGroup: AgeGroup = .child
    
    // Enhanced onboarding pages with more detailed content and corresponding images
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to AchievrAI",
            subtitle: "Your personal metacognitive journal",
            description: "AchievrAI helps you reflect on your learning, track your progress, and grow your metacognitive skills.",
            imageName: "onboarding-welcome",
            systemImage: "lightbulb.fill",
            backgroundColor: .blue
        ),
        OnboardingPage(
            title: "Capture Your Thoughts",
            subtitle: "Journal your learning experiences",
            description: "Use text or voice to record your thoughts, feelings, and reflections about your learning process.",
            imageName: "onboarding-journal",
            systemImage: "text.book.closed.fill",
            backgroundColor: .purple
        ),
        OnboardingPage(
            title: "Gain Emotional Insights",
            subtitle: "Understand your emotions and growth",
            description: "AI-powered analytics help you discover your emotional balance, reflection depth, and receive personalized feedback to support your learning journey.",
            imageName: "onboarding-insights",
            systemImage: "face.smiling.fill",
            backgroundColor: .green
        ),
        OnboardingPage(
            title: "Turn Journals into Stories",
            subtitle: "Personalized narrative chapters",
            description: "Each journal entry becomes a chapter in your own story, complete with engaging cliffhangers and feedback to inspire you.",
            imageName: "onboarding-transform",
            systemImage: "book.closed.fill",
            backgroundColor: .orange
        ),
        OnboardingPage(
            title: "Explore Your Story Map",
            subtitle: "Visualize your learning journey",
            description: "See your progress as a zoomable story map, connecting your chapters and showing your unique path of growth.",
            imageName: "onboarding-storymap",
            systemImage: "map.fill",
            backgroundColor: .teal
        )
    ]

    var body: some View {
        if isOnboardingComplete {
            EmptyView()
        } else if showStudent {
            // Accessibility: announce onboarding completion
            EmptyView().improvedAccessibility(label: "Onboarding complete. Welcome to the app.")
        
            // Route to age-appropriate student onboarding
            if userProfile.ageGroup == .child {
                StudentOnboardingView(isComplete: $isOnboardingComplete, ageGroup: userProfile.ageGroup)
                // Child-friendly onboarding
            } else if userProfile.ageGroup == .teen {
                StudentOnboardingView(isComplete: $isOnboardingComplete, ageGroup: userProfile.ageGroup)
                // Teen-focused onboarding
            } else {
                StudentOnboardingView(isComplete: $isOnboardingComplete, ageGroup: userProfile.ageGroup)
                // Default onboarding for other students
            }
        } else if showParent || userProfile.ageGroup == .parent {
            ParentOnboardingView(isComplete: $isOnboardingComplete)
            // TODO: Customize parent onboarding here
        } else if showTeacher {
            TeacherOnboardingView(isComplete: $isOnboardingComplete)
        } else {
            ZStack {
                pages[currentPage].backgroundColor.opacity(0.1).ignoresSafeArea()
                if !hasSeenAgeSelection {
                    ageGroupSelectionView
                } else if !hasSeenRoleSelection {
                    welcomeView
                } else {
                    OnboardingPagerView(
                        currentPage: $currentPage,
                        pages: pages,
                        onFinish: {
                            withAnimation { hasSeenRoleSelection = false }
                        }
                    )
                    .transition(.slide)
                }
            }
        }
    }
    
    // Welcome screen with role selection
    private var ageGroupSelectionView: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "person.3.sequence.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
            Text("How old are you?")
                .font(.title2)
                .fontWeight(.semibold)
            Picker("Select your age group", selection: $selectedAgeGroup) {
                ForEach(AgeGroup.allCases.filter { $0 != .parent }, id: \ .self) { group in
                    Text(group.displayName).tag(group)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            Button(action: {
                userProfile.setAgeGroup(selectedAgeGroup)
                withAnimation { hasSeenAgeSelection = true }
            }) {
                Text("Continue")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
        .transition(.opacity)
    }

    private var welcomeView: some View {
        VStack(spacing: 40) {
            // App logo and title
            VStack(spacing: 16) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.1)))
                
                Text("Welcome to AchievrAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("The metacognitive journal for deeper learning")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Learn more button
            Button(action: {
                withAnimation {
                    hasSeenRoleSelection = true
                }
            }) {
                Text("Learn More")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.bottom, 20)
            
            // Role selection section
            VStack(spacing: 16) {
                Text("Who are you?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    
                HStack(spacing: 20) {
                    // Student role button
                    RoleSelectionButton(
                        role: "Student",
                        icon: "graduationcap.fill",
                        color: .blue,
                        action: {
                            onboardingRole = "student"
                            showStudent = true
                        }
                    )
                    
                    // Parent role button
                    RoleSelectionButton(
                        role: "Parent",
                        icon: "person.2.fill",
                        color: .green,
                        action: {
                            onboardingRole = "parent"
                            showParent = true
                        }
                    )
                    
                    // Teacher role button
                    RoleSelectionButton(
                        role: "Teacher",
                        icon: "book.fill",
                        color: .purple,
                        action: {
                            onboardingRole = "teacher"
                            showTeacher = true
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let systemImage: String
    let backgroundColor: Color
}
