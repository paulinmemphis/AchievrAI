import SwiftUI
import Combine
import Charts

/// A dashboard view for parents to monitor their child's journaling activity and well-being
struct ParentDashboardView: View {
    // MARK: - Environment
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var aiNudgeManager: AINudgeManager
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    
    // MARK: - State
    @State private var receiveAlerts = true
    @State private var receiveWeeklySummary = true
    @State private var requireAppLogin = false
    @State private var requirePasswordLogin = false
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedTab = 0
    @State private var showingResourcesSheet = false
    @State private var showingChildProfileSheet = false
    @State private var animateCharts = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingEntryDetail = false
    @State private var selectedBirthday = Date()
    @State private var selectedAgeGroup: AgeGroup = .child
    @State private var reviewRequests: [String] = []
    
    // MARK: - Enums
    
    /// Represents different time frames for data analysis
    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Detects concerning content in journal entries
    var atRiskAlertText: String? {
        // Define concerning keywords
        let concerningKeywords = ["self-harm", "suicide", "hopeless", "worthless", "want to die", "can't go on", "cut myself", "kill myself"]
        
        // Get recent entries (last 10)
        let recentEntries = journalStore.entries.suffix(10)
        
        // Check each entry for concerning content
        for entry in recentEntries {
            // Get all text from the entry
            let responses = entry.reflectionPrompts.compactMap { $0.response }
            let aiSummary = entry.aiSummary ?? ""
            let allText = (responses + [aiSummary]).joined(separator: " ").lowercased()
            
            // Check if any concerning keywords are present
            for keyword in concerningKeywords {
                if allText.contains(keyword) {
                    return "Some recent journal entries may indicate your child is at risk of self-harm or experiencing extreme emotional distress. This is not a diagnosis, but we recommend considering professional support or intervention."
                }
            }
        }
        
        return nil
    }
    
    /// Gets the recent mood summary
    var moodSummary: [MoodData] {
        let recent = journalStore.entries.suffix(selectedTimeframe.days)
        let moodCounts = Dictionary(grouping: recent) { $0.emotionalState }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return moodCounts.prefix(5).map { mood, count in
            MoodData(mood: mood.rawValue.capitalized, count: count, color: mood.color)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Dashboard Header
                    dashboardHeader
                    
                    // Alert Section
                    if let alertText = atRiskAlertText {
                        alertSection(alertText: alertText)
                    }
                    
                    // Mood Summary Section
                    moodSummarySection
                    
                    // Settings Section
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Parent Dashboard")
            .sheet(isPresented: $showingResourcesSheet) {
                ResourcesView()
            }
            .sheet(isPresented: $showingChildProfileSheet) {
                DashboardProfileView(birthday: $selectedBirthday, ageGroup: $selectedAgeGroup)
            }
            .onAppear {
                // Animate charts after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        animateCharts = true
                    }
                }
                
                // Load the current app login setting
                requireAppLogin = parentalControlManager.isLoginRequired()
                
                // Load the current password login setting
                requirePasswordLogin = parentalControlManager.getPasswordLoginRequired()
            }
            .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
        }
    }
    
    // MARK: - View Components
    
    /// Dashboard header view
    private var dashboardHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    
                    Text("Parent")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            
            Text("Here's how your child is doing")
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    /// Alert section view
    private func alertSection(alertText: String) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Important Alert")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(alertText)
                        .font(.body)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Button {
                showingResourcesSheet = true
            } label: {
                HStack {
                    Text("View Mental Health Resources")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.1))
                .shadow(color: Color.red.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Mood summary section view
    private var moodSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Emotional State Analysis")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Text("Last \(selectedTimeframe.days) days")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
            
            if moodSummary.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.largeTitle)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor.opacity(0.5))
                        
                        Text("No mood data available")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                HStack {
                    ForEach(moodSummary) { mood in
                        VStack {
                            Text(mood.mood)
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Text("\(mood.count)")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(mood.color)
                                .frame(height: CGFloat(mood.count * 10 + 20))
                                .scaleEffect(animateCharts ? 1.0 : 0.1, anchor: .bottom)
                                .animation(Animation.spring(), value: animateCharts)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    /// Settings section view
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Toggle(isOn: $receiveAlerts) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Concerning Content Alerts")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Get notified about potentially concerning journal entries")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: themeManager.selectedTheme.accentColor))
            
            Divider()
            
            Toggle(isOn: $receiveWeeklySummary) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Progress Summary")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Receive a weekly summary of your child's journaling activity")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: themeManager.selectedTheme.accentColor))
            
            Divider()
            
            Toggle(isOn: $requireAppLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Require App Login")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Require biometric authentication (Face ID/Touch ID) to access the app")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: themeManager.selectedTheme.accentColor))
            .onChange(of: requireAppLogin) { _, newValue in
                parentalControlManager.setAppLoginRequired(newValue)
            }
            
            Divider()
            
            Toggle(isOn: $requirePasswordLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Require Password Login")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text("Require password authentication at app startup to protect journal entries")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: themeManager.selectedTheme.accentColor))
            .onChange(of: requirePasswordLogin) { _, newValue in
                parentalControlManager.setPasswordLoginRequired(newValue)
            }
            
            Divider()
            
            Button {
                showingChildProfileSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Child Profile Settings")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        Text("Set or change your child's age or birthday")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Resources View

/// A view that displays mental health resources
struct ResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Crisis Resources")) {
                    resourceLink(
                        title: "National Suicide Prevention Lifeline",
                        description: "24/7, free and confidential support",
                        phone: "1-800-273-8255"
                    )
                    
                    resourceLink(
                        title: "Crisis Text Line",
                        description: "Text HOME to 741741",
                        phone: nil
                    )
                }
                
                Section(header: Text("Youth Mental Health")) {
                    resourceLink(
                        title: "Child Mind Institute",
                        description: "Resources for children's mental health",
                        phone: nil
                    )
                    
                    resourceLink(
                        title: "National Alliance on Mental Illness (NAMI)",
                        description: "Support for families and individuals",
                        phone: "1-800-950-6264"
                    )
                }
                
                Section(header: Text("Important Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When to Seek Help")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        Text("If your child's journal entries show persistent negative thoughts, hopelessness, or mentions of self-harm, it's important to seek professional help.")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        
                        Text("Remember that this app is not a diagnostic tool and cannot replace professional mental health services.")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resourceLink(title: String, description: String, phone: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text(description)
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            if let phone = phone {
                Button {
                    let phoneURL = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))")!
                    UIApplication.shared.open(phoneURL)
                } label: {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Dashboard Profile View

/// A simplified profile view for the dashboard
struct DashboardProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var userProfile: UserProfile
    
    @Binding var birthday: Date
    @Binding var ageGroup: AgeGroup
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Child's Birthday")) {
                    DatePicker(
                        "Birthday",
                        selection: $birthday,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section(header: Text("Age Group")) {
                    Picker("Age Group", selection: $ageGroup) {
                        Text("Child (6-12)").tag(AgeGroup.child)
                        Text("Teen (13-17)").tag(AgeGroup.teen)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Save Changes") {
                        userProfile.setBirthday(birthday)
                        userProfile.setAgeGroup(ageGroup)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            .navigationTitle("Child Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

/// Represents mood data for visualization
struct MoodData: Identifiable {
    let id = UUID()
    let mood: String
    let count: Int
    let color: Color
}

/// Represents frequency data for visualization
struct FrequencyData: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}
