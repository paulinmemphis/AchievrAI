import SwiftUI

/// A SwiftUI animation to replace Lottie animations
struct AnimationView: View {
    // MARK: - Properties
    var name: String
    var loopMode: AnimationLoopMode = .loop
    var animationSpeed: Double = 1.0
    var completion: (() -> Void)? = nil
    
    // MARK: - State
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Base animation visual
            Group {
                if name == "completion" {
                    completionAnimation
                } else if name == "reward" {
                    rewardAnimation
                } else if name == "streak" {
                    streakAnimation
                } else {
                    defaultAnimation
                }
            }
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1.0
            }
            
            startAnimation()
        }
    }
    
    // MARK: - Animation Types
    
    private var completionAnimation: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 200, height: 200)
            
            Circle()
                .fill(Color.green.opacity(0.4))
                .frame(width: 150, height: 150)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
        }
    }
    
    private var rewardAnimation: some View {
        ZStack {
            ForEach(0..<5) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.yellow)
                    .offset(x: CGFloat.random(in: -50...50), 
                            y: CGFloat.random(in: -50...50))
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.2)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
            
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 100, height: 100)
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
        }
    }
    
    private var streakAnimation: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 180, height: 180)
            
            Image(systemName: "flame.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
    }
    
    private var defaultAnimation: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 150, height: 150)
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        isAnimating = true
        
        // Apply specific animations based on loop mode
        if loopMode == .loop {
            withAnimation(
                Animation
                    .easeInOut(duration: 2.0 / animationSpeed)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
            }
            
            withAnimation(
                Animation
                    .linear(duration: 8.0 / animationSpeed)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360.0
            }
        } else {
            // Play once
            withAnimation(
                Animation
                    .easeInOut(duration: 2.0 / animationSpeed)
            ) {
                scale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (3.0 / animationSpeed)) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion?()
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum AnimationLoopMode {
    case loop
    case playOnce
}

// MARK: - LottieView Replacement
/// A compatibility wrapper to provide the same API as the original LottieView
typealias LottieView = AnimationView

/// A preview provider for LottieView
struct LottieView_Previews: PreviewProvider {
    static var previews: some View {
        LottieView(name: "loading-book")
            .frame(width: 200, height: 200)
    }
}
