import SwiftUI
import AVFoundation
import Speech

// Define a simple struct for sheet item identification
struct EntryEditingData: Identifiable {
    let id: UUID // ID of the entry being edited
    let text: String // Initial text (transcript) to populate the editor
}

struct VoiceJournalView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var journalStore: JournalStore // Inject JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer // Needed for NewEntryView
    @EnvironmentObject private var themeManager: ThemeManager // Add ThemeManager
    @EnvironmentObject var gamificationManager: GamificationManager // Inject GamificationManager
    @Environment(\.presentationMode) var presentationMode // To dismiss this view
    @Environment(\.scenePhase) var scenePhase
    
    // State variables
    @State private var isRecording = false
    @State private var entryDataForEditing: EntryEditingData? = nil // Trigger for sheet
    @State private var transcriptionError: String? = nil // To show errors
    @State private var permissionsGranted = false // Store grant status

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
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills space
            .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea()) // Apply theme background
            .padding()
            .navigationTitle("Voice Note")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            // Use .sheet(item:...) to present NewEntryView when entryDataForEditing is set
            .sheet(item: $entryDataForEditing) { data in
                // Pass the initial data and necessary environment objects
                NewEntryView(initialEntryData: data)
                    .environmentObject(journalStore)
                    .environmentObject(analyzer)
                    .onDisappear { 
                        // Dismiss VoiceJournalView when the NewEntryView sheet is closed
                        presentationMode.wrappedValue.dismiss()
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
            DispatchQueue.main.async { // Ensure UI updates are on main thread
                switch result {
                case .success(let transcript):
                    if transcript.isEmpty {
                        self.transcriptionError = "Transcription was empty."
                        return
                    }
                    // Create initial entry
                    let entryId = UUID() // Generate ID once
                    let initialEntry = JournalEntry(
                        id: entryId, // Provide necessary fields
                        assignmentName: "", // Default: Empty String
                        date: Date(),
                        subject: .other, // Default: .other
                        emotionalState: .neutral, // Default: .neutral
                        reflectionPrompts: [], // Default: Empty Array
                        transcription: transcript // Use the 'transcription' field
                    )
                    // Save the initial entry
                    journalStore.saveEntry(initialEntry) // Use the correct method name
                    // Award gamification points
                    gamificationManager.recordJournalEntry()
                    // Set data to trigger the sheet
                    self.entryDataForEditing = EntryEditingData(id: entryId, text: transcript)
                    
                case .failure(let error):
                    // Handle transcription error
                    self.transcriptionError = "Transcription failed: \(error.localizedDescription)"
                    print("Detailed transcription error: \(error)")
                }
            }
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
    }
}
