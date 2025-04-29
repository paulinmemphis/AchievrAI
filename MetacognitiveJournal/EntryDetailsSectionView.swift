// EntryDetailsSectionView.swift
// Extracted from NewEntryView.swift for modularity
import SwiftUI

struct EntryDetailsSectionView: View {
    @Binding var assignmentName: String
    @Binding var selectedSubject: K12Subject
    var isRecording: Bool
    var activeDictationField: DictationField?
    var toggleDictation: (DictationField) -> Void
    var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Entry Details", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundColor(.accentColor)
            HStack {
                TextField("Assignment Name", text: $assignmentName)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .accessibilityLabel("Assignment Name")
                // Dictation Button for Assignment Name
                Button { toggleDictation(.assignmentName) } label: {
                    Image(systemName: isRecording && activeDictationField == .assignmentName ? "stop.circle.fill" : "mic.fill")
                        .foregroundColor(isRecording && activeDictationField == .assignmentName ? .red : .accentColor)
                }
            }
            Picker(selection: $selectedSubject, label: Label("Subject", systemImage: "books.vertical.fill")) {
                ForEach(K12Subject.allCases, id: \..self) { subject in
                    HStack {
                        Image(systemName: subject.icon)
                        Text(subject.rawValue.capitalized)
                    }.tag(subject)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(themeManager.selectedTheme.backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
