//
//  LoadingView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/27/25.
//


import SwiftUI

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}