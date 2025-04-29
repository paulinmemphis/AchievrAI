//
//  PromptPersonalizationView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


//  PromptPersonalizationView.swift
//  MetacognitiveJournal

import SwiftUI

struct PromptPersonalizationView: View {
    @ObservedObject var manager: PromptPersonalizationManager
    let prompt: String

    var body: some View {
        VStack(spacing: 20) {
            Text(prompt)
                .font(.title3)
                .padding()

            HStack(spacing: 30) {
                Button(action: {
                    manager.toggleFavorite(prompt: prompt)
                }) {
                    Label("Favorite", systemImage: manager.isFavorite(prompt: prompt) ? "star.fill" : "star")
                        .labelStyle(IconOnlyLabelStyle())
                        .foregroundColor(.yellow)
                        .font(.system(size: 28))
                }

                Button(action: {
                    manager.toggleSkipped(prompt: prompt)
                }) {
                    Label("Skip", systemImage: manager.isSkipped(prompt: prompt) ? "xmark.circle.fill" : "xmark.circle")
                        .labelStyle(IconOnlyLabelStyle())
                        .foregroundColor(.red)
                        .font(.system(size: 28))
                }
            }

            if manager.isFavorite(prompt: prompt) {
                Text("You marked this prompt as a favorite.")
                    .foregroundColor(.green)
            }

            if manager.isSkipped(prompt: prompt) {
                Text("You skipped this prompt.")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
