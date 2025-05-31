import SwiftUI

/// An animated mascot character that adapts to the user's current emotional state
struct MascotView: View {
    let mood: String
    
    @State private var animateIcon = false
    @State private var showMessage = false
    @State private var pulseEffect = false
    @State private var randomRotation = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Mascot character with animations
            ZStack {
                // Background glow that responds to mood
                Circle()
                    .fill(moodColor(for: mood).opacity(0.2))
                    .frame(width: animateIcon ? 120 : 100, height: animateIcon ? 120 : 100)
                    .scaleEffect(pulseEffect ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseEffect)
                
                // Mascot image
                Image(systemName: mascotImage(for: mood))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(moodColor(for: mood))
                    .shadow(color: moodColor(for: mood).opacity(0.5), radius: 8, x: 0, y: 5)
                    .rotationEffect(.degrees(animateIcon ? randomRotation : 0))
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatCount(1), value: animateIcon)
            }
            .onAppear {
                // Trigger animations
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateIcon = true
                }
                
                // Add subtle random rotation for lively feel
                randomRotation = Double.random(in: -5...5)
                
                // Start pulse after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    pulseEffect = true
                }
                
                // Show message with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showMessage = true
                    }
                }
            }
            
            // Speech bubble with message
            if showMessage {
                SpeechBubble(message: mascotMessage(for: mood), color: moodColor(for: mood))
                    .padding(.top, 8)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .frame(maxHeight: 80) // Limit height to prevent overflow
            }
        }
        .padding()
    }
    
    /// Returns an appropriate SF Symbol name based on the emotional state
    private func mascotImage(for mood: String) -> String {
        switch mood.lowercased() {
        case "confident": return "face.smiling.fill"
        case "happy": return "sun.max.fill"
        case "excited": return "sparkles"
        case "frustrated": return "cloud.drizzle.fill"
        case "overwhelmed": return "tornado"
        case "curious": return "lightbulb.fill"
        case "neutral": return "leaf.fill"
        case "tired": return "moon.stars.fill"
        case "motivated": return "flame.fill"
        case "focused": return "scope"
        default: return "star.fill"
        }
    }
    
    /// Returns a supportive message appropriate for the current mood
    private func mascotMessage(for mood: String) -> String {
        switch mood.lowercased() {
        case "confident": return "You're doing amazing! Keep that confidence flowing!"
        case "happy": return "Your positive energy brightens everyone's day!"
        case "excited": return "That excitement is contagious! Let's channel it into your writing!"
        case "frustrated": return "It's okay to feel stuck sometimes. Let's take a step back and try a different approach."
        case "overwhelmed": return "Take a deep breath. We can break this down into smaller steps."
        case "curious": return "That's the spirit! Questions lead to amazing discoveries!"
        case "neutral": return "Every journal entry is progress. You're building something meaningful!"
        case "tired": return "Even a short entry today keeps your momentum going. You've got this!"
        case "motivated": return "I love your determination! Let's make the most of this energy!"
        case "focused": return "Your concentration is impressive! Deep work leads to incredible results."
        default: return "You're creating something wonderful with each entry you write!"
        }
    }
    
    /// Returns a color associated with the current mood
    private func moodColor(for mood: String) -> Color {
        switch mood.lowercased() {
        case "confident": return .blue
        case "happy": return .yellow
        case "excited": return .orange
        case "frustrated": return .purple
        case "overwhelmed": return .indigo
        case "curious": return .mint
        case "neutral": return .green
        case "tired": return .gray
        case "motivated": return .red
        case "focused": return .teal
        default: return .accentColor
        }
    }
}

/// A speech bubble component for the mascot's messages
struct SpeechBubble: View {
    let message: String
    let color: Color
    
    @State private var animateText = false
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    
    var body: some View {
        Text(message)
            .font(.system(.body, design: .rounded))
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .fixedSize(horizontal: false, vertical: true) // Ensures text wraps properly
            .frame(maxWidth: 260, maxHeight: 70) // Control both width and height
            .lineLimit(3) // Limit to 3 lines to prevent overflow
            .minimumScaleFactor(0.8) // Allow text to scale down slightly if needed
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
            )
            .offset(y: animateText ? 0 : textOffset)
            .opacity(animateText ? 1 : textOpacity)
            .onAppear {
                // Use a more reliable animation approach
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        textOpacity = 1
                        animateText = true
                    }
                }
            }
    }
}

/// Custom shape for the speech bubble
struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Rounded rectangle for bubble
        let cornerRadius: CGFloat = 16
        let triangleHeight: CGFloat = 12
        let triangleWidth: CGFloat = 16
        let triangleX: CGFloat = rect.width / 2 - triangleWidth/2
        
        // Main bubble
        path.addRoundedRect(
            in: CGRect(x: 0, y: triangleHeight, width: rect.width, height: rect.height - triangleHeight),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        // Triangle pointer
        path.move(to: CGPoint(x: triangleX, y: triangleHeight))
        path.addLine(to: CGPoint(x: triangleX + triangleWidth/2, y: 0))
        path.addLine(to: CGPoint(x: triangleX + triangleWidth, y: triangleHeight))
        
        return path
    }
}

struct MascotView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MascotView(mood: "confident")
            MascotView(mood: "curious")
            MascotView(mood: "frustrated")
        }
        .padding()
    }
}
