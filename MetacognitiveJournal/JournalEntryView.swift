//
//  JournalEntryView 2.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

// File: JournalEntryView.swift
import SwiftUI
import Speech
import Combine

/// View for displaying a single journal entry with reflections and AI insights.
@available(*, deprecated, message: "Use GuidedMultiModalJournalView instead")
struct JournalEntryView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var userProfile: UserProfile
    @State private var editedEntry: JournalEntry
    @State private var isEditing: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var showingReviewRequestSheet: Bool = false
    @State private var reviewMessage: String = ""
    @State private var showingParentFeedbackSheet: Bool = false
    @State private var parentFeedback: String = ""
    
    // Initialize with the original entry and create a copy for editing
    init(entry: JournalEntry) {
        self._editedEntry = State(initialValue: entry)
        self.originalEntry = entry
    }
    
    // Keep a reference to the original entry
    let originalEntry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Action Buttons
                HStack(spacing: 12) {
                    Spacer()
                    
                    // Review Request Button (for children)
                    if userProfile.ageGroup != .parent && !editedEntry.reviewRequested {
                        Button(action: {
                            showingReviewRequestSheet = true
                        }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                Text("Request Review")
                            }
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Provide Feedback Button (for parents)
                    if userProfile.ageGroup == .parent && editedEntry.reviewRequested && !editedEntry.hasBeenReviewed {
                        Button(action: {
                            showingParentFeedbackSheet = true
                        }) {
                            HStack {
                                Image(systemName: "text.bubble")
                                Text("Provide Feedback")
                            }
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Edit/Save Button
                    Button(action: {
                        if isEditing {
                            // Show confirmation before saving
                            showingSaveAlert = true
                        } else {
                            // Enter edit mode
                            isEditing = true
                        }
                    }) {
                        Text(isEditing ? "Save" : "Edit")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeManager.selectedTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
                
                // Subject Header
                if isEditing {
                    HStack {
                        Text("Subject:")
                            .font(.headline)
                        Picker("Subject", selection: $editedEntry.subject) {
                            ForEach(K12Subject.allCases, id: \.self) { subject in
                                Text(subject.rawValue.capitalized).tag(subject)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                } else {
                    Text("Subject: \(editedEntry.subject.rawValue.capitalized)")
                        .font(.headline)
                }

                // Reflection Prompts
                ForEach(editedEntry.reflectionPrompts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(editedEntry.reflectionPrompts[index].prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if isEditing {
                            // Editable response
                            if editedEntry.reflectionPrompts[index].selectedOption != nil {
                                TextField("Your response", text: Binding(
                                    get: { editedEntry.reflectionPrompts[index].selectedOption ?? "" },
                                    set: { editedEntry.reflectionPrompts[index].selectedOption = $0 }
                                ))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            } else if editedEntry.reflectionPrompts[index].response != nil {
                                TextEditor(text: Binding(
                                    get: { editedEntry.reflectionPrompts[index].response ?? "" },
                                    set: { editedEntry.reflectionPrompts[index].response = $0 }
                                ))
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        } else {
                            // Display mode
                            if let selected = editedEntry.reflectionPrompts[index].selectedOption, !selected.isEmpty {
                                Text(selected)
                                    .font(.body)
                            } else if let resp = editedEntry.reflectionPrompts[index].response, !resp.isEmpty {
                                Text(resp)
                                    .font(.body)
                            } else {
                                Text("No response provided.")
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }

                // AI-Generated Summary
                if let aiSummary = editedEntry.aiSummary, !aiSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-Generated Summary")
                            .font(.headline)
                            .padding(.top, 10)
                        Text(aiSummary)
                            .font(.body)
                    }
                }

                // AI Tone Nudge
                if let aiTone = editedEntry.aiTone, !aiTone.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tone-Based Nudge")
                            .font(.headline)
                            .padding(.top, 10)
                        Text(aiTone)
                            .font(.body)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                }
                
                // Audio Transcription
                if let transcription = editedEntry.transcription, !transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voice Journal Transcription")
                            .font(.headline)
                        Text(transcription)
                            .font(.body)
                    }
                    .padding(.bottom, 10)
                }
                
                // Review Request Status
                if editedEntry.reviewRequested {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: editedEntry.hasBeenReviewed ? "checkmark.circle.fill" : "hourglass")
                                .foregroundColor(editedEntry.hasBeenReviewed ? .green : .orange)
                            Text(editedEntry.hasBeenReviewed ? "Review Completed" : "Review Requested")
                                .font(.headline)
                                .foregroundColor(editedEntry.hasBeenReviewed ? .green : .orange)
                        }
                        
                        if let reviewMessage = editedEntry.reviewMessage, !reviewMessage.isEmpty {
                            Text("Request: \(reviewMessage)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let feedback = editedEntry.parentFeedback, !feedback.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Parent Feedback:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(feedback)
                                    .font(.body)
                                    .padding(10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("Save Changes"),
                message: Text("Are you sure you want to save these changes to your journal entry?"),
                primaryButton: .default(Text("Save")) {
                    // Save the edited entry
                    saveChanges()
                    isEditing = false
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    // Stay in edit mode
                }
            )
        }
        .sheet(isPresented: $showingReviewRequestSheet) {
            // Review Request Sheet
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What would you like your parent to review or give feedback on?")
                        .font(.headline)
                        .padding(.top)
                    
                    TextEditor(text: $reviewMessage)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Request Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingReviewRequestSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            submitReviewRequest()
                            showingReviewRequestSheet = false
                        }
                        .disabled(reviewMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingParentFeedbackSheet) {
            // Parent Feedback Sheet
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = editedEntry.reviewMessage, !message.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Child's Request:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(message)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("Your Feedback:")
                        .font(.headline)
                    
                    TextEditor(text: $parentFeedback)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Provide Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingParentFeedbackSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            submitParentFeedback()
                            showingParentFeedbackSheet = false
                        }
                        .disabled(parentFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Function to save changes to the journal store
    private func saveChanges() {
        // Use the updateEntry method from JournalStore to update the entry
        journalStore.updateEntry(editedEntry)
    }
    
    // Function to submit a review request
    private func submitReviewRequest() {
        // Update the edited entry with review request information
        editedEntry.reviewRequested = true
        editedEntry.reviewMessage = reviewMessage
        editedEntry.hasBeenReviewed = false
        editedEntry.parentFeedback = nil
        
        // Save the changes
        saveChanges()
        
        // Reset the review message field
        reviewMessage = ""
    }
    
    // Function to submit parent feedback
    private func submitParentFeedback() {
        // Update the edited entry with parent feedback
        editedEntry.hasBeenReviewed = true
        editedEntry.parentFeedback = parentFeedback
        
        // Save the changes
        saveChanges()
        
        // Reset the parent feedback field
        parentFeedback = ""
    }
}

// MARK: - Preview
// Preview provider
struct JournalEntryView_Previews: PreviewProvider {
    static var sampleEntry: JournalEntry = {
        let prompts = [
            PromptResponse(id: UUID(), prompt: "What was challenging?", options: nil, selectedOption: nil, response: "It was hard", isFavorited: nil, rating: nil),
            PromptResponse(id: UUID(), prompt: "What did you learn?", options: nil, selectedOption: nil, response: nil, isFavorited: nil, rating: nil)
        ]
        return JournalEntry(
            id: UUID(),
            assignmentName: "Sample Assignment",
            date: Date(),
            subject: .math,
            emotionalState: .neutral,
            reflectionPrompts: prompts,
            aiSummary: "You did well on your reflection.",
            aiTone: "Neutral",
            transcription: nil,
            audioURL: nil
        )
    }()

    static var previews: some View {
        NavigationView {
            JournalEntryView(entry: sampleEntry)
                .environmentObject(JournalStore(entries: [sampleEntry]))
                .environmentObject(ThemeManager())
        }
    }
}
