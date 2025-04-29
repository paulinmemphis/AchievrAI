// HowDidYouFeelSectionView.swift
// Extracted from NewEntryView.swift for modularity
import SwiftUI

struct HowDidYouFeelSectionView: View {
    @Binding var selectedEmoticon: String
    @Binding var emotionalStateText: String
    var isRecording: Bool
    var activeDictationField: DictationField?
    var toggleDictation: (DictationField) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How did you feel?", systemImage: "face.smiling.fill")
                .font(.headline)
                .foregroundColor(.accentColor)
            Text("Express your feelings using text, emoji, or voice.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(["😀", "😐", "😢", "😡", "😱", "🥳"], id: \.self) { emoji in
                    Button(action: {
                        selectedEmoticon = emoji
                        emotionalStateText = emoji
                    }) {
                        Text(emoji)
                            .font(.largeTitle)
                            .padding(8)
                            .background(selectedEmoticon == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .accessibilityLabel(Text("Feeling \(emoji)"))
                    }
                }
            }
            HStack {
                TextField("Describe your feelings", text: $emotionalStateText)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .accessibilityLabel("Describe your feelings")
                // Dictation Button for Emotional State
                Button { toggleDictation(.emotionalState) } label: {
                    Image(systemName: isRecording && activeDictationField == .emotionalState ? "stop.circle.fill" : "mic.fill")
                        .foregroundColor(isRecording && activeDictationField == .emotionalState ? .red : .accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
