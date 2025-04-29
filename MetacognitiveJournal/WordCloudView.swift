import SwiftUI

struct WordCloudView: View {
    let words: [String]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(words.enumerated()), id: \ .offset) { i, word in
                    Text(word)
                        .font(.system(size: CGFloat.random(in: 14...30)))
                        .foregroundColor(Color.accentColor.opacity(Double.random(in: 0.6...1)))
                        .position(x: CGFloat.random(in: 0...geo.size.width), y: CGFloat.random(in: 0...geo.size.height))
                        .opacity(0.85)
                }
            }
        }
    }
}
