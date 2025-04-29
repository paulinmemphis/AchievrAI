import SwiftUI
import AVFoundation
import Speech

// Define a simple struct for sheet item identification
struct EntryEditingData: Identifiable {
    let id: UUID // ID of the entry being edited
    let text: String // Initial text (transcript) to populate the editor
}

struct VoiceJournalView: View {
    // Use the AudioRecorder from AudioRecorder.swift, not AudioService.swift
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var journalStore: JournalStore // Inject JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer // Needed for NewEntryView
    @EnvironmentObject private var themeManager: ThemeManager // Add ThemeManager
    @EnvironmentObject var gamificationManager: GamificationManager // Inject GamificationManager
    @EnvironmentObject var coordinator: PsychologicalEnhancementsCoordinator // Inject PsychologicalEnhancementsCoordinator
    @Environment(\.presentationMode) var presentationMode // To dismiss this view
    @Environment(\.scenePhase) var scenePhase
    @State private var showAIJournalEntry = false
    
    // State variables
    @State private var isRecording = false
    @State private var entryDataForEditing: EntryEditingData? = nil // Trigger for sheet
    @State private var transcriptionError: String? = nil // To show errors
    @State private var permissionsGranted = false // Store grant status

    init() {}

    var body: some View {
        NavigationView { 
            VStack(spacing: 24) {
                Text(isRecording ? "Tap to Stop" : "Tap Mic to Record")
                    .font(.title2)
                    .fontWeight(.bold)
                if isRecording {
                    RecordingIndicatorView() // Use a dedicated indicator view
                }
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(isRecording ? .red : .accentColor)
                        .padding(30)
                        .background(Circle().fill(Color.secondary.opacity(0.1)))
                }
                .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
                
                // Display transcription error if any
                // TODO: Make error text color themeable if needed?
                if let error = transcriptionError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Add a save button that appears after recording is complete and transcription is available
                if !isRecording && audioRecorder.transcription.count > 0 {
                    VStack(spacing: 16) {
                        Text("Transcription:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView {
                            Text(audioRecorder.transcription)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                        }
                        .frame(height: 150)
                        
                        Button(action: {
                            // Instead of saving directly, present AIJournalEntryView with the transcribed text
                            showAIJournalEntry = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Continue to Journal Entry")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 8).fill(themeManager.selectedTheme.accentColor))
                            .foregroundColor(.white)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.05)))
                    .padding(.vertical)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills space
            .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea()) // Apply theme background
            .padding()
            .navigationTitle("Voice Note")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            // Present AIJournalEntryView when showAIJournalEntry is true
            .sheet(isPresented: $showAIJournalEntry) {
                NavigationView {
                    AIJournalEntryView(initialText: audioRecorder.transcription)
                        .environmentObject(journalStore)
                        .environmentObject(analyzer)
                        .environmentObject(themeManager)
                        .environmentObject(coordinator)
                        .onDisappear {
                            // Dismiss VoiceJournalView when the AIJournalEntryView sheet is closed
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            }
            // Legacy support for item-based sheet presentation
            .sheet(item: $entryDataForEditing) { data in
                // Redirect to AIJournalEntryView instead of NewEntryView
                NavigationView {
                    AIJournalEntryView(initialText: data.text)
                        .environmentObject(journalStore)
                        .environmentObject(analyzer)
                        .environmentObject(themeManager)
                        .environmentObject(coordinator)
                        .onDisappear {
                            // Dismiss VoiceJournalView when the AIJournalEntryView sheet is closed
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            }
        }
        .onAppear {
            requestPermissions { granted in
                self.permissionsGranted = granted
                print("Permissions requested on appear. Granted: \(granted)")
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            // Show some indicator that transcription is happening
            print("Recording stopped, starting transcription...")
            transcribeAudio()
        } else {
            // Clear previous error
            transcriptionError = nil
            // Start recording - handle potential errors from startRecording
            do {
                try audioRecorder.startRecording()
                isRecording = true
                print("Recording started.")
            } catch {
                 self.transcriptionError = "Failed to start recording: \(error.localizedDescription)"
                 isRecording = false
            }
        }
    }
    
    private func transcribeAudio() {
        audioRecorder.transcribe { result in
            // Create a proper DispatchWorkItem instead of using a trailing closure
            let workItem = DispatchWorkItem {
                switch result {
                case .success(let transcript):
                    if transcript.isEmpty {
                        self.transcriptionError = "Transcription was empty."
                        return
                    }
                    // Store the transcript in the audioRecorder for display
                    self.audioRecorder.transcription = transcript
                    
                case .failure(let error):
                    // Handle transcription error
                    self.transcriptionError = "Transcription failed: \(error.localizedDescription)"
                    print("Detailed transcription error: \(error)")
                }
            }
            // Execute the work item on the main queue
            DispatchQueue.main.async(execute: workItem)
        }
    }
    
    // Save the voice entry as a journal entry
    private func saveVoiceEntry() {
        guard !audioRecorder.transcription.isEmpty else {
            transcriptionError = "No transcription available to save."
            return
        }
        
        // Create a new journal entry
        let entryId = UUID()
        let initialEntry = JournalEntry(
            id: entryId,
            assignmentName: "Voice Note - \(Date().formatted(date: .abbreviated, time: .shortened))",
            date: Date(),
            subject: .other,
            emotionalState: .neutral,
            reflectionPrompts: [
                PromptResponse(
                    id: UUID(),
                    prompt: "Voice Recording",
                    response: audioRecorder.transcription
                )
            ],
            transcription: audioRecorder.transcription,
            audioURL: audioRecorder.audioURL
        )
        
        // Save the entry
        journalStore.saveEntry(initialEntry, audioURL: audioRecorder.audioURL, transcription: audioRecorder.transcription)
        
        // Award gamification points
        gamificationManager.recordJournalEntry()
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Reset the recorder for a new recording
        audioRecorder.transcription = ""
        
        // Dismiss the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Helper Views
struct RecordingIndicatorView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            Text("Recording...")
                .foregroundColor(.red)
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .scaleEffect(scale)
                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: scale)
        }
        .onAppear { self.scale = 1.2 }
    }
}

// MARK: - Preview
struct VoiceJournalView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceJournalView()
            .environmentObject(JournalStore.preview) // Provide preview store
            .environmentObject(ThemeManager()) // Add ThemeManager
            .environmentObject(MetacognitiveAnalyzer()) // Assuming default init or env object injection
            .environmentObject(GamificationManager()) // Inject GamificationManager
            .environmentObject(PsychologicalEnhancementsCoordinator()) // Inject PsychologicalEnhancementsCoordinator
    }
}
