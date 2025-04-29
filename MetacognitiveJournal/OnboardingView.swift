// File: OnboardingView.swift
// MetacognitiveJournal

import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingRole") private var onboardingRole: String?
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false

    @State private var showStudent = false
    @State private var showParent = false
    @State private var showTeacher = false
    @State private var currentPage = 0 // Added state for current page
    
    // Added placeholder onboarding pages
    let pages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to Achievr AI", subtitle: "Your personal metacognitive journal."),
        OnboardingPage(title: "Reflect & Grow", subtitle: "Track your learning process and understand your progress."),
        OnboardingPage(title: "Get Started", subtitle: "Let's begin your journey to better learning.")
    ]

    var body: some View {
        if isOnboardingComplete {
            EmptyView()
        } else if showStudent {
            StudentOnboardingView(isComplete: $isOnboardingComplete)
        } else if showParent {
            ParentOnboardingView(isComplete: $isOnboardingComplete)
        } else if showTeacher {
            TeacherOnboardingView(isComplete: $isOnboardingComplete)
        } else {
            VStack(spacing: 32) {
                Text("Welcome to AchievrAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Who are you?")
                    .font(.title2)
                    .foregroundColor(.secondary)
                HStack(spacing: 20) {
                    Button(action: {
                        onboardingRole = "student"
                        showStudent = true
                    }) {
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                            Text("Student")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(12)
                    }
                    Button(action: {
                        onboardingRole = "parent"
                        showParent = true
                    }) {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                            Text("Parent")
                        }
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(12)
                    }
                    Button(action: {
                        onboardingRole = "teacher"
                        showTeacher = true
                    }) {
                        VStack {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                            Text("Teacher")
                        }
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 20)
                Spacer()
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isOnboardingComplete = false // Assuming false means show main app?
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}

struct OnboardingPage: Identifiable { // Added Identifiable conformance
    let id = UUID() // Added id for Identifiable
    let title: String
    let subtitle: String
}
