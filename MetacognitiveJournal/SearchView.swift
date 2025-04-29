import SwiftUI

struct SearchView: View {
    @EnvironmentObject var journalStore: JournalStore
    @State private var query: String = ""
    @State private var selectedEmotion: EmotionalState? = nil
    @State private var selectedSubject: K12Subject? = nil
    @State private var selectedDate: Date? = nil
    
    // State variables for sharing
    @State private var selectedEntryForShare: JournalEntry? = nil
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextField("Search entries...", text: $query)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Picker("Emotion", selection: $selectedEmotion) {
                            Text("All Emotions").tag(EmotionalState?.none)
                            ForEach(EmotionalState.allCases, id: \.self) { emotion in
                                Text(emotion.rawValue.capitalized).tag(EmotionalState?.some(emotion))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        Picker("Subject", selection: $selectedSubject) {
                            Text("All Subjects").tag(K12Subject?.none)
                            ForEach(K12Subject.allCases, id: \.self) { subject in
                                Text(subject.rawValue.capitalized).tag(K12Subject?.some(subject))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        DatePicker("Date", selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }),
                            displayedComponents: [.date])
                        .labelsHidden()
                        Button(action: { selectedDate = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Clear Date Filter")
                        }
                    }
                    .padding(.horizontal)
                }
                List {
                    ForEach(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.assignmentName)
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    selectedEntryForShare = entry
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .imageScale(.medium)
                                        .accessibilityLabel("Export or Share Entry")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            HStack(spacing: 8) {
                                Text(entry.subject.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                Text(entry.emotionalState.rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(entry.date, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Search & Filter")
            }
        }
    }
    var filteredEntries: [JournalEntry] {
        journalStore.entries.filter { entry in
            (query.isEmpty || entry.assignmentName.localizedCaseInsensitiveContains(query) || (entry.aiSummary ?? "").localizedCaseInsensitiveContains(query)) &&
            (selectedEmotion == nil || entry.emotionalState == selectedEmotion) &&
            (selectedSubject == nil || entry.subject == selectedSubject) &&
            (selectedDate == nil || Calendar.current.isDate(entry.date, inSameDayAs: selectedDate!))
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView().environmentObject(JournalStore())
    }
}
