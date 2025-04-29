// File: VoiceJournalEntryView.swift
// File: VoiceJournalEntryView.swift
import SwiftUI

/// A view for voice-based journal entries: plays prompts, records responses, and transcribes them.
struct VoiceJournalEntryView: View {
    @StateObject private var vm: VoiceJournalViewModel
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var analyzer: MetacognitiveAnalyzer
    @Environment(\.dismiss) private var dismiss

    /// Initialize with list of prompts
    init(prompts: [String]) {
        _vm = StateObject(wrappedValue: VoiceJournalViewModel(prompts: prompts))
    }
    


    // State for showing save confirmation
    @State private var showSaveConfirmation = false
    @State private var savedEntryTitle = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text(vm.currentPrompt)
                .font(.title2)
                .padding()

            Button(action: {
                if vm.isRecording {
                    vm.finishRecording()
                } else {
                    requestPermissions { granted in
                        guard granted else { return }
                        vm.startRecording()
                    }
                }
            }) {
                Text(vm.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            TextEditor(text: $vm.transcribedText)
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            HStack {
                Button("Next Prompt") {
                    vm.nextPrompt()
                }
                .disabled(vm.currentPromptIndex + 1 >= vm.prompts.count)

                Spacer()

                Button("Finish") {
                    // Use the existing save method
                    vm.saveCurrentEntry(in: journalStore)
                    dismiss()
                }
                .disabled(vm.transcribedText.isEmpty)

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle("Voice Journal")
        .onAppear {
            vm.speakPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("JournalEntrySaved"))) { notification in
            if let title = notification.object as? String {
                savedEntryTitle = title
                showSaveConfirmation = true
            }
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Entry Saved"),
                message: Text("Your voice journal entry has been saved."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}


