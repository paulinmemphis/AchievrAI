import SwiftUI

struct AITipView: View {
    let entries: [JournalEntry]
    var body: some View {
        let tip = aiTip
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
                .font(.title2)
            Text(tip)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(14)
    }
    var aiTip: String {
        // Placeholder: Use the latest AI summary if available, else a generic tip
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
