import SwiftUI

struct SubjectsView: View {
    @EnvironmentObject var journalStore: JournalStore

    // Group entries by subject
    private var subjectGroups: [K12Subject: [JournalEntry]] {
        Dictionary(grouping: journalStore.entries, by: \.subject)
    }

    // Sort subjects by the number of entries, descending
    private var sortedSubjects: [K12Subject] {
        subjectGroups
            .map { (subject: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .map { $0.subject }
    }

    var body: some View {
        NavigationView {
            if sortedSubjects.isEmpty {
                EmptyInsightsView()
            } else {
                List {
                    ForEach(sortedSubjects, id: \.self) { subject in
                        let entries = subjectGroups[subject] ?? []
                        NavigationLink(subject.rawValue) {
                            SubjectDetailView(subject: subject, entries: entries)
                        }
                    }
                }
                .navigationTitle("Subjects")
            }
        }
    }
}

struct SubjectDetailView: View {
    let subject: K12Subject
    let entries: [JournalEntry]

    var body: some View {
        List(entries) { entry in
            Text(entry.assignmentName)
        }
        .navigationTitle(subject.rawValue)
    }
}

