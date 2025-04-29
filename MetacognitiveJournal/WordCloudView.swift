import SwiftUI

struct WordCloudView: View {
    let words: [String]
    
    // Calculate font size based on position in the array (assuming words are sorted by importance)
    private func fontSize(for index: Int) -> CGFloat {
        let baseSize: CGFloat = 16
        let maxSize: CGFloat = 32
        let totalWords = CGFloat(words.count)
        let position = CGFloat(index)
        
        // Words earlier in the array get larger fonts
        let size = maxSize - ((position / totalWords) * (maxSize - baseSize))
        return max(baseSize, size)
    }
    
    // Calculate opacity based on position in the array
    private func opacity(for index: Int) -> Double {
        let minOpacity = 0.7
        let maxOpacity = 1.0
        let totalWords = Double(words.count)
        let position = Double(index)
        
        // Words earlier in the array get higher opacity
        return maxOpacity - ((position / totalWords) * (maxOpacity - minOpacity))
    }
    
    // Generate a color from a set of theme colors based on index
    private func color(for index: Int) -> Color {
        let colors: [Color] = [
            .blue, .purple, .indigo, .teal, .cyan
        ]
        return colors[index % colors.count]
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                    Text(word)
                        .font(.system(size: fontSize(for: i)))
                        .fontWeight(i < 3 ? .bold : .regular)
                        .foregroundColor(color(for: i).opacity(opacity(for: i)))
                        .position(
                            x: CGFloat.random(in: 50...(geo.size.width - 50)),
                            y: CGFloat.random(in: 50...(geo.size.height - 50))
                        )
                        .rotationEffect(.degrees(Double.random(in: -30...30)))
                        .shadow(color: .gray.opacity(0.2), radius: 1, x: 1, y: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
        .frame(height: 300)
    }
}

// MARK: - Preview
struct WordCloudView_Previews: PreviewProvider {
    static var previews: some View {
        WordCloudView(words: [
            "Learning", "Reflection", "Growth", "Challenges", 
            "Success", "Mindfulness", "Focus", "Goals",
            "Progress", "Creativity", "Resilience", "Insight"
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
