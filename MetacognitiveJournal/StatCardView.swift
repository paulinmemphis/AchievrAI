//
//  StatCardView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

struct StatCardView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            content
                .font(.caption)
                .foregroundColor(.secondary)

        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .contain)
    }
}

struct StatCardView_Previews: PreviewProvider {
    static var previews: some View {
        StatCardView(title: "Reflection on Resilience") {
            VStack(alignment: .leading, spacing: 5) {
                Text("Subject: Math")
                Text("Date: April 14, 2025")
                Text("Emotion: Curious")
                Text("AI Insight: Discussed overcoming challenges in problem-solving.")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
