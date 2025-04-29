import SwiftUI

struct MoodTrendBarChart: View {
    let entries: [JournalEntry]
    var moodCounts: [String: Int] {
        let weekEntries = entries.filter { Calendar.current.isDateInThisWeek($0.date) }
        return Dictionary(grouping: weekEntries, by: { $0.emotionalState.rawValue })
            .mapValues { $0.count }
    }
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(moodCounts.sorted(by: { $0.key < $1.key }), id: \ .key) { mood, count in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(for: mood))
                        .frame(width: 28, height: CGFloat(count) * 28)
                    Text(mood.capitalized)
                        .font(.caption2)
                        .rotationEffect(.degrees(-30))
                        .frame(width: 44)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut, value: entries.count)
    }
    func color(for mood: String) -> Color {
        switch mood.lowercased() {
        case "confident": return .green
        case "frustrated": return .red
        case "overwhelmed": return .orange
        case "curious": return .blue
        case "neutral": return .gray
        default: return .accentColor
        }
    }
}

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        guard let weekInterval = self.dateInterval(of: .weekOfYear, for: Date()) else { return false }
        return weekInterval.contains(date)
    }
}
