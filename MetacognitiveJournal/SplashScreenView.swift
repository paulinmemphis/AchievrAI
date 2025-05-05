import SwiftUI
import AVFoundation

/// A splash screen view that displays an animated logo with sound when the app starts
struct SplashScreenView: View {
    // MARK: - Properties
    @State private var scale = 0.3
    @State private var opacity = 0.0
    @State private var rotation = -30.0
    @State private var textOpacity = 0.0
    @State private var isAnimationComplete = false
    @State private var audioPlayer: AVAudioPlayer?
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Callback for when animation completes
    var onAnimationComplete: () -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.selectedTheme.backgroundColor,
                    themeManager.selectedTheme.accentColor.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App logo animation
                Image("Image") // Using the image from the asset catalog
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)
                
                // App name with typewriter effect
                Text("AchievrAI")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .opacity(textOpacity)
                
                // Tagline
                Text("Your story, one chapter at a time")
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            // Play startup sound
            playStartupSound()
            
            // Animate logo
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0
            }
            
            // Animate text with delay
            withAnimation(.easeIn.delay(0.4)) {
                textOpacity = 1.0
            }
            
            // Trigger completion after animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    textOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimationComplete = true
                    onAnimationComplete()
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Plays the startup sound effect
    private func playStartupSound() {
        guard let soundURL = Bundle.main.url(forResource: "startup_sound", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView(onAnimationComplete: {})
        .environmentObject(ThemeManager())
}
