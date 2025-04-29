// File: JournalEntryDetailView.swift
import SwiftUICore
import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @EnvironmentObject var journalStore: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedAssignmentName: String
    @State private var editedSubject: K12Subject
    @State private var editedEmotionalState: EmotionalState
    @State private var editedPromptResponses: [PromptResponse]

    init(entry: JournalEntry) {
        self.entry = entry
        _editedAssignmentName = State(initialValue: entry.assignmentName)
        _editedSubject = State(initialValue: entry.subject)
        _editedEmotionalState = State(initialValue: entry.emotionalState)
        _editedPromptResponses = State(initialValue: entry.reflectionPrompts)
    }

    var body: some View {
        Group {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .animation(.default, value: isEditing)
    }

    // MARK: - Display View
    private var displayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                Divider()
                reflectionView
                insightsView
            }
            .padding()
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.assignmentName)
                    .font(.title)
                    .fontWeight(.bold)
                Text(entry.subject.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            emotionalStateView
        }
    }

    private var reflectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(entry.reflectionPrompts) { prompt in
                promptBlock(for: prompt)
            }
        }
    }

    private func promptBlock(for prompt: PromptResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt.prompt)
                .font(.headline)
            if let selected = prompt.selectedOption, !selected.isEmpty {
                Text("Selected: \(selected)")
                    .font(.subheadline)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            Text(prompt.response ?? "")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }

    private var insightsView: some View {
        Group {
            if let aiSummary = entry.aiSummary, !aiSummary.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Insights")
                        .font(.headline)
                    Text(aiSummary)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Editing View
    private var editingView: some View {
        Form {
            Section(header: Text("Assignment Details")) {
                TextField("Assignment Name", text: $editedAssignmentName)
                Picker("Subject", selection: $editedSubject) {
                    ForEach(K12Subject.allCases, id: \.self) { subject in
                        Text(subject.rawValue.capitalized).tag(subject)
                    }
                }
                Picker("Emotional State", selection: $editedEmotionalState) {
                    ForEach(EmotionalState.allCases, id: \.self) { state in
                        Text(state.rawValue.capitalized).tag(state)
                    }
                }
            }

            Section(header: Text("Reflections")) {
                ForEach(0..<editedPromptResponses.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(editedPromptResponses[index].prompt)
                            .font(.headline)
                        if let options = editedPromptResponses[index].options,
                           !options.isEmpty {
                            Picker("Response", selection: Binding(
                                get: { editedPromptResponses[index].selectedOption ?? "" },
                                set: { editedPromptResponses[index].selectedOption = $0 }
                            )) {
                                ForEach(options, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                        }
                        TextEditor(text: Binding(
                            get: { editedPromptResponses[index].response ?? "" },
                            set: { editedPromptResponses[index].response = $0 }
                        ))
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { isEditing = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                    isEditing = false
                }
            }
        }
    }

    private func saveChanges() {
        let updatedEntry = JournalEntry(
            id: entry.id,
            assignmentName: editedAssignmentName,
            date: entry.date,
            subject: editedSubject,
            emotionalState: editedEmotionalState,
            reflectionPrompts: editedPromptResponses,
            aiSummary: entry.aiSummary,
            aiTone: entry.aiTone,
            transcription: entry.transcription,
            audioURL: entry.audioURL
        )
        journalStore.updateEntry(updatedEntry)
    }

    // MARK: - Helpers
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }

    private var emotionalStateView: some View {
        VStack {
            Image(systemName: emotionIcon)
                .font(.title)
                .foregroundColor(emotionColor)
            Text(entry.emotionalState.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(emotionColor)
        }
    }

    private var emotionIcon: String {
        switch entry.emotionalState {
        case .confident: return "checkmark.seal.fill"
        case .neutral: return "equal.circle.fill"
        case .frustrated: return "exclamationmark.triangle.fill"
        case .overwhelmed: return "bolt.fill"
        case .curious: return "magnifyingglass"
        default: return "person.fill"
        }
    }

    private var emotionColor: Color {
        switch entry.emotionalState {
        case .confident: return .green
        case .neutral: return .gray
        case .frustrated: return .red
        case .overwhelmed: return .pink
        case .curious: return .blue
        default: return .primary
        }
    }
}

