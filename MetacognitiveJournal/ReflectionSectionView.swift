// ReflectionSectionView.swift
// Extracted from NewEntryView.swift for modularity
import SwiftUI

struct ReflectionSectionView: View {
    let prompts: [String]
    @Binding var responses: [String: String]
    var isRecording: Bool
    var activeDictationField: DictationField?
    var toggleDictation: (DictationField) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reflection", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
                .foregroundColor(.accentColor)
            ForEach(prompts, id: \.self) { prompt in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        TextEditor(text: Binding(
                            get: { responses[prompt] ?? "" },
                            set: { responses[prompt] = $0 }
                        ))
                        .frame(height: 80)
                        .padding(6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .accessibilityLabel(Text("Response to prompt: \(prompt)"))
                        // Dictation Button for Reflection Prompt
                        Button { toggleDictation(.reflection(prompt: prompt)) } label: {
                            Image(systemName: isRecording && activeDictationField == .reflection(prompt: prompt) ? "stop.circle.fill" : "mic.fill")
                                .foregroundColor(isRecording && activeDictationField == .reflection(prompt: prompt) ? .red : .accentColor)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
