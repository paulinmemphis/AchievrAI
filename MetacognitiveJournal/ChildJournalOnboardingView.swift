import SwiftUI
import Combine
import AVFoundation

/// Onboarding view for child users that determines age and reading level
struct ChildJournalOnboardingView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var childAge: Int = 10
    @State private var readingLevel: ReadingLevel = .grade3to4
    @State private var name: String = ""
    @State private var avatarSelection: String = "avatar1"
    @State private var currentStep: OnboardingStep = .welcome
    @State private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Properties
    let availableAvatars = ["avatar1", "avatar2", "avatar3", "avatar4", "avatar5", "avatar6"]
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Progress indicator
            ProgressView(value: Double(currentStep.rawValue), total: Double(OnboardingStep.allCases.count))
                .padding()
            
            // Content based on current step
            switch currentStep {
            case .welcome:
                welcomeView
            case .nameAndAge:
                nameAndAgeView
            case .readingLevel:
                readingLevelView
            case .avatarSelection:
                avatarSelectionView
            case .complete:
                completeView
            }
            
            // Navigation buttons
            HStack {
                if currentStep != .welcome {
                    Button("Back") {
                        withAnimation {
                            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
                        }
                        playSound("button_tap")
                    }
                    .buttonStyle(RoundedButtonStyle(color: themeManager.selectedTheme.accentColor.opacity(0.2)))
                }
                
                Spacer()
                
                Button(currentStep == .complete ? "Start Journaling" : "Next") {
                    withAnimation {
                        if currentStep == .complete {
                            saveUserProfile()
                            dismiss()
                        } else {
                            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .complete
                        }
                    }
                    playSound("button_tap")
                }
                .buttonStyle(RoundedButtonStyle(color: themeManager.selectedTheme.accentColor))
            }
            .padding()
        }
        .padding()
        .background(themeManager.selectedTheme.backgroundColor)
        .onAppear {
            playSound("welcome")
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image("journal_mascot")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .accessibility(label: Text("Friendly journal mascot"))
            
            Text("Welcome to Your Journal Adventure!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .multilineTextAlignment(.center)
            
            Text("This is your special place to share thoughts, feelings, and adventures!")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Read to me") {
                // Text-to-speech functionality
                let utterance = AVSpeechUtterance(string: "Welcome to Your Journal Adventure! This is your special place to share thoughts, feelings, and adventures!")
                utterance.rate = 0.5
                utterance.pitchMultiplier = 1.2
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
            }
            .buttonStyle(RoundedButtonStyle(color: themeManager.selectedTheme.accentColor))
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private var nameAndAgeView: some View {
        VStack(spacing: 20) {
            Text("Let's get to know you!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            VStack(alignment: .leading) {
                Text("What's your name?")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                TextField("Your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18, design: .rounded))
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("How old are you?")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                HStack {
                    Slider(value: Binding(
                        get: { Double(childAge) },
                        set: { childAge = Int($0) }
                    ), in: 6...16, step: 1)
                    .accentColor(themeManager.selectedTheme.accentColor)
                    
                    Text("\(childAge)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                        .frame(width: 50)
                }
                
                // Age visualization
                HStack(spacing: 5) {
                    ForEach(6...16, id: \.self) { age in
                        Circle()
                            .fill(age <= childAge ? themeManager.selectedTheme.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private var readingLevelView: some View {
        VStack(spacing: 20) {
            Text("Let's find the right reading level")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            Text("Try reading this sentence:")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            // Sample text based on current selection
            Text(readingLevel.description)
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.5))
                )
            
            Button("Read to me") {
                // Text-to-speech functionality
                let utterance = AVSpeechUtterance(string: readingLevel.description)
                utterance.rate = 0.5
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
            }
            .buttonStyle(RoundedButtonStyle(color: themeManager.selectedTheme.accentColor))
            .padding(.bottom)
            
            Text("How easy was that to read?")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            // Reading level selection
            HStack {
                ForEach(ReadingLevel.allCases, id: \.self) { level in
                    Button(action: {
                        readingLevel = level
                        playSound("button_tap")
                    }) {
                        VStack {
                            Text(level.description)
                                .font(.system(size: 12, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(readingLevel == level ? 
                                      themeManager.selectedTheme.accentColor : 
                                      themeManager.selectedTheme.cardBackgroundColor)
                        )
                        .foregroundColor(readingLevel == level ? .white : themeManager.selectedTheme.primaryTextColor)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private var avatarSelectionView: some View {
        VStack(spacing: 20) {
            Text("Choose your journal buddy")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            Text("This friend will join you on your journaling adventure!")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            // Avatar grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(availableAvatars, id: \.self) { avatar in
                    Button(action: {
                        avatarSelection = avatar
                        playSound("avatar_select")
                    }) {
                        Image(avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding()
                            .background(
                                Circle()
                                    .fill(avatarSelection == avatar ? 
                                          themeManager.selectedTheme.accentColor.opacity(0.2) : 
                                          Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(avatarSelection == avatar ? 
                                            themeManager.selectedTheme.accentColor : 
                                            Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private var completeView: some View {
        VStack(spacing: 20) {
            Image(avatarSelection)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding()
            
            Text("You're all set, \(name)!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            Text("Your journal is ready for your amazing thoughts and adventures.")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            // Summary of settings
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Age:")
                        .fontWeight(.bold)
                    Text("\(childAge) years old")
                }
                
                HStack {
                    Text("Reading Level:")
                        .fontWeight(.bold)
                    Text(readingLevel.description)
                }
                
                HStack {
                    Text("Journal Buddy:")
                        .fontWeight(.bold)
                    Text(avatarSelection.capitalized)
                }
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.5))
            )
            
            // Confetti animation
            ChildJournalLottieView(name: "confetti")
                .frame(height: 100)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 5)
        )
        .padding()
        .onAppear {
            playSound("success")
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveUserProfile() {
        let userProfile = ChildUserProfile(
            name: name,
            age: childAge,
            readingLevel: readingLevel,
            avatarImage: avatarSelection
        )
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "childUserProfile")
        }
        
        // Set the appropriate journal mode based on age
        let journalMode: ChildJournalMode = {
            switch childAge {
            case 6...8:
                return .earlyChildhood
            case 9...12:
                return .middleChildhood
            default:
                return .adolescent
            }
        }()
        
        UserDefaults.standard.set(journalMode.rawValue, forKey: "childJournalMode")
    }
    
    private func playSound(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case nameAndAge
    case readingLevel
    case avatarSelection
    case complete
}

struct ChildUserProfile: Codable {
    let name: String
    let age: Int
    let readingLevel: ReadingLevel
    let avatarImage: String
    
    enum CodingKeys: String, CodingKey {
        case name, age, readingLevel, avatarImage
    }
    
    init(name: String, age: Int, readingLevel: ReadingLevel, avatarImage: String) {
        self.name = name
        self.age = age
        self.readingLevel = readingLevel
        self.avatarImage = avatarImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        readingLevel = try container.decode(ReadingLevel.self, forKey: .readingLevel)
        avatarImage = try container.decode(String.self, forKey: .avatarImage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(readingLevel, forKey: .readingLevel)
        try container.encode(avatarImage, forKey: .avatarImage)
    }
}

struct RoundedButtonStyle: SwiftUI.ButtonStyle {
    let color: Color
    
    func makeBody(configuration: SwiftUI.ButtonStyleConfiguration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct ChildJournalLottieView: UIViewRepresentable {
    let name: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // In a real implementation, this would use Lottie animations
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the Lottie animation if needed
    }
}

struct ChildJournalOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ChildJournalOnboardingView()
            .environmentObject(ThemeManager())
    }
}
