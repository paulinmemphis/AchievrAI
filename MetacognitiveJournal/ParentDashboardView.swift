import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var journalStore: JournalStore
    @State private var receiveAlerts = true
    @State private var receiveWeeklySummary = true
    @State private var reviewRequests: [String] = []
    
    // Heuristic for at-risk detection (can be replaced by AI analysis)
    var atRiskAlertText: String? {
        let concerningKeywords = ["self-harm", "suicide", "hopeless", "worthless", "want to die", "can't go on", "cut myself", "kill myself"]
        let concerningEntry = journalStore.entries.suffix(10).first { entry in
            let text = ((entry.reflectionPrompts.map { $0.response ?? "" } + [entry.aiSummary ?? ""]).joined(separator: " ")).lowercased()
            return concerningKeywords.contains { text.contains($0) }
        }
        if concerningEntry != nil {
            return "Some recent journal entries may indicate your child is at risk of self-harm or experiencing extreme emotional distress. This is not a diagnosis, but we recommend considering professional support or intervention."
        }
        return nil
    }
    var moodSummary: [String] {
        let recent = journalStore.entries.suffix(7)
        return Array(Set(recent.map { $0.emotionalState.rawValue.capitalized }))
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    Text("Parent Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    if let alertText = atRiskAlertText {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Important Alert")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(alertText)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(14)
                        .accessibilityElement(children: .combine)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Mood Summary")
                            .font(.headline)
                        HStack(spacing: 18) {
                            ForEach(moodSummary, id: \.self) { mood in
                                Text(mood)
                                    .font(.title3)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification Settings")
                            .font(.headline)
                        Toggle("Receive alerts for concerning entries", isOn: $receiveAlerts)
                        Toggle("Weekly progress summary", isOn: $receiveWeeklySummary)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 1)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entry Review Requests")
                            .font(.headline)
                        if reviewRequests.isEmpty {
                            Text("No pending review requests.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(reviewRequests, id: \.self) { req in
                                Text(req)
                                    .padding(6)
                                    .background(Color.yellow.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding()
            }
            .navigationTitle("Parent Dashboard")
        }
    }
}

struct ParentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDashboardView().environmentObject(JournalStore())
    }
}
