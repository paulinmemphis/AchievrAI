import SwiftUI

struct SubjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedSubject: K12Subject
    
    var body: some View {
        NavigationView {
            List {
                ForEach(K12Subject.allCases, id: \.self) { subject in
                    Button(action: {
                        selectedSubject = subject
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: subjectIcon(for: subject))
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                            
                            Text(subject.rawValue)
                                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                            
                            Spacer()
                            
                            if subject == selectedSubject {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Subject")
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
    
    func subjectIcon(for subject: K12Subject) -> String {
        switch subject {
        case .math:
            return "function"
        case .science:
            return "atom"
        case .english:
            return "book"
        case .history:
            return "clock"
        case .art:
            return "paintpalette"
        case .music:
            return "music.note"
        case .computerScience:
            return "desktopcomputer"
        case .physicalEducation:
            return "figure.walk"
        case .foreignLanguage:
            return "globe"
        case .socialStudies:
            return "person.2"
        case .biology:
            return "leaf"
        case .chemistry:
            return "flask"
        case .physics:
            return "bolt"
        case .geography:
            return "map"
        case .economics:
            return "chart.bar"
        case .writing:
            return "pencil"
        case .reading:
            return "text.book.closed"
        case .other:
            return "questionmark.circle"
        }
    }
}
