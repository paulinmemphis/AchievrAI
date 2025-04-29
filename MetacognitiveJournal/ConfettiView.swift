import SwiftUI

/// A dynamic confetti celebration animation with multiple particles and effects
struct ConfettiView: View {
    // Control how long the animation runs
    var duration: Double = 2.0
    
    // Allow customizing the colors of confetti
    var colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    @State private var isAnimating = false
    @State private var particles: [ConfettiParticle] = []
    
    // Number of confetti pieces to show
    private let particleCount = 50
    
    var body: some View {
        ZStack {
            // Render each confetti particle
            ForEach(particles) { particle in
                ConfettiPiece(color: particle.color, shape: particle.shape)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: isAnimating ? particle.endX : particle.startX, 
                              y: isAnimating ? particle.endY : particle.startY)
                    .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                    .opacity(isAnimating ? 0 : 1) // Fade out at the end
                    .animation(
                        Animation
                            .timingCurve(0.1, 0.8, 0.2, 1, duration: duration)
                            .delay(particle.delay),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    // Create random confetti particles
    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            // Create particles with varying properties
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            // Start position (center of screen)
            let startX = screenWidth / 2
            let startY = screenHeight / 2
            
            // End position (random across the screen)
            let endX = CGFloat.random(in: -20...screenWidth+20)
            let endY = CGFloat.random(in: -20...screenHeight)
            
            return ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                size: CGFloat.random(in: 5...15),
                startX: startX,
                startY: startY,
                endX: endX,
                endY: endY,
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
    
    // Start the animation
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
        
        // Reset animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            resetAnimation()
        }
    }
    
    // Reset animation state to play again
    private func resetAnimation() {
        isAnimating = false
        generateParticles()
        
        // Small delay before starting again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimation()
        }
    }
}

/// A single piece of confetti with various possible shapes
struct ConfettiPiece: View {
    let color: Color
    let shape: ConfettiShape
    
    var body: some View {
        Group {
            switch shape {
            case .circle:
                Circle()
                    .fill(color)
            case .triangle:
                Triangle()
                    .fill(color)
            case .square:
                Rectangle()
                    .fill(color)
            case .strip:
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 5)
            case .star:
                Star(corners: 5, smoothness: 0.45)
                    .fill(color)
            case .custom:
                // Emoji or custom shapes as confetti
                Text(["🎉", "⭐️", "🎈", "✨", "🎊"].randomElement() ?? "🎉")
                    .font(.system(size: 12))
            }
        }
    }
}

/// Triangle shape for confetti
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Star shape for confetti
struct Star: Shape {
    let corners: Int
    let smoothness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        let path = Path { path in
            let angleStep = .pi * 2 / Double(corners * 2)
            
            let firstPoint = CGPoint(
                x: center.x + cos(0) * outerRadius,
                y: center.y + sin(0) * outerRadius
            )
            path.move(to: firstPoint)
            
            for corner in 1..<(corners * 2) {
                let radius = corner.isMultiple(of: 2) ? outerRadius : innerRadius
                let angle = Double(corner) * angleStep
                
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        return path
    }
}

/// Data model for a confetti particle
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let delay: Double
}

/// Available shapes for confetti
enum ConfettiShape: CaseIterable {
    case circle, triangle, square, strip, star, custom
}

/// Preview for ConfettiView
struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            ConfettiView()
        }
    }
}
