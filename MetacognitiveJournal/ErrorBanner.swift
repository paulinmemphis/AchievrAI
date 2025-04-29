//
//  ErrorBanner.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.subheadline)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to dismiss")
    }
}

extension View {
    func errorBanner(isPresented: Binding<Bool>, message: String, onDismiss: @escaping () -> Void) -> some View {
        ZStack(alignment: .top) {
            self
            
            if isPresented.wrappedValue {
                ErrorBanner(message: message, onDismiss: onDismiss)
            }
        }
        .animation(.easeInOut, value: isPresented.wrappedValue)
    }
}
